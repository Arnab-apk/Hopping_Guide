// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Used for hooking into the Dart garbage collector for deallocation of native resources.
/// Has two separate implementations for web and mobile platforms.
///
/// This interface should not be used nor implemented directly by clients.
///
/// @nodoc
abstract class GemObject {
  void initBase(final int id); // Abstract method for initialization
}
