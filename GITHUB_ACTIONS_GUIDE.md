# GitHub Actions - Automated Cross-Platform Builds

## 🎯 What This Does

GitHub Actions will **automatically build bore binaries for all platforms** when you create a release:

- ✅ macOS ARM64 (M1/M2/M3)
- ✅ macOS x86_64 (Intel)
- ✅ Linux x86_64 (for EC2 + Linux users)
- ✅ Windows x86_64

**No manual building required!** Just create a release and GitHub does the rest.

---

## 📁 Files Created

### 1. `.github/workflows/release.yml`
**Triggers on:** Release creation
**Does:** Builds all platforms and uploads binaries to the release

### 2. `.github/workflows/build-test.yml`
**Triggers on:** Manual trigger or pull requests
**Does:** Tests that builds work on all platforms (no release upload)

---

## 🚀 How to Use

### Method 1: Create Release (Automatic Build & Upload)

1. **Push your code to GitHub:**
   ```bash
   cd /Users/himanshukukreja/autoflow/nativebridge-bore-tunnel
   git add .
   git commit -m "Add API key authentication"
   git push origin main
   ```

2. **Create a release on GitHub:**
   - Go to: https://github.com/himanshkukreja/nativebridge-bore-tunnel/releases/new
   - **Tag:** `v0.6.0-nativebridge`
   - **Title:** "NativeBridge bore v0.6.0 - API Key Authentication"
   - **Description:**
     ```markdown
     Modified bore with API key authentication for NativeBridge.

     ## Features
     - ✅ API key authentication (no shared secrets!)
     - ✅ Per-user access control
     - ✅ Backward compatible

     ## Installation
     ```bash
     # macOS ARM64 (M1/M2/M3)
     curl -L https://github.com/himanshkukreja/nativebridge-bore-tunnel/releases/download/v0.6.0-nativebridge/bore-0.6.0-nativebridge-macos-arm64 -o bore
     chmod +x bore
     sudo mv bore /usr/local/bin/

     # macOS Intel
     curl -L https://github.com/himanshkukreja/nativebridge-bore-tunnel/releases/download/v0.6.0-nativebridge/bore-0.6.0-nativebridge-macos-x64 -o bore
     chmod +x bore
     sudo mv bore /usr/local/bin/

     # Linux
     curl -L https://github.com/himanshkukreja/nativebridge-bore-tunnel/releases/download/v0.6.0-nativebridge/bore-0.6.0-nativebridge-linux-x64 -o bore
     chmod +x bore
     sudo mv bore /usr/local/bin/

     # Windows (PowerShell)
     Invoke-WebRequest -Uri "https://github.com/himanshkukreja/nativebridge-bore-tunnel/releases/download/v0.6.0-nativebridge/bore-0.6.0-nativebridge-windows-x64.exe" -OutFile bore.exe
     ```

     ## Usage
     ```bash
     export BORE_API_KEY="your_nativebridge_api_key"
     bore local 5555 --to bore.nativebridge.io
     ```
     ```
   - **DON'T upload any files yet!**
   - Click **"Publish release"**

3. **GitHub Actions starts automatically:**
   - Go to: https://github.com/himanshkukreja/nativebridge-bore-tunnel/actions
   - You'll see "Build and Release" workflow running
   - Takes ~10-15 minutes to build all platforms

4. **Binaries are automatically uploaded:**
   - Once workflow completes, go back to your release
   - All binaries will be there:
     - `bore-0.6.0-nativebridge-macos-arm64`
     - `bore-0.6.0-nativebridge-macos-x64`
     - `bore-0.6.0-nativebridge-linux-x64`
     - `bore-0.6.0-nativebridge-windows-x64.exe`
     - `SHA256SUMS.txt` (checksums for verification)

5. **Done!** Users can now download from the release.

---

### Method 2: Test Builds First (Before Release)

If you want to test that builds work before creating a release:

1. **Push your code:**
   ```bash
   git push origin main
   ```

2. **Trigger test build manually:**
   - Go to: https://github.com/himanshkukreja/nativebridge-bore-tunnel/actions
   - Click "Test Build" workflow
   - Click "Run workflow" → "Run workflow"

3. **Watch it build:**
   - Builds all 4 platforms
   - Doesn't create a release
   - Just tests that everything compiles

4. **Download artifacts (optional):**
   - After workflow completes, click on it
   - Scroll to "Artifacts" section
   - Download any binary to test locally

5. **If all builds succeed → Create release (Method 1)**

---

## 📊 What Happens Behind the Scenes

