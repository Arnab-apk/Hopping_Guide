// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary

/// Web-compatible BitField implementation using Set
class PlatformBitField<T> {
  /// Creates a BitField with the specified length (ignored on web)
  PlatformBitField(int _);

  final Set<T> _set = <T>{};

  /// Gets whether the field is set
  bool operator [](T key) => _set.contains(key);

  /// Sets or clears a field
  void operator []=(T key, bool value) {
    if (value) {
      _set.add(key);
    } else {
      _set.remove(key);
    }
  }
}
