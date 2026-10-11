import os
import sys
import json
import hashlib
import subprocess
import urllib.request
import urllib.error

repo = "Arnab-apk/Hopping_Guide"
tag_name = "v1.0.0"
release_title = "UMA v1.0.0 — Performance optimizations, lightweight per-ABI builds, and video calling refinement"

# 1. Retrieve token via Git Credential Manager
env = {**os.environ, 'GIT_TERMINAL_PROMPT': '0', 'GCM_INTERACTIVE': 'never'}
result = subprocess.run(
    ['git', 'credential', 'fill'],
    input=f'url=https://github.com/{repo}.git\n\n',
    capture_output=True,
    text=True,
    env=env
)
cred = dict(line.split('=', 1) for line in result.stdout.splitlines() if '=' in line)
token = os.environ.get('GH_TOKEN') or os.environ.get('GITHUB_TOKEN') or cred.get('password')

if not token:
    print("Error: Could not retrieve GitHub token.")
    sys.exit(1)

apk_dir = r"D:\projects\puja_proj\app\build\app\outputs\flutter-apk"
apk_files = {
    "UMA-v1.0.0-arm64-v8a.apk": os.path.join(apk_dir, "app-arm64-v8a-release.apk"),
    "UMA-v1.0.0-armeabi-v7a.apk": os.path.join(apk_dir, "app-armeabi-v7a-release.apk"),
    "UMA-v1.0.0-x86_64.apk": os.path.join(apk_dir, "app-x86_64-release.apk"),
}

for name, path in apk_files.items():
    if not os.path.exists(path):
        print(f"Error: Missing APK file at {path}")
        sys.exit(1)

# Generate checksums
checksum_lines = []
print("Computing SHA256 checksums...")
for name, path in apk_files.items():
    hasher = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    digest = hasher.hexdigest()
    size_mb = os.path.getsize(path) / (1024 * 1024)
    print(f"  {name}: {digest} ({size_mb:.1f} MB)")
    checksum_lines.append(f"{digest}  {name}")

checksum_path = os.path.join(apk_dir, "SHA256SUMS.txt")
with open(checksum_path, "w", encoding="utf-8") as f:
    f.write("\n".join(checksum_lines) + "\n")

assets_to_upload = dict(apk_files)
assets_to_upload["SHA256SUMS.txt"] = checksum_path

headers = {
    "Authorization": f"Bearer {token}",
    "Accept": "application/vnd.github+json",
    "User-Agent": "UMA-Release-Publisher",
}

# 2. Check if release exists or create it
release_url = f"https://api.github.com/repos/{repo}/releases/tags/{tag_name}"
req = urllib.request.Request(release_url, headers=headers)
release = None

body_text = """# UMA v1.0.0 — Major Performance, Video Calling, & Route Pin Release

Welcome to **UMA v1.0.0**! This milestone release introduces massive APK size and startup speed optimizations, per-ABI lightweight builds, streamlined video call navigation controls, and refined transit routing map pin displays.

---

### 🚀 Key Improvements & Highlights

#### 1. Lightweight Per-ABI APKs & 61.6% Download Size Reduction
- Switched to **split per-ABI Android release builds** (`arm64-v8a`, `armeabi-v7a`, `x86_64`), reducing modern ARM64 package size from **318.4 MiB down to 122.2 MiB** (~61.6% reduction).
- Significantly faster package installation and reduced local storage footprint on mobile devices.
- ARM64 build verified on physical Motorola Edge 50 (`versionCode 4018`, Android 16 / API 36).

#### 2. Startup & UI Performance Optimizations
- **On-demand Tab Mounting**: Inactive tabs (Directory, Trails, Squad Chat) now mount strictly when selected, preserving state upon visit while muting background ticker overhead.
- **Snappier Greeting / Splash**: Greeting splash minimum hold time reduced from 4000 ms to 800 ms with redundant staged delay loops removed.
- **Pandal Directory Caching**: Directory listing rebuilds solely on genuine coordinate displacements rather than periodic compass/orientation ticks. Haversine distance calculations are cached per filter/sort pass.
- **Mapbox Directions Coalescing**: Concurrent identical direction queries are coalesced within the service instance to eliminate redundant network traffic.

#### 3. Group Video Calling & UX Refinement
- **Fixed End Call Button**: Prominently placed, accessible red "End call" button anchored cleanly below media controls and elevated above Android gesture navigation.
- **Hosted Calling Fallback**: Automatic, resilient fallback to hosted squad calling backend (`uma-group-calling.onrender.com`) when local build-time API defines are absent.
- **State Preservation**: In-call layout stability during reconnection and participant renegotiation.

#### 4. Route & Transit Map Pins Refinement
- **Focused Station Pins**: Trail and itinerary maps display intermediate, boarding, and interchange stations strictly for the active transit legs. Unrelated stations are suppressed, eliminating route visual clutter.
- **Pandal Pin Layering**: Numbered festival pins render atop station markers for clean tap target priority.
- **Strict GPS Fix Validation**: Trail progress checks require GPS timestamps $\le$ 10 seconds fresh and accuracy $\le$ 30 meters, rejecting jitter and duplicate arrivals.

---

### 📦 Release Assets & Checksums

| Asset | Target Architecture | Size |
|---|---|---|
| `UMA-v1.0.0-arm64-v8a.apk` | Most modern Android devices (64-bit ARM) | ~122.2 MB |
| `UMA-v1.0.0-armeabi-v7a.apk` | Older 32-bit ARM Android devices | ~99.9 MB |
| `UMA-v1.0.0-x86_64.apk` | x86_64 Emulators & Chromebooks | ~177.0 MB |
| `SHA256SUMS.txt` | Cryptographic checksums | Text |

Verify checksums using:
```bash
sha256sum -c SHA256SUMS.txt
```

---

### ✅ Quality & Verification
- **Automated Tests**: 434 tests passing with zero failures.
- **Static Analysis**: `flutter analyze` report: clean (0 issues).
- **Physical Device**: Verified installed and launched on Motorola Edge 50.
"""

