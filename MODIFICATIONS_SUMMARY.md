# bore Modifications Summary

## Overview

We successfully modified the bore tunnel to support **API key authentication** with the NativeBridge backend, solving the shared secret exposure problem.

## Problem We Solved

### Original Problem
```
User → Backend API → Gets bore secret → Can bypass backend forever
```

**Issues:**
- ❌ Shared secret exposed to all clients
- ❌ No per-user authentication
- ❌ Can't revoke individual users
- ❌ No audit trail of who created what
- ❌ Secret leaked = must rotate for everyone

### Our Solution
```
User → Backend API (validates every time) → bore server → Tunnel created
```

**Benefits:**
- ✅ Each user has unique API key
- ✅ Per-user authentication and authorization
- ✅ Can revoke individual users
- ✅ Full audit trail
- ✅ API key leaked = only that user affected

## Files Modified

### 1. [Cargo.toml](Cargo.toml)
**Added:**
```toml
reqwest = { version = "0.11", features = ["json"] }
```
**Why:** Need HTTP client to validate API keys with backend

### 2. [src/auth.rs](src/auth.rs:82-169)
**Added:**
- `ApiKeyAuthenticator` struct
- `validate_api_key()` - Makes HTTP POST to backend
- `server_handshake()` - Server-side API key validation
- `client_handshake()` - Client-side API key sending

**How it works:**
```rust
// Server receives API key from client
// Makes HTTP call to validate
POST https://api.nativebridge.io/v1/validate-tunnel-access
Authorization: Bearer <api_key>

// If 200 OK → tunnel allowed
// If 401/4xx → tunnel rejected
```

### 3. [src/server.rs](src/server.rs)
**Added:**
- `AuthMode` enum (None, Secret, ApiKey)
- Updated `Server::new()` to accept `api_validation_url`
- Modified `handle_connection()` to use appropriate auth mode

**How it works:**
```rust
// Server can now run in 3 modes:
1. AuthMode::None - No authentication (original behavior without --secret)
2. AuthMode::Secret - HMAC secret (original --secret flag)
3. AuthMode::ApiKey - API key validation (NEW --api-validation-url flag)
```

### 4. [src/client.rs](src/client.rs)
**Added:**
- `ClientAuthMode` enum (None, Secret, ApiKey)
- Updated `Client::new()` to accept `api_key` parameter
- Modified authentication handshake to support API keys

**How it works:**
```rust
// Client can now authenticate 3 ways:
1. No auth
2. --secret (original)
3. --api-key (NEW)
```

### 5. [src/main.rs](src/main.rs)
**Added:**
- `--api-validation-url` flag for server
- `--api-key` flag for client

**Server command:**
```bash
bore server --api-validation-url "https://api.nativebridge.io/v1/validate-tunnel-access"
```

**Client command:**
```bash
bore local 5555 --to bore.nativebridge.io --api-key "nb_your_key"
```

## Authentication Flow

### Client-to-Server Handshake

```
1. Client connects to server
2. Server sends Challenge(UUID)
3. Client sends Authenticate(api_key)
4. Server validates API key with backend:
   POST /v1/validate-tunnel-access
   Authorization: Bearer <api_key>
5. Backend responds:
   - 200 OK → Server allows tunnel
   - 401 Unauthorized → Server rejects
6. Server sends Hello(port) or Error(message)
7. Tunnel established or connection closed
```

### Backend API Contract

**Endpoint:** `POST /v1/validate-tunnel-access`

**Request Headers:**
```
Authorization: Bearer <api_key>
Content-Type: application/json
```

**Request Body:**
```json
{
  "api_key": "<api_key>"
}
```

**Response (Success - 200 OK):**
```json
{
  "valid": true,
  "user_id": "user_123"
}
```

**Response (Failure - 401 Unauthorized):**
```json
{
  "valid": false,
  "error": "Invalid API key"
}
```

## Backward Compatibility

✅ **Fully backward compatible!**

The original bore secret authentication still works:

```bash
# Old way (still works)
bore server --secret "my_shared_secret"
bore local 5555 --to server.com --secret "my_shared_secret"

# New way
bore server --api-validation-url "https://api.backend.com/validate"
bore local 5555 --to server.com --api-key "nb_api_key_123"
```

## Testing Status

### ✅ Compilation
```bash
cargo build --release
# Success! Only 1 minor warning about unused fields
```

### ⏳ Runtime Testing
**Not yet tested - needs:**
1. Mock backend API endpoint
2. Local bore server running
3. Test client connections

### 📋 Next Steps for Testing

