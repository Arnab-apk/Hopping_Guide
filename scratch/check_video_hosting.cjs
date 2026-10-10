const { execFileSync } = require('node:child_process');
async function main() {
  const accounts = JSON.parse(execFileSync(process.env.ComSpec, ['/d', '/s', '/c', 'firebase.cmd login:list --json'], { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] })).result;
  const token = accounts[0]?.tokens?.access_token;
  if (!token) throw new Error('Firebase CLI login is required.');
  const response = await fetch('https://cloudbilling.googleapis.com/v1/projects/kolkata-puja-2026/billingInfo', {
    headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(25000),
  });
  const data = await response.json();
  if (!response.ok) {
    console.log('Billing check HTTP status:', response.status);
    console.log('Reason:', data.error?.details?.find(item => item.reason)?.reason || data.error?.status || 'unknown');
    process.exitCode = 1;
  } else {
    console.log('Firebase project:', 'kolkata-puja-2026');
    console.log('Billing enabled:', data.billingEnabled === true);
  }
}
main().catch(() => { console.error('Could not check Firebase hosting readiness.'); process.exitCode = 1; });
