# Magic Lane Maps SDK for Flutter
 
Bring high-performance, feature-rich mapping, routing, and navigation to your Flutter apps. The Magic Lane Maps SDK delivers global coverage, turn-by-turn navigation, offline functionality, and real-time traffic. Build immersive, real-time navigation experiences with 3D terrain, voice guidance, and customizable map styles using minimal effort and maximum control. Powered by OpenStreetMap data, it ensures smooth rendering, flexible routing, and seamless offline use. Designed for privacy and performance, Magic Lane products are 100% surveillance-free.
 
The SDK supports Android, iOS and the Web, with plans to provide support for the Linux platform in the future.
___
 
<p>
<a href="https://www.magiclane.com/web">
  <img src="https://img.shields.io/badge/Magic%20Lane-9b78fd" alt="Magic Lane">
</a>
<a href="https://developer.magiclane.com/docs/flutter/guides/introduction/">
    <img src="https://img.shields.io/badge/Read-Documentation-blue?labelColor=000000" alt="Read Docs"/>
</a>
</p>
 
 
## Features
 
### Global Mapping and Visualization

- Global map coverage with up-to-date OpenStreetMap data
- 3D terrain topography for immersive visual experiences
- Customizable map styles: adjust colors, elements, and design to match your app's branding, allowing the creation of street, satellite, terrain and hybrid styles
 
