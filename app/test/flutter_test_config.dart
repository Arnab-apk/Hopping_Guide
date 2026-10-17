import 'dart:async';
import 'package:kolkata_puja/widgets/pujo_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PujoMap.nativeMapsEnabled = false;
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
  await testMain();
}