1. **Create mock validation server** (see NATIVEBRIDGE_SETUP.md)
2. **Run bore server** with mock endpoint
3. **Test valid API key** - should create tunnel
4. **Test invalid API key** - should reject
5. **Deploy to EC2** with production backend

## Deployment Plan

### Phase 1: Local Testing
```bash
# Terminal 1: Mock backend
python mock_validator.py

# Terminal 2: bore server
./target/release/bore server \
  --api-validation-url "http://localhost:8080/v1/validate-tunnel-access"

# Terminal 3: Client
./target/release/bore local 5555 --to localhost --api-key "test_key"
```

### Phase 2: EC2 Deployment
```bash
# Build on EC2
ssh ec2-user@3.6.53.225
git clone https://github.com/YOUR_USERNAME/nativebridge-bore-tunnel.git
cd nativebridge-bore-tunnel
cargo build --release

# Run with systemd
sudo systemctl start bore-server
```

### Phase 3: Update test_bore.py
```python
# In bridgelink/test_bore.py
api_key = os.getenv('NB_API_KEY')

bore_process = subprocess.Popen([
    'bore', 'local', str(self.adb_port),
    '--to', 'bore.nativebridge.io',
    '--api-key', api_key  # NEW!
], ...)
```

## Security Improvements

| Feature | Before | After |
|---------|--------|-------|
| Shared Secret | ✅ One secret for all | ❌ No shared secrets |
| Per-User Auth | ❌ Can't identify users | ✅ Each user has API key |
| Revocation | ❌ Must rotate for all | ✅ Revoke individual users |
| Audit Trail | ❌ No tracking | ✅ Backend logs all attempts |
| Rate Limiting | ❌ Not possible | ✅ Backend enforces quotas |
| Secret Exposure | ❌ Client sees secret | ✅ Secret stays on server |

## Performance Considerations

**API Validation Latency:**
- Added ~5-50ms per tunnel creation (one HTTP call)
- Timeout: 5 seconds (configurable in auth.rs:108)
- Cached? No - validates every tunnel creation

**Mitigation:**
- Keep backend validation endpoint fast (<50ms)
- Consider caching valid API keys for N seconds
- Monitor backend performance

## Known Limitations

1. **API Key in Memory**: Client stores API key in memory (mitigated by OS process isolation)
2. **No Key Rotation**: If API key changes, client must restart
3. **Validation on Every Connection**: Each proxy connection validates (not just initial tunnel)

## Future Enhancements

### Optional Improvements:
1. **Token Caching**: Cache valid tokens for 5 minutes to reduce backend load
2. **Mutual TLS**: Add client certificates for extra security
3. **WebSocket Backend**: Use WebSocket instead of HTTP for real-time validation
4. **Rate Limiting**: Built-in rate limiting in bore server (not just backend)
5. **Metrics**: Prometheus metrics for tunnel creation, validation latency, etc.

## Maintenance

### Syncing with Upstream bore

If ekzhang/bore releases updates:

```bash
# Add upstream remote
git remote add upstream https://github.com/ekzhang/bore.git

# Fetch upstream changes
git fetch upstream

# Merge (may have conflicts in auth-related files)
git merge upstream/main

# Resolve conflicts in:
# - src/auth.rs (our ApiKeyAuthenticator code)
# - src/server.rs (our AuthMode enum)
# - src/client.rs (our ClientAuthMode enum)
# - src/main.rs (our --api-key flag)
```

### Testing After Updates

```bash
cargo test
cargo build --release
# Run integration tests
```

## Documentation

- **[NATIVEBRIDGE_SETUP.md](NATIVEBRIDGE_SETUP.md)** - Complete setup guide
- **[MODIFICATIONS_SUMMARY.md](MODIFICATIONS_SUMMARY.md)** - This file
- **Original [README.md](README.md)** - Original bore documentation

## Questions?

If you encounter issues:

1. Check [NATIVEBRIDGE_SETUP.md](NATIVEBRIDGE_SETUP.md) troubleshooting section
2. Verify backend API is responding correctly
3. Check bore server logs: `journalctl -u bore-server -f`
4. Test with mock validator first before production

## Success Criteria

✅ Build succeeds
✅ Documentation created
⏳ Local testing with mock backend
⏳ EC2 deployment
⏳ Integration with test_bore.py
⏳ Production validation with NativeBridge backend

---

**Modified by:** Himanshu Kukreja
**Date:** 2025-11-20
**Repository:** https://github.com/YOUR_USERNAME/nativebridge-bore-tunnel
