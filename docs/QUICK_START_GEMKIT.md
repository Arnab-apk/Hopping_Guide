# 🚀 Quick Start: Magic Lane GemKit Integration

## Current Status: ⚠️ SDK Required

Your app is **prepared** for GemKit but needs the **SDK package from Magic Lane**.

## 📦 What's Already Done

✅ Configuration files created  
✅ Initialization code ready  
✅ Map screen template created  
✅ API token handling implemented  
✅ App runs perfectly with flutter_map fallback  

## 🎯 What You Need

### 1. Get SDK from Magic Lane
Contact: https://www.linkedin.com/company/magiclane

You'll receive:
- 🔑 API Token
- 📦 SDK Package (`gem_kit`)
- 📚 Documentation
- 📄 License Agreement

### 2. Add SDK to Project

**Option A: If on pub.dev**
```yaml
# app/pubspec.yaml
dependencies:
  gem_kit: ^x.x.x
```

**Option B: If git repository**
```yaml
# app/pubspec.yaml
dependencies:
  gem_kit:
    git:
      url: https://github.com/magiclane/gem_kit_flutter
      ref: main
```

**Option C: If local package**
```bash
# Extract SDK to packages/gem_kit/
# Update pubspec.yaml
dependencies:
  gem_kit:
    path: ../../packages/gem_kit
```

### 3. Set API Token

**Method 1: Environment Variable (Recommended)**
```bash
flutter run --dart-define=MAGIC_LANE_API_KEY=your_token_here
```

**Method 2: Android local.properties**
```properties
# app/android/local.properties
MAGIC_LANE_API_KEY=your_token_here
```

**Method 3: iOS Environment**
```bash
# Set before running
export MAGIC_LANE_API_KEY=your_token_here
cd app/ios
pod install
cd ..
flutter run
```

### 4. Uncomment Integration Code

**In `app/lib/main.dart`:**
```dart
// Line ~7: Uncomment import
import 'package:gem_kit/gem_kit.dart';

// Line ~220: Uncomment initialization
await GemKit.initialize(appAuthorization: GemKitConfig.apiToken);
debugPrint('✓ GemKit initialized successfully');
```

**In `app/lib/screens/map_screen_gemkit.dart`:**
```dart
// Line ~7: Uncomment imports
import 'package:gem_kit/gem_kit.dart';
import 'package:gem_kit/api/gem_map.dart';
import 'package:gem_kit/api/gem_map_controller.dart';

// Line ~96: Uncomment GemMap widget
return GemMap(
  onMapCreated: _onMapCreated,
  appAuthorization: const String.fromEnvironment('MAGIC_LANE_API_KEY'),
  initialCameraPosition: CameraPosition(
    target: LatLng(22.5726, 88.3639),
    zoom: 12.0,
  ),
);

// Line ~126+: Uncomment marker methods
_addPandalMarkers();
_addMetroMarkers();
_addFoodMarkers();
```

**In `app/lib/config/gemkit_config.dart`:**
```dart
// Line ~62: Enable GemKit
static const bool useGemKitMap = true;
```

### 5. Run Your App

```bash
cd app
flutter pub get
flutter run --dart-define=MAGIC_LANE_API_KEY=your_token_here
```

## 🔧 Quick Commands

```bash
# Install dependencies
cd app && flutter pub get

# Run with GemKit (after SDK obtained)
flutter run --dart-define=MAGIC_LANE_API_KEY=your_token

# Build release APK
flutter build apk --release --dart-define=MAGIC_LANE_API_KEY=your_token

# Run without GemKit (current setup)
flutter run  # Uses flutter_map fallback

# Check configuration
flutter doctor -v

# Clean build
flutter clean && flutter pub get
```

## 🐛 Troubleshooting

### "Package gem_kit not found"
→ You need to obtain SDK from Magic Lane first

### "Invalid API token"
→ Check token spelling, no extra spaces/quotes

### Android build fails
→ Verify minSdkVersion is 23+ in `app/android/app/build.gradle`

### iOS build fails
→ Run `cd app/ios && pod install`

### Map doesn't show
→ Check console for GemKit initialization messages
→ Verify API token is set correctly

## 📚 Documentation

- **Full Integration Guide**: `MAGIC_LANE_INTEGRATION.md`
- **Status & Progress**: `GEMKIT_INTEGRATION_STATUS.md`
- **Configuration Reference**: `app/lib/config/gemkit_config.dart`
- **Example Map Screen**: `app/lib/screens/map_screen_gemkit.dart`

## 📞 Get Help

**Magic Lane Support**
- LinkedIn: https://www.linkedin.com/company/magiclane
- GitHub: https://github.com/magiclane
- Check your license agreement for support contact

**Your App Status**
```bash
# Check what's working
flutter run  # Should work perfectly with flutter_map

# Check GemKit status (after SDK obtained)
flutter run --dart-define=MAGIC_LANE_API_KEY=test
# Look for "GemKit initialized" in console
```

## ⚡ Fast Track (After SDK Obtained)

1. Add `gem_kit` to pubspec.yaml → `flutter pub get`
2. Set API token → `export MAGIC_LANE_API_KEY=your_token`
3. Uncomment 3 code blocks (main.dart, map_screen_gemkit.dart, gemkit_config.dart)
4. Run → `flutter run --dart-define=MAGIC_LANE_API_KEY=$MAGIC_LANE_API_KEY`
5. See map with GemKit! 🎉

---

**Current Step**: Contact Magic Lane to obtain SDK package and API token.

**Time to Integrate**: ~1 week after SDK obtained

**App Status Now**: ✅ Fully functional with flutter_map
