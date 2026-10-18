(function () {
  'use strict';
  const url = new URL(window.location.href);
  const path = url.pathname.split('/').filter(Boolean);
  const code = (url.searchParams.get('code') || (path[0] === 'join' ? path[1] : '') || '').trim().toUpperCase();
  if (!/^[A-Z0-9]{8}$/.test(code)) {
    document.getElementById('title').textContent = 'Check your invite link';
    document.getElementById('message').textContent = 'This link is missing a valid group code. Ask your friend to share the invite again.';
    return;
  }
  document.getElementById('code').textContent = code;
  const scheme = 'pujoparikrama://join?code=' + encodeURIComponent(code);
  document.getElementById('open').href = /Android/i.test(navigator.userAgent)
    ? 'intent://join?code=' + encodeURIComponent(code) + '#Intent;scheme=pujoparikrama;package=com.kolkatapuja.kolkata_puja;end'
    : scheme;
  document.getElementById('invite').hidden = false;
})();
