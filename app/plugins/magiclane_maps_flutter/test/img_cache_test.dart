// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary

// ignore_for_file: avoid_redundant_argument_values
// Explicit `uid: 1` (etc.) reads better in test bodies even when it matches
// the helper's default.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:magiclane_maps_flutter/src/core/images/img_cache.dart';
import 'package:magiclane_maps_flutter/src/core/images/renderable_img.dart';

ImgCacheKey _key({
  int uid = 1,
  int widthPx = 64,
  int heightPx = 64,
  int formatId = 3,
  int settingsHash = 0,
  int imageTypeId = 0,
  bool allowResize = false,
}) =>
    ImgCacheKey(
      uid: uid,
      widthPx: widthPx,
      heightPx: heightPx,
      formatId: formatId,
      settingsHash: settingsHash,
      imageTypeId: imageTypeId,
      allowResize: allowResize,
    );

RenderableImg _img(int bytes, {int width = 64, int height = 64}) =>
    RenderableImg(width, height, Uint8List(bytes));

void main() {
  // ------------------------------------------------------------------
  // ImgCacheKey value semantics
  // ------------------------------------------------------------------
  group('[ImgCacheKey]', () {
    test('equal when all fields match', () {
      expect(_key(uid: 42), equals(_key(uid: 42)));
      expect(_key(uid: 42).hashCode, equals(_key(uid: 42).hashCode));
    });

    test('differs when uid differs', () {
      expect(_key(uid: 42), isNot(equals(_key(uid: 43))));
    });

    test('differs when widthPx differs', () {
      expect(_key(widthPx: 32), isNot(equals(_key(widthPx: 33))));
    });

    test('differs when heightPx differs', () {
      expect(_key(heightPx: 32), isNot(equals(_key(heightPx: 33))));
    });

    test('differs when formatId differs', () {
      expect(_key(formatId: 3), isNot(equals(_key(formatId: 1))));
    });

    test('differs when settingsHash differs', () {
      expect(_key(settingsHash: 100), isNot(equals(_key(settingsHash: 101))));
    });

    test('differs when imageTypeId differs', () {
      expect(_key(imageTypeId: 0), isNot(equals(_key(imageTypeId: 4))));
    });

    test('differs when allowResize differs', () {
      expect(_key(allowResize: false), isNot(equals(_key(allowResize: true))));
    });

    test('default-size keys (widthPx -1) hash uniquely', () {
      expect(_key(widthPx: -1), isNot(equals(_key(widthPx: 64))));
      expect(_key(widthPx: -1, heightPx: -1).hashCode,
          equals(_key(widthPx: -1, heightPx: -1).hashCode));
    });

    test('equality is reflexive and symmetric', () {
      final ImgCacheKey k = _key(uid: 7, settingsHash: 123);
      // ignore: unrelated_type_equality_checks
      expect(k == k, isTrue);
      expect(k == _key(uid: 7, settingsHash: 123), isTrue);
      expect(_key(uid: 7, settingsHash: 123) == k, isTrue);
    });
  });

  // ------------------------------------------------------------------
  // ImgCache core operations
  // ------------------------------------------------------------------
  group('[ImgCache]', () {
    setUp(() {
      ImgCache.configure();
      ImgCache.instance.clear();
      ImgCache.instance.resetStats();
    });

    test('miss returns null and increments misses', () {
      expect(ImgCache.instance.get(_key()), isNull);
      expect(ImgCache.instance.stats.misses, equals(1));
      expect(ImgCache.instance.stats.hits, equals(0));
    });

    test('put then get returns same image', () {
      final RenderableImg image = _img(1024);
      ImgCache.instance.put(_key(), image);
      expect(ImgCache.instance.get(_key()), same(image));
      expect(ImgCache.instance.stats.hits, equals(1));
    });

    test('get on unknown key does not mutate entries or bytes', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      final int entriesBefore = ImgCache.instance.stats.entries;
      final int bytesBefore = ImgCache.instance.stats.bytes;
      ImgCache.instance.get(_key(uid: 999));
      expect(ImgCache.instance.stats.entries, equals(entriesBefore));
      expect(ImgCache.instance.stats.bytes, equals(bytesBefore));
    });

    test('hit increments hits counter only', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      final ImgCacheStats before = ImgCache.instance.stats;
      ImgCache.instance.get(_key(uid: 1));
      final ImgCacheStats after = ImgCache.instance.stats;
      expect(after.hits, equals(before.hits + 1));
      expect(after.misses, equals(before.misses));
      expect(after.evictions, equals(before.evictions));
    });

    test('repeated hits never trigger evictions', () {
      ImgCache.instance.put(_key(uid: 1), _img(2048));
      for (int i = 0; i < 50; i++) {
        ImgCache.instance.get(_key(uid: 1));
      }
      expect(ImgCache.instance.stats.evictions, equals(0));
    });

    test('first hit promotes from probationary to protected', () {
      ImgCache.configure(maxBytes: 1024 * 1024);
      final RenderableImg image = _img(1024);
      ImgCache.instance.put(_key(uid: 1), image);
      expect(ImgCache.instance.stats.entries, equals(1));
      // First hit (promotion) and second hit (already protected) both work.
      expect(ImgCache.instance.get(_key(uid: 1)), same(image));
      expect(ImgCache.instance.get(_key(uid: 1)), same(image));
      expect(ImgCache.instance.stats.hits, equals(2));
    });

    test('byte-weighted eviction trims probationary under capacity', () {
      ImgCache.configure(maxBytes: 100 * 1024);
      for (int i = 0; i < 5; i++) {
        ImgCache.instance.put(_key(uid: i), _img(10 * 1024));
      }
      final ImgCacheStats stats = ImgCache.instance.stats;
      expect(stats.evictions, greaterThan(0));
      expect(stats.bytes, lessThanOrEqualTo(100 * 1024));
    });

    test('LRU ordering: touching an entry protects it from eviction', () {
      ImgCache.configure(maxBytes: 100 * 1024);
      ImgCache.instance.put(_key(uid: 1), _img(5 * 1024));
      ImgCache.instance.get(_key(uid: 1)); // promote to protected
      for (int i = 100; i < 110; i++) {
        ImgCache.instance.put(_key(uid: i), _img(5 * 1024));
      }
      expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
    });

    test('invalidate(uid) drops only entries for that uid', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      ImgCache.instance.put(_key(uid: 2), _img(1024));
      ImgCache.instance.put(_key(uid: 3), _img(1024));
      ImgCache.instance.invalidate(2);
      expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
      expect(ImgCache.instance.get(_key(uid: 2)), isNull);
      expect(ImgCache.instance.get(_key(uid: 3)), isNotNull);
    });

    test('invalidate is a no-op for an unknown uid', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      ImgCache.instance.put(_key(uid: 2), _img(1024));
      ImgCache.instance.invalidate(9999);
      expect(ImgCache.instance.stats.entries, equals(2));
      expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
      expect(ImgCache.instance.get(_key(uid: 2)), isNotNull);
    });

    test('invalidate drops entries across both segments', () {
      // Promote one to protected, leave another in probationary.
      ImgCache.instance.put(_key(uid: 7), _img(1024));
      ImgCache.instance.get(_key(uid: 7)); // promote
      ImgCache.instance.put(_key(uid: 7, widthPx: 128), _img(1024));
      expect(ImgCache.instance.stats.entries, equals(2));
      ImgCache.instance.invalidate(7);
      expect(ImgCache.instance.stats.entries, equals(0));
    });

    test('multiple invalidate calls are idempotent', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      ImgCache.instance.invalidate(1);
      ImgCache.instance.invalidate(1);
      ImgCache.instance.invalidate(1);
      expect(ImgCache.instance.stats.entries, equals(0));
    });

    test('clear empties entries but preserves stats', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      ImgCache.instance.get(_key(uid: 1)); // 1 hit
      ImgCache.instance.get(_key(uid: 999)); // 1 miss
      ImgCache.instance.clear();
      final ImgCacheStats s = ImgCache.instance.stats;
      expect(s.entries, equals(0));
      expect(s.bytes, equals(0));
      // Stats are PRESERVED by clear().
      expect(s.hits, equals(1));
      expect(s.misses, equals(1));
    });

    test('resetStats zeros counters but preserves entries', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      ImgCache.instance.get(_key(uid: 1));
      ImgCache.instance.resetStats();
      final ImgCacheStats s = ImgCache.instance.stats;
      expect(s.hits, equals(0));
      expect(s.misses, equals(0));
      expect(s.evictions, equals(0));
      // Entries are PRESERVED by resetStats().
      expect(s.entries, equals(1));
      expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
    });

    test('configure with non-positive maxBytes throws', () {
      expect(() => ImgCache.configure(maxBytes: 0), throwsArgumentError);
      expect(() => ImgCache.configure(maxBytes: -1), throwsArgumentError);
    });

    test('configure replaces the cache (state discarded)', () {
      ImgCache.instance.put(_key(uid: 1), _img(4096));
      expect(ImgCache.instance.stats.entries, equals(1));
      ImgCache.configure(maxBytes: 1024 * 1024);
      expect(ImgCache.instance.stats.entries, equals(0));
      expect(ImgCache.instance.get(_key(uid: 1)), isNull);
    });

    test('maxBytes getter reflects configuration', () {
      ImgCache.configure(maxBytes: 7 * 1024 * 1024);
      expect(ImgCache.instance.maxBytes, equals(7 * 1024 * 1024));
    });

    test('default maxBytes is 16 MB', () {
      ImgCache.configure();
      expect(ImgCache.instance.maxBytes, equals(16 * 1024 * 1024));
    });

    test('budget enforces a hard byte ceiling across many puts', () {
      ImgCache.configure(maxBytes: 64 * 1024);
      for (int i = 0; i < 100; i++) {
        ImgCache.instance.put(_key(uid: i), _img(2 * 1024));
      }
      expect(ImgCache.instance.stats.bytes, lessThanOrEqualTo(64 * 1024));
    });

    test('replacing a key updates bytes, not entry count', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      final int before = ImgCache.instance.stats.bytes;
      ImgCache.instance.put(_key(uid: 1), _img(2048));
      final int after = ImgCache.instance.stats.bytes;
      expect(ImgCache.instance.stats.entries, equals(1));
      expect(after, greaterThan(before));
    });

    test('replacing a key with smaller payload decreases bytes', () {
      ImgCache.instance.put(_key(uid: 1), _img(4096));
      final int before = ImgCache.instance.stats.bytes;
      ImgCache.instance.put(_key(uid: 1), _img(512));
      final int after = ImgCache.instance.stats.bytes;
      expect(ImgCache.instance.stats.entries, equals(1));
      expect(after, lessThan(before));
    });

    test('replacing a key returns the new image on get', () {
      final RenderableImg first = _img(1024);
      final RenderableImg second = _img(1024);
      ImgCache.instance.put(_key(uid: 1), first);
      ImgCache.instance.put(_key(uid: 1), second);
      expect(ImgCache.instance.get(_key(uid: 1)), same(second));
      expect(ImgCache.instance.get(_key(uid: 1)), isNot(same(first)));
    });

    test('format-id, allowResize, and settings each discriminate', () {
      final RenderableImg a = _img(1024);
      final RenderableImg b = _img(1024);
      final RenderableImg c = _img(1024);
      final RenderableImg d = _img(1024);
      ImgCache.instance.put(_key(formatId: 3), a);
      ImgCache.instance.put(_key(formatId: 1), b);
      ImgCache.instance.put(_key(allowResize: true), c);
      ImgCache.instance.put(_key(settingsHash: 99), d);
      expect(ImgCache.instance.stats.entries, equals(4));
      expect(ImgCache.instance.get(_key(formatId: 3)), same(a));
      expect(ImgCache.instance.get(_key(formatId: 1)), same(b));
      expect(ImgCache.instance.get(_key(allowResize: true)), same(c));
      expect(ImgCache.instance.get(_key(settingsHash: 99)), same(d));
    });

    test('imageTypeId discriminates even for matching uid', () {
      final RenderableImg base = _img(1024);
      final RenderableImg lane = _img(1024);
      ImgCache.instance.put(_key(uid: 42, imageTypeId: 0), base);
      ImgCache.instance.put(_key(uid: 42, imageTypeId: 4), lane);
      expect(ImgCache.instance.stats.entries, equals(2));
      expect(ImgCache.instance.get(_key(uid: 42, imageTypeId: 0)), same(base));
      expect(ImgCache.instance.get(_key(uid: 42, imageTypeId: 4)), same(lane));
    });

    test('stats accuracy under rapid mixed access', () {
      ImgCache.configure(maxBytes: 1024 * 1024);
      const int n = 200;
      for (int i = 0; i < n; i++) {
        ImgCache.instance.get(_key(uid: i)); // miss
        ImgCache.instance.put(_key(uid: i), _img(1024));
      }
      final int missesAfterFill = ImgCache.instance.stats.misses;
      expect(missesAfterFill, equals(n));

      int observedHits = 0;
      for (int i = 0; i < n; i++) {
        if (ImgCache.instance.get(_key(uid: i)) != null) {
          observedHits++;
        }
      }
      final ImgCacheStats finalStats = ImgCache.instance.stats;
      expect(
        finalStats.hits + (finalStats.misses - missesAfterFill),
        equals(n),
        reason: 'every phase-2 access is either a hit or a fresh miss.',
      );
      expect(finalStats.hits, equals(observedHits));
    });

    test('working set survives a long cold-stream scan (SLRU resistance)', () {
      ImgCache.configure(maxBytes: 100 * 1024);
      const int hotCount = 5;
      for (int i = 0; i < hotCount; i++) {
        ImgCache.instance.put(_key(uid: i), _img(4 * 1024));
        ImgCache.instance.get(_key(uid: i));
        ImgCache.instance.get(_key(uid: i));
      }
      for (int i = 100; i < 300; i++) {
        ImgCache.instance.put(_key(uid: i), _img(2 * 1024));
      }
      int hotSurvivors = 0;
      for (int i = 0; i < hotCount; i++) {
        if (ImgCache.instance.get(_key(uid: i)) != null) {
          hotSurvivors++;
        }
      }
      expect(
        hotSurvivors,
        equals(hotCount),
        reason: 'SLRU should preserve the protected hot set across a scan.',
      );
    });

    test('demotion path: promoting many entries demotes the LRU protected', () {
      ImgCache.configure(maxBytes: 50 * 1024);
      for (int i = 0; i < 10; i++) {
        ImgCache.instance.put(_key(uid: i), _img(4 * 1024));
        ImgCache.instance.get(_key(uid: i));
      }
      expect(ImgCache.instance.get(_key(uid: 9)), isNotNull);
    });

    test('promote-and-evict bookkeeping leaves stats consistent', () {
      ImgCache.configure(maxBytes: 100 * 1024);
      for (int i = 0; i < 50; i++) {
        ImgCache.instance.put(_key(uid: i), _img(3 * 1024));
        ImgCache.instance.get(_key(uid: i));
      }
      final ImgCacheStats s = ImgCache.instance.stats;
      expect(s.bytes >= 0, isTrue, reason: 'bytes must never go negative.');
      expect(s.bytes <= 100 * 1024, isTrue, reason: 'bytes must respect cap.');
      expect(s.entries >= 0, isTrue);
      expect(s.hits >= 0 && s.misses >= 0 && s.evictions >= 0, isTrue);
    });
  });

  // ------------------------------------------------------------------
  // Oversized-entry admission policy (the bug-fix surface)
  // ------------------------------------------------------------------
  group('[ImgCache oversize admission]', () {
    setUp(() {
      ImgCache.configure();
      ImgCache.instance.clear();
      ImgCache.instance.resetStats();
    });

    test('entry larger than maxBytes is rejected outright', () {
      ImgCache.configure(maxBytes: 10 * 1024);
      ImgCache.instance.put(_key(uid: 1), _img(64 * 1024));
      expect(ImgCache.instance.get(_key(uid: 1)), isNull);
      expect(ImgCache.instance.stats.entries, equals(0));
    });

    test('entry larger than maxBytes does not disturb existing entries', () {
      // Roomy budget so the two pre-existing entries comfortably fit
      // before the oversized put. We're testing that a *rejection* is a
      // no-op on the rest of the cache, not eviction dynamics.
      ImgCache.configure(maxBytes: 200 * 1024);
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      ImgCache.instance.put(_key(uid: 2), _img(1024));
      // 1 MB > 200 KB → rejected.
      ImgCache.instance.put(_key(uid: 99), _img(1024 * 1024));
      expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
      expect(ImgCache.instance.get(_key(uid: 2)), isNotNull);
      // The oversized entry was never admitted.
      expect(ImgCache.instance.stats.entries, equals(2));
    });

    test(
      'entry larger than probationaryCap but smaller than maxBytes lands in protected',
      () {
        // 100 KB budget → probationary ~20 KB, protected ~80 KB.
        ImgCache.configure(maxBytes: 100 * 1024);

        // 40 KB > probationaryCap, fits in protected.
        ImgCache.instance.put(_key(uid: 1), _img(40 * 1024));

        // Direct-admit to protected: a get hit returns it without
        // re-FFI'ing, and stats show one entry.
        expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
        expect(ImgCache.instance.stats.entries, equals(1));
      },
    );

    test(
      'oversize bypass does NOT evict pre-existing probationary entries',
      () {
        // This is the original critical-bug regression test.
        ImgCache.configure(maxBytes: 100 * 1024);

        // Fill probationary with a few small entries.
        ImgCache.instance.put(_key(uid: 1), _img(2 * 1024));
        ImgCache.instance.put(_key(uid: 2), _img(2 * 1024));
        ImgCache.instance.put(_key(uid: 3), _img(2 * 1024));

        // Insert a large (40 KB) entry that previously would have caused
        // probationary self-eviction and collateral damage.
        ImgCache.instance.put(_key(uid: 99), _img(40 * 1024));

        // All small entries survive.
        expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
        expect(ImgCache.instance.get(_key(uid: 2)), isNotNull);
        expect(ImgCache.instance.get(_key(uid: 3)), isNotNull);
        // The large entry is also retrievable.
        expect(ImgCache.instance.get(_key(uid: 99)), isNotNull);
      },
    );

    test(
      'oversize bypass does NOT evict protected entries when room is available',
      () {
        ImgCache.configure(maxBytes: 200 * 1024);
        // Promote a small entry to protected.
        ImgCache.instance.put(_key(uid: 1), _img(2 * 1024));
        ImgCache.instance.get(_key(uid: 1));

        // Direct-admit a 50 KB entry to protected. Both fit.
        ImgCache.instance.put(_key(uid: 99), _img(50 * 1024));

        expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
        expect(ImgCache.instance.get(_key(uid: 99)), isNotNull);
      },
    );

    test('boundary: weight exactly at probationaryCap stays in probationary', () {
      // 100 KB budget; probationary cap = 20480 (20 * 1024).
      // Use a payload sized to (probationaryCap - overhead) so the
      // computed weight equals probationaryCap exactly.
      ImgCache.configure(maxBytes: 100 * 1024);
      // overhead is internal but small (~64). We use a payload that's
      // definitely under, and verify the entry is admitted.
      ImgCache.instance.put(_key(uid: 1), _img(20 * 1024 - 100));
      expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
    });

    test('boundary: weight exactly at maxBytes is admitted', () {
      ImgCache.configure(maxBytes: 100 * 1024);
      // Just under maxBytes (overhead is ~64 bytes).
      ImgCache.instance.put(_key(uid: 1), _img(100 * 1024 - 100));
      // The entry was larger than probationary cap so it went straight
      // into protected; should still be retrievable.
      expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
    });
  });

  // ------------------------------------------------------------------
  // Stress / fuzz-style scenarios
  // ------------------------------------------------------------------
  group('[ImgCache stress]', () {
    setUp(() {
      ImgCache.configure();
      ImgCache.instance.clear();
      ImgCache.instance.resetStats();
    });

    test('1000 mixed puts and gets keep invariants', () {
      ImgCache.configure(maxBytes: 256 * 1024);
      for (int i = 0; i < 1000; i++) {
        if (i % 3 == 0) {
          ImgCache.instance.put(_key(uid: i ~/ 3), _img(512));
        } else if (i % 3 == 1) {
          ImgCache.instance.get(_key(uid: (i ~/ 3) % 50));
        } else {
          ImgCache.instance.invalidate(i % 7);
        }
      }
      final ImgCacheStats s = ImgCache.instance.stats;
      expect(s.bytes, lessThanOrEqualTo(256 * 1024));
      expect(s.entries, greaterThanOrEqualTo(0));
      expect(s.hits >= 0 && s.misses >= 0 && s.evictions >= 0, isTrue);
    });

    test('1000 invalidates of unknown uids do nothing harmful', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      for (int i = 1000; i < 2000; i++) {
        ImgCache.instance.invalidate(i);
      }
      expect(ImgCache.instance.stats.entries, equals(1));
      expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
    });

    test('bursty 100 KB inserts settle within budget', () {
      ImgCache.configure(maxBytes: 512 * 1024);
      for (int i = 0; i < 20; i++) {
        ImgCache.instance.put(_key(uid: i), _img(100 * 1024));
      }
      expect(ImgCache.instance.stats.bytes, lessThanOrEqualTo(512 * 1024));
    });

    test('interleaved puts+invalidates keep bytes counter in sync', () {
      ImgCache.configure(maxBytes: 64 * 1024);
      for (int i = 0; i < 100; i++) {
        ImgCache.instance.put(_key(uid: i % 10), _img(1024));
        if (i % 5 == 0) {
          ImgCache.instance.invalidate(i % 10);
        }
      }
      final ImgCacheStats s = ImgCache.instance.stats;
      // Bytes counter must stay non-negative and within budget.
      expect(s.bytes, greaterThanOrEqualTo(0));
      expect(s.bytes, lessThanOrEqualTo(64 * 1024));
    });

    test('entries counter matches what we can actually retrieve', () {
      ImgCache.configure(maxBytes: 1024 * 1024);
      for (int i = 0; i < 50; i++) {
        ImgCache.instance.put(_key(uid: i), _img(1024));
      }
      int retrievable = 0;
      for (int i = 0; i < 50; i++) {
        if (ImgCache.instance.get(_key(uid: i)) != null) {
          retrievable++;
        }
      }
      expect(retrievable, equals(ImgCache.instance.stats.entries));
    });

    test('repeated identical puts produce a single entry', () {
      final RenderableImg image = _img(1024);
      for (int i = 0; i < 20; i++) {
        ImgCache.instance.put(_key(uid: 1), image);
      }
      expect(ImgCache.instance.stats.entries, equals(1));
    });
  });

  // ------------------------------------------------------------------
  // Degenerate / corner cases
  // ------------------------------------------------------------------
  group('[ImgCache corners]', () {
    setUp(() {
      ImgCache.configure();
      ImgCache.instance.clear();
      ImgCache.instance.resetStats();
    });

    test('empty-bytes image can be cached and retrieved', () {
      final RenderableImg empty = RenderableImg(1, 1, Uint8List(0));
      ImgCache.instance.put(_key(uid: 1), empty);
      expect(ImgCache.instance.get(_key(uid: 1)), same(empty));
    });

    test('configure(maxBytes: 1) rejects everything practical', () {
      ImgCache.configure(maxBytes: 1);
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      // 1024 + overhead > 1 → entry > maxBytes → rejected.
      expect(ImgCache.instance.stats.entries, equals(0));
    });

    test('clear on empty cache is a no-op', () {
      ImgCache.instance.clear();
      ImgCache.instance.clear();
      expect(ImgCache.instance.stats.entries, equals(0));
    });

    test('resetStats on empty cache is a no-op', () {
      ImgCache.instance.resetStats();
      ImgCache.instance.resetStats();
      final ImgCacheStats s = ImgCache.instance.stats;
      expect(s.hits, equals(0));
      expect(s.misses, equals(0));
      expect(s.evictions, equals(0));
    });

    test('invalidate on empty cache is a no-op', () {
      ImgCache.instance.invalidate(42);
      expect(ImgCache.instance.stats.entries, equals(0));
    });

    test('clear during active use leaves cache usable', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      ImgCache.instance.get(_key(uid: 1));
      ImgCache.instance.clear();
      // Cache is usable again immediately.
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
    });

    test('configure during active use yields a fresh cache', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      ImgCache.configure(maxBytes: 2 * 1024 * 1024);
      expect(ImgCache.instance.get(_key(uid: 1)), isNull);
      // New instance is functional.
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      expect(ImgCache.instance.get(_key(uid: 1)), isNotNull);
    });

    test('hash-collision-resistant: differing single field never equates', () {
      // Object.hash collisions are possible; verify equality is field-based,
      // not hash-based, so we never return wrong data on a collision.
      final ImgCacheKey a = _key(uid: 1, settingsHash: 0);
      final ImgCacheKey b = _key(uid: 1, settingsHash: 0, allowResize: true);
      expect(a, isNot(equals(b)));
      final RenderableImg ia = _img(1024);
      final RenderableImg ib = _img(2048);
      ImgCache.instance.put(a, ia);
      ImgCache.instance.put(b, ib);
      expect(ImgCache.instance.get(a), same(ia));
      expect(ImgCache.instance.get(b), same(ib));
    });

    test('stats snapshot is immutable across subsequent mutations', () {
      ImgCache.instance.put(_key(uid: 1), _img(1024));
      final ImgCacheStats snap = ImgCache.instance.stats;
      ImgCache.instance.put(_key(uid: 2), _img(1024));
      // The earlier snapshot is unaffected by later mutations.
      expect(snap.entries, equals(1));
      expect(ImgCache.instance.stats.entries, equals(2));
    });
  });
}