try:
    with urllib.request.urlopen(req) as resp:
        release = json.loads(resp.read().decode("utf-8"))
        print(f"Existing release found: ID {release['id']}, URL {release['html_url']}")
        # Update existing release body/title
        patch_url = f"https://api.github.com/repos/{repo}/releases/{release['id']}"
        patch_body = {
            "name": release_title,
            "body": body_text,
            "draft": False,
            "prerelease": False
        }
        patch_req = urllib.request.Request(
            patch_url,
            data=json.dumps(patch_body).encode("utf-8"),
            headers=headers,
            method="PATCH"
        )
        with urllib.request.urlopen(patch_req) as patch_resp:
            release = json.loads(patch_resp.read().decode("utf-8"))
            print("Updated release details.")
except urllib.error.HTTPError as e:
    if e.code == 404:
        print(f"Release {tag_name} does not exist yet. Creating...")
        create_url = f"https://api.github.com/repos/{repo}/releases"
        create_body = {
            "tag_name": tag_name,
            "target_commitish": "release/v1.0.0",
            "name": release_title,
            "body": body_text,
            "draft": False,
            "prerelease": False
        }
        create_req = urllib.request.Request(
            create_url,
            data=json.dumps(create_body).encode("utf-8"),
            headers=headers,
            method="POST"
        )
        with urllib.request.urlopen(create_req) as create_resp:
            release = json.loads(create_resp.read().decode("utf-8"))
            print(f"Created release ID {release['id']} at {release['html_url']}")
    else:
        raise

release_id = release["id"]
upload_url_template = release["upload_url"]
base_upload_url = upload_url_template.split("{")[0]

existing_assets = {a["name"]: a for a in release.get("assets", [])}

for asset_name, asset_path in assets_to_upload.items():
    if asset_name in existing_assets:
        asset_id = existing_assets[asset_name]["id"]
        print(f"Deleting existing asset {asset_name} (ID: {asset_id})...")
        del_req = urllib.request.Request(
            f"https://api.github.com/repos/{repo}/releases/assets/{asset_id}",
            headers=headers,
            method="DELETE"
        )
        try:
            urllib.request.urlopen(del_req)
            print(f"Deleted old {asset_name}")
        except Exception as del_err:
            print(f"Warning: could not delete {asset_name}: {del_err}")

    content_type = "application/vnd.android.package-archive" if asset_name.endswith(".apk") else "text/plain; charset=utf-8"
    file_size = os.path.getsize(asset_path)
    print(f"Uploading {asset_name} ({file_size / (1024*1024):.2f} MB)...")

    upload_url = f"{base_upload_url}?name={asset_name}"
    upload_headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": content_type,
        "User-Agent": "UMA-Release-Publisher",
        "Content-Length": str(file_size)
    }

    with open(asset_path, "rb") as f:
        file_bytes = f.read()

    up_req = urllib.request.Request(upload_url, data=file_bytes, headers=upload_headers, method="POST")
    with urllib.request.urlopen(up_req) as up_resp:
        res = json.loads(up_resp.read().decode("utf-8"))
        print(f"Uploaded {asset_name}: {res['browser_download_url']}")

print("\n--- ALL ASSETS UPLOADED AND RELEASE PUBLISHED SUCCESSFULLY! ---")
print(f"Release URL: {release['html_url']}")