![A demo showcasing navigation between Murren and Kandahar in satellite view with elevation, exploring the breathtaking mountains through map gestures. Recorded in the Magic Earth app.](https://developer.magiclane.com/docs/flutter/img/sdk-preview.gif)
 
### Search and Location Intelligence

- Advanced customizable POI, address search and geocoding on OpenStreetMap POIs and custom landmarks
- Public transport stop schedules with up to date departure info
- Wikipedia integration for landmark descriptions, with rich metadata such as landmark categories, contact info, and extra data
 
![A demo showcasing POIs, traffic and speed cameras in Paris. Recorded in the Magic Earth app.](https://developer.magiclane.com/docs/flutter/img/map-style-pois-preview.gif)
 
### Routing Flexibility

- Customizable multi-stop routing with advanced options (avoid tolls, highways, etc.)
- Route profile with elevation chart and climb details
- Truck, bike (including E-Bike), car and public transport specific route calculation
 
![A long car route between european cities. The route contains toll road segments. The ETA, duration and the number of kilometers are shown. Yellow dots represent zones with high incline. Captured in the Magic Earth app.](https://developer.magiclane.com/docs/flutter/img/route-preview.jpg)
 
### Turn-by-Turn Navigation

- Optimized navigation for car, pedestrian, bicycle, truck with voice guidance in multiple languages
- Lane instructions and signposts for more accurate driving assistance
- GPX support: import, display, and navigate
 
![Navigation in Paris with ETA, trip duration, and distance clearly displayed. Lane guidance is shown along with an upcoming speed camera. Traffic is color-coded on the map, and other events are visible. The route profile is also displayed. Recorded using the Magic Earth app.](https://developer.magiclane.com/docs/flutter/img/navigation-preview.gif)
 
### Real-Time Traffic and Incident Information

- Live traffic data integration for dynamic route adjustments
- Road incident detection and alerts, including police, speed cameras, potholes and other events
- Social reporting and event voting (crowdsourced traffic events) and multiple types of alarms including geofencing support
 
![Speed camera report. Captured using the Magic Earth app.](https://developer.magiclane.com/docs/flutter/img/speed-camera-report-preview.jpg)
 
### Offline Capabilities

- Downloadable content for all countries and regions
- Offline routing, navigation, and search on offline maps
- Download and apply offline map styles and voice packs
 
### Sensor and Data Features

- Record sensor data (GPS, accelerometer, gyroscope, compass and more)
- Driver behavior analysis
- Record video, audio and sensor data
 
## Requirements
 
The Magic Lane Maps SDK for Flutter supports the following platforms:
- Android: API level 23 (Android 6.0) or higher
- iOS/iPadOS: Version 14.0 or higher
- Web: a modern browser with WebAssembly and WebGL 2 support (Chrome, Edge, Firefox, Safari)
 
SDK Requirements
- Dart: Minimum version 3.9.0
- Flutter: Minimum version 3.35.1
 
## Integrate the SDK
 
Add the `magiclane_maps_flutter` dependency to the `pubspec.yaml` file, under `dependencies`.
 
### Android

#### Add maven dependency

In the `android/build.gradle.kts` file, add the following maven block as shown below:
```kts
allprojects {
    repositories {
        google()
        mavenCentral()
        // Add the following three lines
        maven {
            url = uri("https://developer.magiclane.com/packages/android")
        }
    }
}
```
 
### iOS
 
Set the minimum iOS version of the project to 14.0 from XCode.
 
### Web
 
No extra configuration is required. The web engine (WebAssembly payload) is fetched from the Magic Lane servers at runtime, so nothing needs to be bundled with your app. Run your app on the web with:
```sh
flutter run -d chrome
```
 
Please checkout the [Integrate the SDK documentation](https://developer.magiclane.com/docs/flutter/guides/get-started/integrate-sdk) for more details and troubleshooting instructions. Depending on your use case, platform-specific intents and permissions may be required in the `AndroidManifest.xml` and `Info.plist` files.

## Get a SDK API key
 
To use the Magic Lane Maps SDK for Flutter, an API key is required. You can create one by creating a new project on the [Magic Lane Developer Portal](https://developer.magiclane.com/api/projects). The SDK is available for trial use with a generous number of free operations, allowing you to explore its features at no cost. No credit card required for trial.
 
The `token` can be passed to the `GemMap` widget or to the `GemKit.initialize` method.
 
## Quick start
 
### Show the map
 
Building a fully interactive, high-performance map in Flutter with the Magic Lane Maps SDK is quick and straightforward.
The example below demonstrates how to display a customizable map. Add the following to your `main.dart`:
 
```dart
import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
 
const projectApiToken = String.fromEnvironment('PASTE_YOUR_API_TOKEN_HERE');
 
void main() async {
  runApp(
    MaterialApp(
      home: GemMap(
        appAuthorization: projectApiToken,
        onMapCreated: (GemMapController controller) {
          // The controller can be used to interact with the map
        },
      ),
    ),
  );
}
```

Paste your API token between the quotes in the `projectApiToken` variable. The API token can also be passed at build time using `--dart-define`.
 
With the `GemMapController`, you can easily:
- Center the map on specific coordinates, landmarks, overlay items, paths or routes with smooth animations
- Switch between predefined or custom map styles to match your app’s design
- Add interactive markers, custom landmarks, and route overlays
- Listen for user events like taps, drags, and gestures on map elements
- Follow the user’s real-time location for GPS navigation apps
 
For information regarding all the map operations and more, please checkout the [Maps documentation](https://developer.magiclane.com/docs/flutter/guides/maps/get-started).
 
 
### Display markers
 
Markers are highly customizable elements that can be displayed on a map. Create a marker, add it to a collection and display the collection on the map:
 
```dart
Marker marker = Marker()
    ..name = 'My Custom Marker'
    ..setCoordinates([Coordinates(latitude: 50.11, longitude: 8.68)]);
 
MarkerCollection markers = MarkerCollection(
    markerType: MarkerType.point,
    name: 'My Markers',
);
markers.add(marker);
 
mapController.preferences.markers.add(markers);
```
 
Extensive customization options are available for markers via the `MarkerRenderSettings` and `MarkerCollectionRenderSettings`classes. Options for import from formats such as GeoJSON are also available. Check the [Markers documentation](https://developer.magiclane.com/docs/flutter/guides/core/markers) and the [Display Markers documentation](https://developer.magiclane.com/docs/flutter/guides/maps/display-map-items/display-markers) for more details.
 
### Show user location
 
In order to show the current user location, the required permissions need to be requested.
 
Add to the `android/app/main/AndroidManifest.xml` file, within the `manifest` block:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```
 
And to the `ios/Runner/Info.plist` file, within the `<dict>` block:
 
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is needed for map localization and navigation</string>
```
 
Update your `ios/Podfile` to include the following configuration, which ensures the correct build settings for location permissions:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
 
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
         'PERMISSION_LOCATION=1',
      ]
    end
  end
end
```
 
We will use the [`permission_handler`](https://pub.dev/packages/permission_handler) package to manage permissions. This needs to be added to the project.
 
The following snippet requests the location permission, initializes the live location data source and starts the follow position mode.
```dart
final locationPermissionStatus = await Permission.locationWhenInUse.request();
 
if (locationPermissionStatus == PermissionStatus.granted) {
    PositionService.instance.setLiveDataSource();
    mapController.startFollowingPosition();
}
```
 
The `PositionService` class enables advanced functionality, including real-time GPS tracking and precise geolocation. By leveraging map-matching techniques, it delivers enhanced position accuracy.
 
User privacy is strictly protected: Magic Lane does not store any GPS location data.
 
### Search for POIs
 
Searching for POIs from the map based on coordinates and a geographic position can be done in the following way:
 
```dart
SearchService.search(
  'Paris',
  Coordinates(longitude: 46.78, latitude: 2.10),
  (GemError error, List<Landmark> result) {
    if (error != GemError.success) {
      // The search operation failed
    } else {
      // Do something with the resulting landmarks
    }
  },
);
```
 
Search functionality can be tailored using the optional `SearchPreferences` object. Users can search on custom landmarks (created manually or imported from GeoJSON or KML files), map overlay items such as traffic reports, or apply filters like searching only on downloaded maps, specific categories, maximum distance to the query coordinates, and more.
 
Multiple types of search are available:
- Guided Address Search – Navigate a hierarchical structure of countries, cities, regions, postal codes, and streets for precise results
- Search Along Route – Find locations, points of interest, or amenities along a planned route
- Search Within Area – Look for landmarks or locations inside a specified geographic area
- Search Around Position – Explore nearby locations, services, or points of interest around your current or selected positions
 
The search module supports geocoding and reverse geocoding features.
 
More details and usecases are available in the [Search documentation](https://developer.magiclane.com/docs/flutter/guides/search/get-started-search).
 
### Calculate route
 
Plan advanced multi-stop routes with precision between 2 or more waypoints, whether they come from real-time location search, interactive map selection, or custom GPS coordinates.
The Magic Lane Maps SDK for Flutter delivers offline-capable route calculation that adapts to your transport mode and constraints, from cars and truck, bikes, and pedestrians.
 
```dart
Landmark start = Landmark()
  ..name = 'Start waypoint'
  ..coordinates = Coordinates(latitude: 48.85, longitude: 2.32);

Landmark destination = Landmark()
  ..name = 'End waypoint'
  ..coordinates = Coordinates(latitude: 50.83, longitude: 4.35);

RoutePreferences routePreferences = RoutePreferences(
  transportMode: RouteTransportMode.car,
  routeType: RouteType.fastest,
  carProfile: CarProfile(
    mass: 1200,
    fuel: FuelType.diesel,
    maxSpeed: 120,
  ),
);

RoutingService.calculateRoute(
  [start, destination],
  routePreferences,
  (GemError error, List<Route> routes) {
    if (error != GemError.success) {
      // The route calculation operation failed
    } else {
      // Do something with the calculated routes
    }
  },
);
```
 
The `RoutePreferences` object lets you customize and optimize every journey with precision, adapting to real-time traffic, road restrictions, and specific vehicle profiles. Fine-tune routes with advanced options such as:
- Intelligent truck routing – account for vehicle height, length, width, mass, and axle load to avoid restricted roads and ensure safe passage.
- Bicycle & e-bike navigation – enable hill avoidance, leverage electric bike optimizations, and adapt to cycling infrastructure.
- Road type avoidance – skip toll roads, motorways, ferries, or unpaved roads
- Traffic-aware routing – avoid congestion with live traffic updates for faster arrival times.
- Emergency vehicle mode – unlock priority routes, restricted access roads, and instant recalculation for rapid response scenarios.
 
Whether you need scenic drives, eco-friendly navigation, or precise last-mile delivery routes, you have the accuracy with the flexibility of a fully customizable routing engine—and works both online and offline for maximum reliability.
 
More details are available in the [Routing documentation](https://developer.magiclane.com/docs/flutter/guides/routing/get-started-routing).
 
### Navigate on route
 
Start a turn-by-turn navigation with real-time guidance, voice instructions, and dynamic rerouting using the `NavigationService` class. Provide the route calculated earlier and a list of callbacks for getting notified about events.
 
```dart
// Activate automatic sound playing for TTS navigation instructions.
SoundPlayingService.canPlaySounds = true;

NavigationService.startNavigation(
  // Use the route provided by the calculateRoute method
  route,
  onDestinationReached: (landmark) {
    print('Reached destination: ${landmark.name}');
  },
  onNavigationInstruction: (instruction, events) {
    Uint8List? turnImage = instruction.nextTurnDetails?.abstractGeometryImg.getRenderableImageBytes();
    String nextTurnInstruction = instruction.nextTurnInstruction;
    int metersUntillDestination = instruction.remainingTravelTimeDistance.totalDistanceM;
    int secondsUntilDestination = instruction.remainingTravelTimeDistance.totalTimeS;
  },
);
```

Key features include:
- Text-to-Speech (TTS) voice guidance – both flexible computer voices and natural-sounding spoken directions in multiple languages
- Real-time turn visuals – display upcoming maneuvers with high-quality icons, signs and lane guidance
- Live traffic adaptation – detect better routes and recalculate with zero effort
- Smart rerouting – handle roadblocks, missed turns, or route changes without losing navigation flow
- Precise ETA & distance tracking – monitor remaining travel time and distance in real time
- Offline-first design – navigate seamlessly even without an internet connection
 
More details are available in the [Navigation documentation](https://developer.magiclane.com/docs/flutter/guides/navigation/get-started-navigation).
 
### Download offline maps

Retrieve a list of available maps for download, where each item corresponds to a specific region or country.
Once downloaded, all core features such as search, routing, and turn-by-turn navigation—are fully available offline, ensuring reliability even without an internet connection, no other configuration required. You can obtain the list of downloadable map items using the `asyncGetStoreContentList` method:

```dart
ContentStore.asyncGetStoreContentList(
  ContentType.roadMap,
  (error, items, isListCached) {
    if (error != GemError.success || items.isEmpty) {
      // The request was not successful
    } else {
      // Do something with the items
    }
  },
);
```

Each `ContentStoreItem` includes detailed metadata such as name, ID, country code, version, size, and more.

To download a specific region, use the `asyncDownload` method:

```dart
item.asyncDownload(
  (error) {
    if (error == GemError.success) {
      // The download was successful
    } else {
      // The download was not successful
    }
  },
);
```

The Content Store provides complete control over managing downloadable map data and additional resources. It allows developers to:
- Browse and filter content – retrieve the full store list or search by country codes or geographic areas
- Download and update maps – check for updates and manage versions
- Access local content – list installed maps and extras directly on the device
- Manage content lifecycle – refresh, cancel, pause, or resume downloads as needed

## Developer Resources & Support
 
Leverage our comprehensive [documentation](https://developer.magiclane.com/docs/flutter/guides/introduction/) to implement even the most challenging features with ease.
Access over [70 fully-documented examples](https://developer.magiclane.com/docs/flutter/examples/get-started-with-sample-apps/) covering the most popular use cases, each accompanied by clear explanations to accelerate your development process.
 
For tailored solutions or implementation support [contact our team](https://www.magiclane.com/web/contact).

SDKs are also available for iOS, Android, C++, and Qt, with REST APIs offered for selected services.
___
Demos are sourced from the [Magic Earth](https://play.google.com/store/apps/details?id=com.generalmagic.magicearth) app. All map features from showcased demos are powered by the Magic Lane Maps SDK for Flutter. Showcased widgets are not included in the SDK. Traffic conditions, reports, and satellite imagery may vary by region.
