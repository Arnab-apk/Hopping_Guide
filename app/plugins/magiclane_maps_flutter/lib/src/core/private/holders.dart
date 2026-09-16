// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Used internally to hold a string value that is modified asynchronously.
/// This class is not intended for public use.
///
/// @nodoc
@internal
class StringHolder extends GemAutoreleaseObject {
  factory StringHolder() {
    return _create();
  }

  StringHolder.init(super.id);

  String get value {
    final OperationResult resultString = objectMethod(
      pointerId,
      'StringHolderFlutter',
      'value',
    );
    return resultString['result'];
  }

  static StringHolder _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'StringHolderFlutter'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return StringHolder.init(decodedVal['result']);
  }
}

/// Used internally to hold an image value that is modified asynchronously.
/// This class is not intended for public use.
///
/// @nodoc
@internal
class ImgHolder extends GemAutoreleaseObject {
  factory ImgHolder() {
    return _create();
  }

  ImgHolder.init(super.id);

  Img get value {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ImgHolderFlutter',
      'value',
    );
    return Img.init(resultString['result']);
  }

  static ImgHolder _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'ImgHolderFlutter'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return ImgHolder.init(decodedVal['result']);
  }
}

/// Used internally to handle external info retrieval for landmarks.
/// This class is not intended for public use directly.
///
/// @nodoc
@internal
class ExternalInfoHandler extends EventDrivenProgressListener {
  ExternalInfoHandler(ExternalInfo externalInfo)
    : _externalInfo = externalInfo,
      super();

  final ExternalInfo _externalInfo;

  void cancelWikiInfo() {
    objectMethod(_externalInfo.pointerId, 'ExternalInfo', 'cancelWikiInfo');
  }
}
