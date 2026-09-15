# Magic Lane SDK (GemKit) Integration Guide

## Overview
This document provides step-by-step instructions for integrating Magic Lane's GemKit SDK into the Kolkata Puja app.

## Prerequisites

### 1. Obtain Magic Lane SDK License
**Required before proceeding:**
- Contact Magic Lane International B.V. at: https://www.linkedin.com/company/magiclane
- Request Flutter SDK (GemKit) license and API token
- You will receive:
  - API Token (projectApiToken)
  - SDK package files or repository access
  - License agreement documentation

### 2. SDK Package Installation

#### Option A: If provided as pub.dev package
```yaml
# In app/pubspec.yaml
dependencies:
  gem_kit: ^x.x.x  # Version provided by Magic Lane
```

#### Option B: If provided as local package/git repository
```yaml
# In app/pubspec.yaml
dependencies:
  gem_kit:
    git:
      url: [URL provided by Magic Lane]
      ref: [version/tag]
```

#### Option C: If provided as local files
1. Create `packages/gem_kit/` directory in project root
2. Extract Magic Lane SDK files there
3. Add to pubspec.yaml:
```yaml
dependencies:
  gem_kit:
    path: ../../packages/gem_kit
```

## Platform Configuration

### Android Configuration

#### 1. Update `app/android/app/build.gradle`

```gradle
android {
    compileSdkVersion 36
    
    defaultConfig {
        minSdkVersion 23  // GemKit requires minimum API 23
        targetSdkVersion 36
        
        // Add GemKit native architecture support
        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a', 'x86_64'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    // GemKit dependencies (if required)
    implementation 'androidx.appcompat:appcompat:1.6.1'
}
```

#### 2. Update `app/android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Existing permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- GemKit specific permissions -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32" />
    
    <application
        android:name="${applicationName}"
        android:label="Kolkata Puja"
        android:icon="@mipmap/ic_launcher">
        
        <!-- GemKit Configuration -->
        <meta-data
            android:name="com.magiclane.sdk.API_KEY"
            android:value="${MAGIC_LANE_API_KEY}" />
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- ... rest of your activity config -->
        </activity>
    </application>
</manifest>
```

#### 3. Add API Key to `app/android/local.properties`

```properties
sdk.dir=D:\\src\\android-sdk
flutter.sdk=D:\\src\\flutter
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1

# Magic Lane API Key (DO NOT COMMIT THIS FILE)
MAGIC_LANE_API_KEY=YOUR_API_TOKEN_HERE
```

#### 4. Update `app/android/build.gradle` (project level)

```gradle
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // Add if Magic Lane has private Maven repository
        // maven { url "https://maven.magiclane.com/repository" }
    }
}
```

### iOS Configuration

#### 1. Update `app/ios/Podfile`

```ruby
platform :ios, '13.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Add GemKit pod if provided by Magic Lane
  # pod 'GemKit', '~> x.x.x'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # GemKit requires iOS 13.0+
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

#### 2. Update `app/ios/Runner/Info.plist`

```xml
<dict>
    <!-- Existing keys -->
    
    <!-- GemKit API Key -->
    <key>MagicLaneAPIKey</key>
    <string>${MAGIC_LANE_API_KEY}</string>
    
    <!-- Location permissions (already present) -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs access to location for pandal navigation and squad tracking.</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>This app needs location access for enhanced navigation features.</string>
</dict>
```

## Code Integration

### 1. Initialize GemKit in `app/lib/main.dart`

```dart
import 'package:gem_kit/gem_kit.dart';

// Store your API token securely
const String projectApiToken = String.fromEnvironment(
  'MAGIC_LANE_API_KEY',
  defaultValue: 'YOUR_API_TOKEN_HERE',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GemKit BEFORE Firebase
  try {
    await GemKit.initialize(appAuthorization: projectApiToken);
    debugPrint('✓ GemKit initialized successfully');
  } catch (e) {
    debugPrint('⚠ GemKit initialization failed: $e');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  // ... rest of initialization
  
  runApp(/* ... */);
}
```

### 2. Create GemKit Map Screen

Create `app/lib/screens/map_screen_gemkit.dart` - see separate implementation file.

## Running the App

### Development (with API key as environment variable)
```bash
cd app
flutter run --dart-define=MAGIC_LANE_API_KEY=your_actual_token_here
```

### Build Release APK
```bash
cd app
flutter build apk --release --dart-define=MAGIC_LANE_API_KEY=your_actual_token_here
```

## Feature Migration Checklist

- [ ] Basic map display with GemMap widget
- [ ] Pandal markers with clustering
- [ ] Metro station overlay
- [ ] Food spot overlay
- [ ] Search integration
- [ ] Routing service (pedestrian)
- [ ] Turn-by-turn navigation
- [ ] Custom trail visualization
- [ ] Squad member tracking on GemMap
- [ ] Offline map support
- [ ] Performance optimization

## API Token Security

**IMPORTANT:** Never commit your Magic Lane API token to version control!

Add to `.gitignore`:
```
# Magic Lane API Token
**/local.properties
**/.env
**/magic_lane_config.dart
```

## Troubleshooting

### Common Issues

1. **"GemKit not found" error**
   - Verify you've received the SDK package from Magic Lane
   - Check package is correctly added to pubspec.yaml
   - Run `flutter pub get`

2. **"Invalid API token" error**
   - Verify token is correctly set in environment variable
   - Check token hasn't expired
   - Contact Magic Lane support

3. **Build failures on Android**
   - Check minSdkVersion is at least 23
   - Verify NDK is installed
   - Clean and rebuild: `flutter clean && flutter pub get`

4. **iOS build failures**
   - Run `cd ios && pod install`
   - Check deployment target is iOS 13.0+
   - Clean derived data

## Support Contacts

- **Magic Lane Support**: Check your license agreement for support contact
- **Documentation**: https://github.com/magiclane (check for private repos you may have access to)
- **LinkedIn**: https://www.linkedin.com/company/magiclane

## Next Steps

After obtaining the SDK from Magic Lane:
1. Update this document with actual package details
2. Implement the map screen integration
3. Migrate existing features one by one
4. Test thoroughly on both Android and iOS
5. Update README.md with Magic Lane attribution
