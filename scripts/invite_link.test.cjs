const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(require('node:path').join(__dirname, '../app/hosting/invite.js'), 'utf8');
function render(link, userAgent = 'Android') {
  const elements = Object.fromEntries(['title', 'message', 'code', 'open', 'invite'].map(id => [id, { hidden: true }]));
  vm.runInNewContext(source, { URL, window: { location: { href: link } }, navigator: { userAgent }, document: { getElementById: id => elements[id] } });
  return elements;
}
test('shared query invite opens the existing Android app with the exact code', () => {
  const page = render('https://kolkata-puja-2026.web.app/join?code=puja7k9x');
  assert.equal(page.invite.hidden, false);
  assert.equal(page.code.textContent, 'PUJA7K9X');
  assert.equal(page.open.href, 'intent://join?code=PUJA7K9X#Intent;scheme=pujoparikrama;package=com.kolkatapuja.kolkata_puja;end');
});
test('path invite supports custom scheme fallback', () => {
  const page = render('https://kolkata-puja-2026.web.app/join/PUJA7K9X', 'Other');
  assert.equal(page.open.href, 'pujoparikrama://join?code=PUJA7K9X');
});
test('missing and malformed invites cannot launch the app', () => {
  for (const suffix of ['', '?code=bad', '?code=%3Cscript%3E', '?code=12345678%23Intent']) {
    const page = render('https://kolkata-puja-2026.web.app/join' + suffix);
    assert.equal(page.invite.hidden, true);
    assert.equal(page.open.href, undefined);
  }
});
test('hosting serves Android association file including dot directory', () => {
  const config = require('../app/firebase.json').hosting;
  assert.ok(!config.ignore.includes('**/.*'));
  const links = require('../app/hosting/.well-known/assetlinks.json');
  assert.equal(links[0].target.package_name, 'com.kolkatapuja.kolkata_puja');
  assert.match(links[0].target.sha256_cert_fingerprints[0], /^([A-F0-9]{2}:){31}[A-F0-9]{2}$/);
});
