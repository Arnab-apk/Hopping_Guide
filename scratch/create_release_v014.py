import os
import sys
import subprocess
import json
import urllib.request
import urllib.error

# 1. Get token from get_token.ps1
res = subprocess.run(
    ["powershell", "-ExecutionPolicy", "Bypass", "-File", r"C:\Users\arnab\.gemini\antigravity-ide\brain\43c383c9-68c8-424c-80f0-43e5ffdecd3e\scratch\get_token.ps1"],
    capture_output=True,
    text=True,
    check=True
)
token = res.stdout.strip()
if not token:
    print("Error: Could not retrieve GitHub token.")
    sys.exit(1)

owner = "Arnab-apk"
repo = "Hopping_Guide"
tag_name = "v0.1.4"
apk_path = r"c:\Users\arnab\Desktop\puja_proj\app\build\app\outputs\flutter-apk\app-release.apk"
asset_name = "Uma-PujoParikrama-release.apk"

if not os.path.exists(apk_path):
    print(f"Error: APK not found at {apk_path}")
    sys.exit(1)

file_size = os.path.getsize(apk_path)
print(f"Found APK: {apk_path} ({file_size} bytes, {file_size / (1024*1024):.2f} MB)")

# 2. Check/create tag and push
print(f"Ensuring tag {tag_name} exists...")
subprocess.run(["git", "tag", "-a", tag_name, "-m", f"Release {tag_name}"], capture_output=True)
push_url = f"https://x-access-token:{token}@github.com/{owner}/{repo}.git"
push_res = subprocess.run(["git", "push", push_url, tag_name], capture_output=True, text=True)
print(f"Tag push result: {push_res.stdout.strip() or push_res.stderr.strip()}")

# 3. Check or create Release via GitHub REST API
headers = {
    "Authorization": f"token {token}",
    "Accept": "application/vnd.github.v3+json",
    "User-Agent": "Uma-Release-Script"
}

release_url = f"https://api.github.com/repos/{owner}/{repo}/releases/tags/{tag_name}"
req = urllib.request.Request(release_url, headers=headers)
release = None

try:
    with urllib.request.urlopen(req) as resp:
        release = json.loads(resp.read().decode("utf-8"))
        print(f"Existing release found: ID {release['id']}, URL {release['html_url']}")
except urllib.error.HTTPError as e:
    if e.code == 404:
        print(f"Release {tag_name} not found. Creating new release...")
        create_url = f"https://api.github.com/repos/{owner}/{repo}/releases"
        body = {
            "tag_name": tag_name,
            "target_commitish": "fix/critical-issues",
            "name": "Uma - Pujo Parikrama v0.1.4 (Enriched Ground Facts & Gemini 3.5 Flash)",
            "body": (
                "## What's New in v0.1.4\n\n"
                "### 1. Enriched, Highly Detailed Kolkata Puja Ground Facts\n"
                "- **Iconic Food Spots Integration**: Proximity-matched world-famous Kolkata eateries (Golbari, Bagbazar Ghat Kochuri, Paramount Sherbets, Indian Coffee House, Putiram, Campari, Bedouin) to pandals.\n"
                "- **Realistic Crowd Windows**: Differentiates Golden Afternoon window (1:30 PM–4:30 PM), Late Night Hopping (1:30 AM–4:00 AM), and Peak Evening Rush (6:30 PM–11:30 PM).\n"
                "- **Kolkata Police & Transit Regulations**: Pedestrian zone vehicular bans from 4 PM, one-way crowd circulation, and Night Metro schedules operating till 4:00 AM on Saptami, Ashtami, and Nabami.\n\n"
                "### 2. Gemini Flash-Tier Intelligence & Free Tier Optimization\n"
                "- Configured **`gemini-3.5-flash`** as primary default model for highest multilingual reasoning and fact adherence.\n"
                "- Multi-candidate fallback cascade: `gemini-3.5-flash` -> `gemini-3-flash-preview` -> `gemini-3.1-flash-lite` -> `gemini-2.5-flash`.\n\n"
                "### 3. Native Multilingual Squad Chat Bot\n"
                "- Fully integrated inside Squad Chat (`@pujo bot` or tapping Puja Bot chip).\n"
                "- Answers natively in Bengali script (বাংলা), Benglish (Banglish), or English."
            ),
            "draft": False,
            "prerelease": False
        }
        create_req = urllib.request.Request(create_url, data=json.dumps(body).encode("utf-8"), headers=headers, method="POST")
        with urllib.request.urlopen(create_req) as create_resp:
            release = json.loads(create_resp.read().decode("utf-8"))
            print(f"Created release: ID {release['id']}, URL {release['html_url']}")
    else:
        raise

release_id = release["id"]
upload_url_template = release["upload_url"] # e.g. "https://uploads.github.com/repos/Arnab-apk/Hopping_Guide/releases/12345/assets{?name,label}"
upload_url = upload_url_template.split("{")[0] + f"?name={asset_name}"

# Check if asset already exists
existing_assets = release.get("assets", [])
for asset in existing_assets:
    if asset["name"] == asset_name:
        print(f"Asset {asset_name} already exists (ID: {asset['id']}). Deleting old asset first...")
        del_req = urllib.request.Request(asset["url"], headers=headers, method="DELETE")
        urllib.request.urlopen(del_req)
        print("Deleted old asset.")

print(f"Uploading APK ({file_size / (1024*1024):.2f} MB) to {upload_url}...")
upload_headers = {
    "Authorization": f"token {token}",
    "Content-Type": "application/vnd.android.package-archive",
    "User-Agent": "Uma-Release-Script"
}

with open(apk_path, "rb") as f:
    apk_data = f.read()

upload_req = urllib.request.Request(upload_url, data=apk_data, headers=upload_headers, method="POST")
with urllib.request.urlopen(upload_req) as upload_resp:
    res_asset = json.loads(upload_resp.read().decode("utf-8"))
    print(f"Upload successful! Asset ID: {res_asset['id']}, Download URL: {res_asset['browser_download_url']}")

print("\n--- DONE! Release v0.1.4 published successfully with APK attached ---")
