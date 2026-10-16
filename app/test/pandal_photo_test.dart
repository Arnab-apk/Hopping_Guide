import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/models/pandal_photo.dart';
import 'package:kolkata_puja/models/place.dart';

void main() {
  test('photo metadata survives pandal and unified place round trips', () {
    final pandal = Pandal.fromMap('photo_pandal', {
      'name': 'Photo Pandal',
      'photos': [
        {
          'url': 'https://example.com/idol.jpg',
          'caption': 'The idol at dusk',
          'credit': 'Puja committee',
          'source_url': 'https://example.com/pandal',
          'year': 2025,
          'rights_status': 'approved',
        },
      ],
    });
    final restored = Pandal.fromMap(pandal.id, pandal.toFirestore());
    final place = Place.fromPandal(restored);
    final fromPlace = Place.fromDoc(place.toMap(), place.id).rawPandal!;
    expect(fromPlace.photoGallery.single.toMap(), pandal.photos.single.toMap());
    expect(place.imageUrl, pandal.photos.single.url);
  });

  test('legacy cover remains usable without losing its gallery credit', () {
    final pandal = Pandal.fromMap('legacy', {
      'image_url': 'https://example.com/cover.jpg',
      'photos': [
        {'url': 'https://example.com/cover.jpg', 'credit': 'Photographer'},
        {'url': 'https://example.com/second.jpg'},
      ],
    });
    expect(pandal.photoGallery, hasLength(2));
    expect(pandal.photoGallery.first.credit, 'Photographer');
    expect(Pandal.fromMap('old', {'image_url': pandal.imageUrl}).photoGallery,
        hasLength(1));
  });

  test('malformed photos are ignored without inventing dates or provenance', () {
    final photos = PandalPhoto.parseList([
      null, 42, {},
      {'url': 'javascript:alert(1)'},
      {'url': 'file:///private/image.jpg'},
      {'url': 'https://user:password@example.com/photo.jpg'},
      {'url': ' https://example.com/photo.jpg ', 'year': 'not a year'},
      {'url': 'https://example.com/photo.jpg', 'year': 2026},
      'https://example.com/other.jpg',
    ]);
    expect(photos, hasLength(2));
    expect(photos.first.year, isNull);
    expect(photos.first.credit, isEmpty);
    expect(photos.first.rightsStatus, 'unknown');
    expect(PandalPhoto.parseList('not a list'), isEmpty);
  });
}
