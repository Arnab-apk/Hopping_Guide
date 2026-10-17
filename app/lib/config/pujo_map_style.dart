import 'dart:convert';

import 'package:flutter/services.dart';

/// OpenFreeMap's public styles, also used by Pujo Map. Assets pin the visual
/// design; tiles, glyphs and sprites continue to come from OpenFreeMap.
class PujoMapStyle {
  const PujoMapStyle._();

  static Future<String> load({
    required bool dark,
    bool moreNames = true,
    bool threeDimensional = true,
  }) async {
    final source = await rootBundle.loadString(
      'assets/maps/${dark ? 'dark' : 'liberty'}.json',
    );
    return prepare(
      source,
      dark: dark,
      moreNames: moreNames,
      threeDimensional: threeDimensional,
    );
  }

  static String prepare(
    String source, {
    required bool dark,
    bool moreNames = true,
    bool threeDimensional = true,
  }) {
    final style =
        jsonDecode(source.replaceFirst('\uFEFF', '')) as Map<String, dynamic>;
    final layers = (style['layers'] as List).cast<Map<String, dynamic>>();
    if (!layers.any((layer) => layer['type'] == 'fill-extrusion')) {
      final buildingIndex = layers.indexWhere(
        (layer) => layer['id'] == 'building',
      );
      layers.insert(buildingIndex + 1, {
        'id': 'building-3d',
        'type': 'fill-extrusion',
        'source': 'openmaptiles',
        'source-layer': 'building',
        'minzoom': 14,
        'paint': {
          'fill-extrusion-color': dark ? '#333a46' : '#dedbd5',
          'fill-extrusion-height': [
            'coalesce',
            ['get', 'render_height'],
            3,
          ],
          'fill-extrusion-base': [
            'coalesce',
            ['get', 'render_min_height'],
            0,
          ],
          'fill-extrusion-opacity': 0.85,
        },
      });
    }
    for (final layer in layers) {
      if (layer['type'] == 'fill-extrusion') {
        layer['layout'] = {
          ...?layer['layout'] as Map<String, dynamic>?,
          'visibility': threeDimensional ? 'visible' : 'none',
        };
      }
      if (layer['type'] == 'symbol' &&
          layer['source-layer'] == 'poi' &&
          !moreNames) {
        layer['layout'] = {
          ...?layer['layout'] as Map<String, dynamic>?,
          'visibility': 'none',
        };
      }
    }
    style['layers'] = layers;
    return jsonEncode(style);
  }
}
