/// A real pandal photograph with provenance independent of the festival edition.
class PandalPhoto {
  const PandalPhoto({
    required this.url,
    this.caption = '',
    this.credit = '',
    this.sourceUrl = '',
    this.year,
    this.rightsStatus = 'unknown',
  });

  final String url;
  final String caption;
  final String credit;
  final String sourceUrl;
  final int? year;
  final String rightsStatus;

  static bool isSupportedUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }

  static List<PandalPhoto> parseList(dynamic raw) {
    if (raw is! List) return const [];
    final photos = <PandalPhoto>[];
    final seen = <String>{};
    for (final item in raw) {
      final map = item is Map ? item : <String, dynamic>{};
      final url = (item is String ? item : map['url'])?.toString().trim() ?? '';
      if (!isSupportedUrl(url) || !seen.add(url)) continue;
      final year = int.tryParse(map['year']?.toString() ?? '');
      photos.add(PandalPhoto(
        url: url,
        caption: map['caption']?.toString().trim() ?? '',
        credit: map['credit']?.toString().trim() ?? '',
        sourceUrl: map['source_url']?.toString().trim() ?? '',
        year: year != null && year >= 1900 && year <= 2100 ? year : null,
        rightsStatus: map['rights_status']?.toString() ?? 'unknown',
      ));
    }
    return List.unmodifiable(photos);
  }

  Map<String, dynamic> toMap() => {
    'url': url,
    'caption': caption,
    'credit': credit,
    'source_url': sourceUrl,
    if (year != null) 'year': year,
    'rights_status': rightsStatus,
  };
}
