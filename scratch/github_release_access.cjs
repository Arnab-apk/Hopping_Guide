// Only print repository metadata; never print or persist credential-helper output.
const { spawnSync } = require('node:child_process');
async function main() {
  const repo = 'Arnab-apk/Hopping_Guide';
  const result = spawnSync('git', ['credential', 'fill'], {
    input: `url=https://github.com/${repo}.git\n\n`, encoding: 'utf8',
    env: { ...process.env, GIT_TERMINAL_PROMPT: '0', GCM_INTERACTIVE: 'never' },
  });
  const credential = Object.fromEntries((result.stdout || '').split(/\r?\n/)
    .filter(line => line.includes('=')).map(line => { const i = line.indexOf('='); return [line.slice(0,i), line.slice(i+1)]; }));
  const token = process.env.GH_TOKEN || process.env.GITHUB_TOKEN || credential.password;
  if (!token) { console.log('GitHub sign-in is needed before release upload.'); process.exitCode = 1; return; }
  const headers = { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json', 'User-Agent': 'UMA-release-check' };
  const response = await fetch(`https://api.github.com/repos/${repo}`, { headers, signal: AbortSignal.timeout(25000) });
  if (!response.ok) { console.log('GitHub access check HTTP status:', response.status); process.exitCode = 1; return; }
  const repository = await response.json();
  console.log('GitHub repository:', repo);
  console.log('Release write access:', repository.permissions?.push === true);
  const releasesResponse = await fetch(`https://api.github.com/repos/${repo}/releases?per_page=5`, { headers, signal: AbortSignal.timeout(25000) });
  if (!releasesResponse.ok) { console.log('Release list HTTP status:', releasesResponse.status); return; }
  for (const release of await releasesResponse.json()) console.log('Existing release:', release.tag_name, release.html_url);
}
main().catch(() => { console.error('GitHub access check failed; no credentials were printed.'); process.exitCode = 1; });