```
┌─────────────────────────────────────────────────────────────┐
│  You: Create Release on GitHub                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions: Triggers "Build and Release" workflow     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ├─────► Job 1: Build macOS ARM64
                     │         ├─ Install Rust
                     │         ├─ cargo build --release --target aarch64-apple-darwin
                     │         └─ Upload bore-0.6.0-nativebridge-macos-arm64
                     │
                     ├─────► Job 2: Build macOS x64
                     │         ├─- Install Rust
                     │         ├─ cargo build --release --target x86_64-apple-darwin
                     │         └─ Upload bore-0.6.0-nativebridge-macos-x64
                     │
                     ├─────► Job 3: Build Linux x64
                     │         ├─ Install Rust + musl-tools
                     │         ├─ cargo build --release --target x86_64-unknown-linux-musl
                     │         └─ Upload bore-0.6.0-nativebridge-linux-x64
                     │
                     └─────► Job 4: Build Windows x64
                               ├─ Install Rust
                               ├─ cargo build --release --target x86_64-pc-windows-msvc
                               └─ Upload bore-0.6.0-nativebridge-windows-x64.exe
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  All binaries uploaded to your release automatically!      │
└─────────────────────────────────────────────────────────────┘
```

All jobs run **in parallel** (at the same time), so it's fast!

---

## ✅ Verify Builds Succeeded

After creating a release:

1. **Check Actions tab:**
   - https://github.com/himanshkukreja/nativebridge-bore-tunnel/actions
   - Should show green checkmark ✅

2. **Check Release page:**
   - https://github.com/himanshkukreja/nativebridge-bore-tunnel/releases
   - Should show all 4 binaries + SHA256SUMS.txt

3. **Test download:**
   ```bash
   # Download macOS ARM64 binary
   curl -L https://github.com/himanshkukreja/nativebridge-bore-tunnel/releases/download/v0.6.0-nativebridge/bore-0.6.0-nativebridge-macos-arm64 -o bore

   # Test it
   chmod +x bore
   ./bore --help
   ```

---

## 🐛 Troubleshooting

### Build fails with compilation error

**Check:**
- Go to Actions tab → Click failed workflow → Click failed job
- Read error message
- Usually: Code doesn't compile on that platform
- Fix: Update code, push, create new release

### "GITHUB_TOKEN" permission error

**Fix:**
- Go to: https://github.com/himanshkukreja/nativebridge-bore-tunnel/settings/actions
- Under "Workflow permissions"
- Select "Read and write permissions"
- Save

### Binary not uploaded to release

**Check:**
- Did workflow complete successfully?
- Did you use `workflow_dispatch` (manual trigger)? That doesn't upload to releases.
- Only `release` trigger uploads binaries.

### Windows build fails

**Common issue:** Windows needs different dependencies sometimes.
**Fix:** Update `Cargo.toml` if needed, or use `x86_64-pc-windows-gnu` target instead of `msvc`.

---

## 🔄 Updating Releases

When you need to update:

1. **Make your changes**
2. **Push to GitHub**
3. **Create a new release** with a new tag (e.g., `v0.6.1-nativebridge`)
4. **GitHub Actions rebuilds everything automatically**

---

## 📋 Comparison: Manual vs GitHub Actions

| Task | Manual (Local) | GitHub Actions |
|------|---------------|----------------|
| macOS ARM64 | ✅ Easy | ✅ Automatic |
| macOS Intel | ❌ Needs Intel Mac | ✅ Automatic |
| Linux | ❌ Needs musl-gcc | ✅ Automatic |
| Windows | ❌ Needs MinGW | ✅ Automatic |
| Time | ~30 min per platform | ~15 min total (parallel) |
| Cost | Free (your time) | Free (GitHub provides) |
| Reproducible | ❌ Your machine | ✅ Clean environment |
| Checksums | ❌ Manual | ✅ Automatic |

**Verdict: Use GitHub Actions!** 🚀

---

## 🎓 Advanced: Customize Workflow

### Change version number dynamically

Edit `.github/workflows/release.yml`:

```yaml
- name: Prepare binary
  shell: bash
  run: |
    VERSION="${GITHUB_REF#refs/tags/v}"  # Extract from tag
    RELEASE_NAME="bore-${VERSION}-${{ matrix.platform.name }}"
    # ... rest of script
```

### Add tests before building

```yaml
- name: Run tests
  run: cargo test --all-features

- name: Build
  run: cargo build --release --target ${{ matrix.platform.target }}
```

### Build only on specific tags

```yaml
on:
  release:
    types: [created]
  push:
    tags:
      - 'v*.*.*-nativebridge'  # Only tags like v0.6.0-nativebridge
```

---

## 📝 Summary

**To release with automatic cross-platform builds:**

1. Push code to GitHub
2. Create release with tag `v0.6.0-nativebridge`
3. Wait 15 minutes
4. All binaries appear in the release automatically!

**That's it!** No manual building, no cross-compilation setup needed.

---

## 🔗 Useful Links

- **Actions Dashboard:** https://github.com/himanshkukreja/nativebridge-bore-tunnel/actions
- **Releases:** https://github.com/himanshkukreja/nativebridge-bore-tunnel/releases
- **GitHub Actions Docs:** https://docs.github.com/en/actions

---

**Next Steps:**

1. ✅ Push `.github/workflows/` files to GitHub
2. ✅ Create your first release
3. ✅ Watch the magic happen! ✨
