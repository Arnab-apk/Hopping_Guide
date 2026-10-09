/// Accepted external links must point to this app's registered schemes or hosts.
class AppDeepLink {
  const AppDeepLink._();

  static const hosts = {
    'sharodiya.com',
    'kolkata-puja-2026.web.app',
    'kolkata-puja-2026.firebaseapp.com',
  };

  static bool isSupported(Uri uri) {
    if (uri.scheme == 'pujoparikrama' || uri.scheme == 'pujo') {
      return uri.host == 'join' || uri.host == 'pandal';
    }
    return uri.scheme == 'https' && hosts.contains(uri.host) &&
        uri.pathSegments.isNotEmpty &&
        (uri.pathSegments.first == 'join' || uri.pathSegments.first == 'pandal');
  }
}
