"""Check cached GitHub release access without writing or printing credentials."""
import json
import os
import subprocess
import urllib.request
import urllib.error

repo = 'Arnab-apk/Hopping_Guide'
env = {**os.environ, 'GIT_TERMINAL_PROMPT': '0', 'GCM_INTERACTIVE': 'never'}
result = subprocess.run(['git', 'credential', 'fill'],
    input=f'url=https://github.com/{repo}.git\n\n', capture_output=True,
    text=True, env=env)
credential = dict(line.split('=', 1) for line in result.stdout.splitlines() if '=' in line)
token = os.environ.get('GH_TOKEN') or os.environ.get('GITHUB_TOKEN') or credential.get('password')
if not token:
    print('GitHub sign-in is needed before release upload.')
    raise SystemExit(1)

headers = {'Authorization': f'Bearer {token}', 'Accept': 'application/vnd.github+json',
           'User-Agent': 'UMA-release-check'}
try:
    request = urllib.request.Request(f'https://api.github.com/repos/{repo}', headers=headers)
    with urllib.request.urlopen(request, timeout=25) as response:
        repository = json.load(response)
    print('GitHub repository:', repo)
    print('Release write access:', bool(repository.get('permissions', {}).get('push')))
    request = urllib.request.Request(f'https://api.github.com/repos/{repo}/releases?per_page=5', headers=headers)
    with urllib.request.urlopen(request, timeout=25) as response:
        releases = json.load(response)
    for release in releases:
        print('Existing release:', release['tag_name'], release['html_url'])
except urllib.error.HTTPError as error:
    print('GitHub access check HTTP status:', error.code)
    raise SystemExit(1)
except Exception:
    print('GitHub access check failed; no credentials were printed.')
    raise SystemExit(1)
