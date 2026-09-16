// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:collection';

import 'package:magiclane_maps_flutter/src/core/images/renderable_img.dart';
import 'package:meta/meta.dart';

/// Cache key for rendered image bytes produced by `GemKitPlatform.callGetFlutterImg`.
///
/// Combines the content-stable native [uid] with the render-time parameters
/// that influence output (size, format, render settings, image type). All
/// fields are value-compared so semantically equal renders collapse to one
/// cache entry. `widthPx` and `heightPx` of `-1` mean "SDK default size".
@immutable
class ImgCacheKey {
  const ImgCacheKey({
    required this.uid,
    required this.widthPx,
    required this.heightPx,
    required this.formatId,
    required this.settingsHash,
    required this.imageTypeId,
    required this.allowResize,
  });

  /// Content-stable native id (see `ImgBase.uid` in images.dart).
  final int uid;

  /// Requested width in pixels, or `-1` for SDK default.
  final int widthPx;

  /// Requested height in pixels, or `-1` for SDK default.
  final int heightPx;

  /// Encoded format id (`ImageFileFormat.id`).
  final int formatId;

  /// Stable hash of the render-settings struct (or `0` when no settings apply).
  final int settingsHash;

  /// Image type discriminator (`ImageType.id`) — defends against uid
  /// collisions across image types.
  final int imageTypeId;

  /// Whether the SDK was allowed to choose the optimal aspect ratio.
  final bool allowResize;

  @override
  bool operator ==(Object other) =>
      other is ImgCacheKey &&
      other.uid == uid &&
      other.widthPx == widthPx &&
      other.heightPx == heightPx &&
      other.formatId == formatId &&
      other.settingsHash == settingsHash &&
      other.imageTypeId == imageTypeId &&
      other.allowResize == allowResize;

  @override
  int get hashCode => Object.hash(
    uid,
    widthPx,
    heightPx,
    formatId,
    settingsHash,
    imageTypeId,
    allowResize,
  );
}

/// Diagnostics for [ImgCache] effectiveness.
///
/// Snapshot returned by [ImgCache.stats]; counters are cumulative since the
/// last [ImgCache.resetStats] (NOT reset by [ImgCache.clear]) and are safe to
/// log periodically.
@immutable
class ImgCacheStats {
  const ImgCacheStats({
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.bytes,
    required this.entries,
  });

  /// Number of `get` calls that returned a cached image.
  final int hits;

  /// Number of `get` calls that missed.
  final int misses;

  /// Number of entries dropped to keep the cache within its byte budget.
  final int evictions;

  /// Current resident size in bytes across both SLRU segments.
  final int bytes;

  /// Current entry count across both SLRU segments.
  final int entries;
}

/// Internal storage record for a cached render.
class _CacheEntry {
  _CacheEntry(this.image, this.weight);
  final RenderableImg image;
  final int weight;
}

/// Byte-weighted Segmented-LRU cache for rendered image bytes.
///
/// The cache lives in pure Dart and stores [RenderableImg] instances (each
/// holding a Dart [Uint8List]).
///
/// ## Eviction
///
/// Two byte-budgeted segments form the SLRU: probationary (default 20%) and
/// protected (default 80%). New entries normally land in probationary; a
/// subsequent [get] hit promotes them to protected. When protected
/// overflows, its least-recently-used entry is demoted to probationary; when
/// probationary overflows, its least-recently-used entry is evicted. This
/// split absorbs one-shot render bursts without flushing the warm working
/// set kept in protected.
///
/// ## Admission tiers
///
/// An entry's weight (bytes + bookkeeping overhead) determines where it
/// lands on insertion:
///   * `weight > maxBytes`  → **rejected**. The render is too large for the
///     cache regardless of segment.
///   * `weight > _probationaryCap` → **inserted directly into protected**.
///     A strict-SLRU implementation would put everything in probationary
///     first, but for an entry larger than the probationary segment that
///     produces an immediate self-eviction (and may evict otherwise hot
///     probationary entries as collateral). Bypassing probationary keeps
///     large entries useful while staying within the total byte budget.
///   * `weight <= _probationaryCap` → standard SLRU path (probationary first).
///
/// ## Invalidation
///
/// - `uid` is content-stable per the SDK contract, so the cache has no TTL
/// and no automatic invalidation hooks. Callers can clear all entries
/// ([clear]) or drop entries for a single underlying image ([invalidate]).
/// - `GemKitPlatform.disposeGemSdk` calls [clear] during teardown.
/// - [invalidate] iterates each segment to drop matching uids, which is O(n)
/// in the segment size.
class ImgCache {
  ImgCache._(this._maxBytes)
    : _probationaryCap = (_maxBytes * _probationaryFraction).round(),
      _protectedCap = _maxBytes - (_maxBytes * _probationaryFraction).round();

