// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/core/common/gem_object_interface.dart';

/// Used for hooking into the Dart garbage collector for deallocation of native resources on mobile platforms.
///
/// @nodoc
class GemObjectImpl extends GemObject {
  @override
  void initBase(final int id) {}
}
