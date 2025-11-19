# NativeBridge bore - API Key Authentication

This is a modified version of bore that supports API key authentication with the NativeBridge backend.

## What Changed?

The original bore uses HMAC-based shared secret authentication. This fork adds support for **API key authentication** where:

1. Client sends API key instead of shared secret
2. Server validates API key with NativeBridge backend via HTTP
3. Each user has their own API key (no shared secrets!)
4. Backend can revoke access per user

## Architecture

```
┌──────────────┐                ┌──────────────┐                ┌──────────────┐
│   CLI        │   API Key      │ bore server  │   Validate     │ NativeBridge │
│  (Client)    │──────────────> │              │──────────────> │   Backend    │
└──────────────┘                └──────────────┘                └──────────────┘
                                      │
                                      │ If valid, create tunnel
                                      ▼
                                ┌──────────────┐
                                │  ADB Device  │
                                └──────────────┘
```

## Server Setup (on EC2)

### 1. Build the modified bore server

```bash
# On your local machine (or EC2)
cd /Users/himanshukukreja/autoflow/nativebridge-bore-tunnel
cargo build --release

# The binary will be at:
# target/release/bore
```

### 2. Run the server with API validation

```bash
# On EC2 (3.6.53.225)
./bore server \
  --api-validation-url "https://api.nativebridge.io/v1/validate-tunnel-access" \
  --bind-addr 0.0.0.0
```

**Important flags:**
- `--api-validation-url`: Your backend endpoint that validates API keys
- `--bind-addr`: IP address to bind to (use 0.0.0.0 for all interfaces)
- `--min-port` (optional): Minimum port number (default: 1024)
- `--max-port` (optional): Maximum port number (default: 65535)

### 3. Expected Backend API

Your backend endpoint must:

**Request:**
```http
POST /v1/validate-tunnel-access
Authorization: Bearer <api_key>
Content-Type: application/json

{
  "api_key": "<api_key>"
}
```

**Response (Success):**
```json
{
  "valid": true,
  "user_id": "user_123"
}
```

**Response (Failure):**
```json
{
  "valid": false,
  "error": "Invalid API key"
}
```

Or simply return HTTP status:
- `200 OK` = Valid
- `401 Unauthorized` = Invalid

## Client Setup

### 1. Build the client

```bash
cargo build --release
```

### 2. Run with API key

```bash
# Using API key (NEW!)
export BORE_API_KEY="nb_your_api_key_here"
./bore local 5555 --to bore.nativebridge.io

# Or pass directly
./bore local 5555 --to bore.nativebridge.io --api-key "nb_your_api_key_here"
```

### 3. Legacy secret still works

```bash
# Old HMAC secret method still supported
./bore local 5555 --to bore.nativebridge.io --secret "shared_secret"
```

## Python Integration (test_bore.py)

Update your test_bore.py to use the modified bore client:

```python
import os
import subprocess

# Get API key from environment
api_key = os.getenv('NB_API_KEY')

# Start bore tunnel with API key
bore_process = subprocess.Popen([
    'bore', 'local', '5555',
    '--to', 'bore.nativebridge.io',
    '--api-key', api_key
], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
```

## Environment Variables

**Client:**
- `BORE_API_KEY` - NativeBridge API key for authentication
- `BORE_SECRET` - Legacy HMAC secret (alternative to API key)
- `BORE_SERVER` - Server address (e.g., bore.nativebridge.io)

**Server:**
- `BORE_API_VALIDATION_URL` - Backend validation endpoint
- `BORE_MIN_PORT` - Minimum allowed port (default: 1024)
- `BORE_MAX_PORT` - Maximum allowed port (default: 65535)

## Security Benefits

✅ **No shared secrets** - Each user has unique API key
✅ **Revocation** - Backend can revoke individual users
✅ **Audit trail** - Backend logs all tunnel creation attempts
✅ **Rate limiting** - Backend enforces quotas per user
✅ **Time-based access** - Backend can implement expiration

## Testing Locally

### 1. Create a mock validation server

```python
# mock_validator.py
from flask import Flask, request, jsonify

app = Flask(__name__)

VALID_API_KEYS = {
    "test_key_123": "user_abc",
    "test_key_456": "user_xyz"
}

@app.route('/v1/validate-tunnel-access', methods=['POST'])
def validate():
    auth_header = request.headers.get('Authorization', '')
    api_key = auth_header.replace('Bearer ', '')

    if api_key in VALID_API_KEYS:
        return jsonify({
            'valid': True,
            'user_id': VALID_API_KEYS[api_key]
        }), 200
    else:
        return jsonify({
            'valid': False,
            'error': 'Invalid API key'
        }), 401

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

### 2. Run the mock validator

```bash
python mock_validator.py
```

### 3. Run bore server pointing to mock

```bash
./target/release/bore server \
  --api-validation-url "http://localhost:8080/v1/validate-tunnel-access" \
  --bind-addr 127.0.0.1
```

### 4. Test with client

```bash
# Valid key - should work
./target/release/bore local 5555 --to localhost --api-key "test_key_123"

# Invalid key - should fail
./target/release/bore local 5555 --to localhost --api-key "wrong_key"
```

## Deployment to EC2

### 1. Build for Linux (on macOS)

```bash
# Install cross-compilation target
rustup target add x86_64-unknown-linux-gnu

# Build (might need additional setup for cross-compilation)
# OR build directly on EC2
```

### 2. Build on EC2 directly

```bash
# On EC2
sudo yum install -y git gcc
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Clone and build
git clone https://github.com/YOUR_USERNAME/nativebridge-bore-tunnel.git
cd nativebridge-bore-tunnel
cargo build --release
```

### 3. Run as systemd service

```ini
# /etc/systemd/system/bore-server.service
[Unit]
Description=NativeBridge bore server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/nativebridge-bore-tunnel
Environment="BORE_API_VALIDATION_URL=https://api.nativebridge.io/v1/validate-tunnel-access"
ExecStart=/home/ec2-user/nativebridge-bore-tunnel/target/release/bore server --bind-addr 0.0.0.0
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl enable bore-server
sudo systemctl start bore-server
sudo systemctl status bore-server
```

## Troubleshooting

### Client can't connect

```bash
# Check if server is running
nc -zv bore.nativebridge.io 7835

# Check firewall on EC2
# Ensure port 7835 is open in security group
```

### Authentication fails

```bash
# Check server logs
journalctl -u bore-server -f

# Common issues:
# 1. API validation URL is incorrect
# 2. Backend is not reachable from EC2
# 3. API key format is wrong
# 4. Backend returned non-200 status
```

### API validation timeout

```bash
# The validation has 5-second timeout
# Check backend response time
curl -X POST https://api.nativebridge.io/v1/validate-tunnel-access \
  -H "Authorization: Bearer test_key" \
  -w "\nTime: %{time_total}s\n"
```

## Migration from Original bore

If you're currently using the original bore with shared secrets:

1. **Phase 1**: Deploy this fork with both `--secret` and `--api-validation-url`
   - Existing clients with secrets continue working
   - New clients can use API keys

2. **Phase 2**: Migrate all clients to API keys
   - Update client code to use API keys
   - Test thoroughly

3. **Phase 3**: Remove `--secret` flag from server
   - All clients now use API keys
   - Full per-user authentication

## License

MIT (same as original bore)
