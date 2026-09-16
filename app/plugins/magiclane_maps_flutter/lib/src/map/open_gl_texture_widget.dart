// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// Texture Widget for Map
///
/// The API user should not use this widget directly. It is used internally by the SDK
/// to render OpenGL content onto a Flutter texture.
///
/// ## See also:
///
/// - [GemMap] - The map widget that uses this texture widget internally.
///
/// {@category Maps & 3D Scenes}
@experimental
class OpenGLTextureWidget extends StatefulWidget {
  const OpenGLTextureWidget({
    super.key,
    this.width = 512,
    this.height = 512,
    this.onPlatformViewCreated,
  });
  final int width;
  final int height;
  final PlatformViewCreatedCallback? onPlatformViewCreated;

  @override
  State<OpenGLTextureWidget> createState() => _OpenGLTextureWidgetState();
}

class _OpenGLTextureWidgetState extends State<OpenGLTextureWidget> {
  int? _textureId;
  static const MethodChannel _channel = MethodChannel(
    'plugins.flutter.dev/gem_maps',
  );

  @override
  void initState() {
    super.initState();
    _createTexture();
  }

  Future<void> _createTexture() async {
    final int? textureId = await _channel.invokeMethod<int>(
      'createOpenGLTexture',
      <String, dynamic>{'width': widget.width, 'height': widget.height},
    );
    setState(() {
      _textureId = textureId;
    });
    if (textureId != null && widget.onPlatformViewCreated != null) {
      widget.onPlatformViewCreated!(textureId);
    }
  }

  Future<void> _disposeTexture() async {
    if (_textureId != null) {
      await _channel.invokeMethod('disposeOpenGLTexture', <String, dynamic>{
        'textureId': _textureId,
      });
    }
  }

  @override
  void didUpdateWidget(OpenGLTextureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width || oldWidget.height != widget.height) {
      _updateTextureSize();
    }
  }

  Future<void> _updateTextureSize() async {
    if (_textureId != null) {
      await _channel.invokeMethod('onSurfaceChanged', <String, int?>{
        'textureId': _textureId,
        'width': widget.width,
        'height': widget.height,
      });
    }
  }

  @override
  void dispose() {
    _disposeTexture();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_textureId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Texture(textureId: _textureId!);
  }
}
