// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// @nodoc
enum ObjType {
  @Deprecated('unknown may cause memory leaks and should not be used.')
  unknown,
  gemImage,
  gemBuffer,
}

/// @nodoc
extension ObjTypeExtension on ObjType {
  int get id {
    switch (this) {
      // ignore: deprecated_member_use_from_same_package
      case ObjType.unknown:
        return 0;
      case ObjType.gemImage:
        return 1;
      case ObjType.gemBuffer:
        return 2;
    }
  }
}