  /// Default byte budget — 16 MB. Configurable via [configure].
  static const int kDefaultMaxBytes = 16 * 1024 * 1024;

  /// Approximate bookkeeping overhead per entry: LinkedHashMap node + key
  /// fields + Dart object headers. Used to weight tiny renders so the cache
  /// doesn't admit thousands of zero-byte phantom entries that each cost
  /// more in map overhead than their payload.
  ///
  /// The constant is a heuristic — actual node size varies by platform (VM
  /// AOT vs JIT vs dart2js). Treat the byte budget as approximate, not
  /// exact; the protection it gives against tiny-entry flooding matters
  /// more than the absolute accuracy.
  static const int _entryOverheadBytes = 64;

  /// Fraction of [_maxBytes] reserved for probationary (new) entries.
  static const double _probationaryFraction = 0.2;

  static ImgCache _instance = ImgCache._(kDefaultMaxBytes);

  /// The process-wide cache instance for the current isolate.
  static ImgCache get instance => _instance;

  /// Replaces the cache with a fresh one sized to [maxBytes]. Any cached
  /// entries are discarded. Intended for application startup or tests.
  static void configure({int maxBytes = kDefaultMaxBytes}) {
    if (maxBytes <= 0) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'must be positive');
    }
    _instance = ImgCache._(maxBytes);
  }

  final int _maxBytes;
  final int _probationaryCap;
  final int _protectedCap;

  /// Configured byte budget. Sum of the probationary and protected caps
  /// (modulo rounding). Useful for surfacing in diagnostics.
  int get maxBytes => _maxBytes;

  // LinkedHashMap preserves insertion order; "most recently used" is the
  // tail. Use remove+re-insert to bump an entry to the tail.
  final LinkedHashMap<ImgCacheKey, _CacheEntry> _probationary =
      LinkedHashMap<ImgCacheKey, _CacheEntry>();
  final LinkedHashMap<ImgCacheKey, _CacheEntry> _protected =
      LinkedHashMap<ImgCacheKey, _CacheEntry>();

  int _probationaryBytes = 0;
  int _protectedBytes = 0;
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  /// Returns the cached image for [key], or null on miss.
  ///
  /// A probationary hit promotes the entry to protected (and may demote the
  /// LRU protected entry back to probationary). A protected hit moves the
  /// entry to the MRU position within protected.
  ///
  /// Hits never trigger evictions: by construction every cached entry has
  /// weight ≤ `_protectedCap`, so promoting from probationary to protected
  /// always succeeds without evicting the just-promoted entry. The only
  /// evictions that can happen during [get] are demotions of older
  /// protected entries, which is the desired SLRU behavior.
  RenderableImg? get(ImgCacheKey key) {
    final _CacheEntry? promoted = _probationary.remove(key);
    if (promoted != null) {
      _probationaryBytes -= promoted.weight;
      _hits++;
      _admitProtected(key, promoted);
      return promoted.image;
    }
    final _CacheEntry? hit = _protected.remove(key);
    if (hit != null) {
      _protectedBytes -= hit.weight;
      _protected[key] = hit;
      _protectedBytes += hit.weight;
      _hits++;
      return hit.image;
    }
    _misses++;
    return null;
  }

  /// Inserts [image] under [key]. Existing entries for [key] are replaced.
  ///
  /// Admission policy is weight-tiered (see class doc): oversized renders
  /// are rejected, large-but-cacheable renders go straight into protected,
  /// normal-sized renders take the standard probationary path.
  void put(ImgCacheKey key, RenderableImg image) {
    // Drop any existing entry first; bookkeeping below assumes an insert.
    _removeKey(key);

    final int weight = image.bytes.lengthInBytes + _entryOverheadBytes;

    // Tier 1: too large for the cache at all.
    if (weight > _maxBytes) {
      return;
    }

    // Tier 2: fits in protected but not in probationary. Insert directly
    // into protected to avoid the self-eviction-and-collateral pattern.
    if (weight > _probationaryCap) {
      _admitProtected(key, _CacheEntry(image, weight));
      return;
    }

    // Tier 3: standard SLRU path. New entry lands in probationary.
    _probationary[key] = _CacheEntry(image, weight);
    _probationaryBytes += weight;
    _trimProbationary();
  }

  /// Drops every entry whose key matches [uid].
  ///
  /// O(n) in the size of each segment. Use after a content change that is
  /// not reflected in a new native uid (e.g., theme/skin reload).
  void invalidate(int uid) {
    _probationaryBytes -= _dropMatching(_probationary, uid);
    _protectedBytes -= _dropMatching(_protected, uid);
  }

  /// Empties both segments. Stats counters are preserved — see [resetStats].
  ///
  /// Hooked into `GemKitPlatform.disposeGemSdk`. Apps can also call this
  /// from a memory-pressure handler.
  void clear() {
    _probationary.clear();
    _protected.clear();
    _probationaryBytes = 0;
    _protectedBytes = 0;
  }

  /// Zeros the cumulative hit / miss / eviction counters.
  ///
  /// Decoupled from [clear] so monitoring can establish a baseline at any
  /// point without disturbing cache contents (or vice versa: drop entries
  /// during memory pressure while preserving lifetime stats for telemetry).
  void resetStats() {
    _hits = 0;
    _misses = 0;
    _evictions = 0;
  }

  /// Cumulative diagnostics since the last [resetStats] (NOT reset by
  /// [clear]).
  ImgCacheStats get stats => ImgCacheStats(
    hits: _hits,
    misses: _misses,
    evictions: _evictions,
    bytes: _probationaryBytes + _protectedBytes,
    entries: _probationary.length + _protected.length,
  );

  /// Inserts [entry] into protected as the MRU; demotes the LRU protected
  /// entry back to probationary if the segment is over capacity.
  ///
  /// Defensive: stops demoting once the just-inserted entry would be the
  /// next candidate. This can only happen for entries admitted via the
  /// large-entry bypass; for entries arriving via probationary promotion
  /// the weight is bounded by `_probationaryCap` < `_protectedCap`, so the
  /// loop terminates naturally.
  void _admitProtected(ImgCacheKey key, _CacheEntry entry) {
    _protected[key] = entry;
    _protectedBytes += entry.weight;
    while (_protectedBytes > _protectedCap && _protected.length > 1) {
      final ImgCacheKey demoteKey = _protected.keys.first;
      if (demoteKey == key) {
        // Would evict the just-inserted entry; bail out. The cache may
        // temporarily exceed `_protectedCap` but stays within `_maxBytes`.
        break;
      }
      final _CacheEntry demoted = _protected.remove(demoteKey)!;
      _protectedBytes -= demoted.weight;
      if (demoted.weight <= _probationaryCap) {
        // Standard SLRU demotion.
        _probationary[demoteKey] = demoted;
        _probationaryBytes += demoted.weight;
        _trimProbationary();
      } else {
        // Demoted entry would not fit in probationary either (large bypass
        // entry that just got demoted). Drop it outright.
        _evictions++;
      }
    }
  }

  /// Evicts the LRU probationary entries until under capacity.
  void _trimProbationary() {
    while (_probationaryBytes > _probationaryCap && _probationary.isNotEmpty) {
      final ImgCacheKey evictKey = _probationary.keys.first;
      final _CacheEntry evicted = _probationary.remove(evictKey)!;
      _probationaryBytes -= evicted.weight;
      _evictions++;
    }
  }

  /// Removes [key] from whichever segment holds it and adjusts the byte
  /// counter. Used by [put] before inserting a replacement value.
  void _removeKey(ImgCacheKey key) {
    final _CacheEntry? probationaryHit = _probationary.remove(key);
    if (probationaryHit != null) {
      _probationaryBytes -= probationaryHit.weight;
      return;
    }
    final _CacheEntry? protectedHit = _protected.remove(key);
    if (protectedHit != null) {
      _protectedBytes -= protectedHit.weight;
    }
  }

  /// Removes every entry whose key matches [uid]; returns the bytes freed.
  int _dropMatching(LinkedHashMap<ImgCacheKey, _CacheEntry> bucket, int uid) {
    int freed = 0;
    bucket.removeWhere((ImgCacheKey key, _CacheEntry entry) {
      final bool match = key.uid == uid;
      if (match) {
        freed += entry.weight;
      }
      return match;
    });
    return freed;
  }
}
