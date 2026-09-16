# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Please check the [Migration Guide](https://developer.magiclane.com/docs/flutter/guides/migration-guide/) for complete steps required for upgrading to a new version.

> <svg class="svg-inline--fa fa-info-circle fa-w-16" style="width: 1em; vertical-align: -.125em; padding-right: .225em;" aria-hidden="true" focusable="false" data-prefix="fas" data-icon="info-circle" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" data-fa-i2svg=""><path fill="currentColor" d="M256 8C119.043 8 8 119.083 8 256c0 136.997 111.043 248 248 248s248-111.003 248-248C504 119.083 392.957 8 256 8zm0 110c23.196 0 42 18.804 42 42s-18.804 42-42 42-42-18.804-42-42 18.804-42 42-42zm56 254c0 6.627-5.373 12-12 12h-88c-6.627 0-12-5.373-12-12v-24c0-6.627 5.373-12 12-12h12v-64h-12c-6.627 0-12-5.373-12-12v-24c0-6.627 5.373-12 12-12h64c6.627 0 12 5.373 12 12v100h12c6.627 0 12 5.373 12 12v24z"></path></svg> **New map structure available !**
>
> Please update all applications to version 2.19.0 or later to access the newest map available. To support recent enhancements, a change in the map format was required.
>
> Legacy map formats will remain available until April 2027. However, the `registerOnWorldwideRoadMapSupportDisabled` callback will be triggered when using an older SDK.

> <svg class="svg-inline--fa fa-info-circle fa-w-16" style="width: 1em; vertical-align: -.125em; padding-right: .225em;" aria-hidden="true" focusable="false" data-prefix="fas" data-icon="info-circle" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" data-fa-i2svg=""><path fill="currentColor" d="M256 8C119.043 8 8 119.083 8 256c0 136.997 111.043 248 248 248s248-111.003 248-248C504 119.083 392.957 8 256 8zm0 110c23.196 0 42 18.804 42 42s-18.804 42-42 42-42-18.804-42-42 18.804-42 42-42zm56 254c0 6.627-5.373 12-12 12h-88c-6.627 0-12-5.373-12-12v-24c0-6.627 5.373-12 12-12h12v-64h-12c-6.627 0-12-5.373-12-12v-24c0-6.627 5.373-12 12-12h64c6.627 0 12 5.373 12 12v100h12c6.627 0 12 5.373 12 12v24z"></path></svg> **Breaking Change !**
>
> Due to improvements of our SDK and map data, we kindly ask you to update your applications and projects with any SDK revision released starting with October 2024 in order to continue using the online Magic Lane map-related services and to continue receiving map updates.

## [3.1.11] - 2026-07-20

### Fixed

- Restored the bundled `navarrow.glb` asset

## [3.1.10] - 2026-07-16

### Added

- Web platform support
- `PTAlertCause`, `PTAlertEffect`, `PTAlertSeverityLevel`, `PTOccupancyStatus`, `PTCongestionLevel` enums
- `PTAlertInfo`, `PTAlertTranslation`, `PTAlertActivePeriod`, `PTCrowdingInfo` classes for live public transit service alerts and vehicle crowding
- `alerts`, `vehicle` and `departureOccupancyStatus` properties to the `PTTrip` class
- `liveCrowding` property to the `PTRouteInfo` class
- `alerts` property to the `PTStop` and `PTStopInfo` classes

### Changed

- `getOnlineServiceRestrictions` of the `TrafficService` class now returns a `Set<TrafficOnlineRestrictions>` with all active restrictions instead of a single `TrafficOnlineRestrictions` value
- the Android plugin now builds using AGP's built-in Kotlin support

### Fixed

- `ContentStore`, `NavigationService` and `SearchService` requests that take a `TilesGeographicArea` now send the proper geographic area instead of a bounding box, resolving degraded and incorrect results
- `RoadInfoImg` now keeps a stable uid across navigation instruction updates
- marker cluster rendering and grouping issues
- DNS resolution network issues
- improved camera behavior
- weather icons are now correct, fixed uid colision
- crash that could occur when a new position was emitted after the canvas was no longer valid

## [3.1.9] - 2026-06-10

### Added

- `RouteRestrictionType`, `RouteUpdateRate`, `WatermarkPosition`, `NavigationInstructionDifferenceResult` enums
- `BatchResult`, `RestrictionSection`, `NavigationInstructionUpdateInfo`, `EVCarModel` classes
- `restrictionSections` property to the `RouteBase` and `RouteSegmentBase` classes
- `restrictions` property to the `TurnDetails` class
- `currentRestrictions` property to the `NavigationInstruction` class
- `maxSpeedMps` property to the `LogMetrics` and `RecordMetrics` classes
- `getEVCarModels` method to the `RoutingService` class
- `getCategoryByName` method to the `LandmarkStore` class
- `categoriesMetadata` property to the `GenericCategories` class
- `setBatch`, `getBatch` methods to the `SettingsService` class
- `copy` method to the `RoutePreferences` class
- `navigationRouteUpdateRate` property to the `MapViewExtensions` class
- `setWatermarkLogoProperties` method to the `GemMapController` and `GemView` classes, and `watermarkLogoVisibility` property to the `GemView` class
- `getPathIndexByName` method to the `MapViewPathCollection` class
- `initialMapStyleId` parameter to the `GemMap` widget, to apply a ContentStore style before the first frame

### Removed

- `getRoadInfoImg` method from the `NavigationInstruction` class. Use the `getRoadInfoImgByType` method instead

### Changed

- added `shadow` value to the `HighlightOptions` and `RouteRenderOptions` enums
- added `restrictionsUpdated` value to the `NavigationInstructionUpdateEvents` enum
- the `startNavigation` and `startSimulation` methods of the `NavigationService` class now expose optional `onNavigationInstructionOptimized` and `onRestrictionsUpdated` callbacks
- iOS uses metal rendering

### Fixed

- events emitted before the SDK finished initializing are now queued and delivered once the engine is ready, resolving related startup crashes
- orientation sensor not working on some Android devices because an incorrect context was passed at SDK initialization
- `removeListener` for position listeners now correctly stops further callbacks
- the map view no longer rebuilds when unrelated widget properties change
- use-after-free crashes and memory leaks involving image pointers
- listeners now release their registered callbacks on dispose, preventing stale callbacks and leaks after the owning `GemMapController` is disposed
- double dispose of internal auto-release objects
- stability improvements on Android and iOS

## [3.1.8] - 2026-03-16

### Added

- `RoadInfoType` enum
- `getRoadInfoImgByType` method to the `NavigationInstruction` class

### Removed

- `getRoadInfoImg` method from the `NavigationInstruction` class as it was deprecated. Use the `getRoadInfoImgByType` method instead.

### Fixed

- `aVar` parameter from `GemKit` class issue on iOS devices
- crashes related to some specific scenarios

## [3.1.7] - 2026-02-27

### Added

- `Gate`, `GateDecision` enums
- `GateStatus`, `GateKeeperService` classes
- `setTiltAngle`, `setMapAngle` methods to the `MapViewPreferences` class (for API consistency)
- `viewAngle` setter to the `MapViewPreferences` class (for API consistency)
- `GemList` and derived classes now support all `Iterable` methods (skip, skipWhile, take, takeWhile)

### Removed

- `registerOnMobileCountryCodeChanged`, `registerOnConnectionFailed`, `registerOnConnectFinished` methods from the `NetworkProvider` class. Use the `OffBoardListener` class methods instead.
- `ProxyDetails` class and `ProxyType` enum as the `NetworkProvider` class has been simplified

### Changed

- the `capabilitties` getter of the `SdkSettings` class has been deprecated and replaced with `capabilities`
- added activation value to `SdkCapability` enum
- the `log` method from the `Debug` class now supports strings containing format specifiers like substrings
- the `isMinifyEnabled` and `isShrinkResources` flags set to false in the Android config files are no longer necessary
- the `appAuthorization` method of the `SdkSettings` class no longer sets the token if it is invalid
- the `ActivationService` class is no longer available in public SDK releases with auto activation enabled. Calls to methods from this class will set the `ApiErrorService` error level to `GemError.missingCapability`
- audio recording requires additional permissions on newer releases.

### Fixed

- `PositionService` methods now properly handle null values for the return type, without runtime assertion errors
- crashes related to network events on Android devices, especially when Android Auto is involved
- triggering the `onDetachedFromActivityForConfigChanges` event no longer crashes the app on Android devices
- route ranges and other substructures of the `RoutePreferences` class are now properly returned by the corresponding getters.
- `add`, `size` and other such members from the `MapViewRouteCollections` class no longer crash after the related `GemMapController` is disposed
- rendering related crash invloving contour lines

## [3.1.6] - 2026-02-05

### Added

- `searchAddress` method to the `SearchService` class
- `deviation` property to the `OverlayItemPosition` and `LandmarkPosition` classes
- `getStringList`, `getIntList`, `setStringList`, `getBoolList`, `setIntList`, `getDoubleList`, `setDoubleList`, `setLargeIntList`, `getLargeIntList`, `setBoolList` methods to the `SettingsService` class
- `getClosestAddressLandmark` method to the `GemView` and `GemMapController` classes
- `isFollowingPositionTouchHandlerModified`, `isDefaultFollowingPosition` properties to the `GemView` class

### Removed

- `RoutingAlgoModifiers` enum, the `getRoutingAlgoModifiers`, `setRoutingAlgoModifiers` methods and `routingAlgoModifiers` getter from the `Debug` class as they are not relevant for the public API anymore

### Changed

- `isFollowingPositionTouchHandlerModified` and `isDefaultFollowingPosition` methods from the `GemMapController` and `GemView` and now getters with the same name
- added an optional named `dataSavePolicy` parameter to the `update` method from the `ContentUpdater` class
- return type of the `getRoadInfoImg` method from the `NavigationInstruction` class changed from `Img` to `RoadInfoImg`
- return type of the `getSocialReportsCategory` method from the `SocialReportsOverlayInfo` class changed from `OverlayCategory?` to `SocialReportsOverlayCategory?`
- the `BLUETOOTH`, `BLUETOOTH_CONNECT`, `READ_PHONE_STATE`, `MODIFY_AUDIO_SETTINGS` are no longer provided by default in the manifest.
- the behavior of the `startFollowingPosition` method from the `GemMapController` class has suffered minor changes regarding the animation and angles on certain scenarios

### Fixed

- `getRoadInfoImg` method of the `RouteInstructionBase` class resizes the image width when the provided initial size is too small
- `asyncDownload` method of the `ContentStoreItem` class does not call the provided `onComplete` callback on immediate failure
- `setPerspective` method of the `FollowPositionPreferences` class works when animation is provided
- callback provided to `registerOnTouchHandlerModifyFollowPosition` never gets called
- `backgroundColor` argument provided to `getRenderableImage` method of the `RoadInfoImg` class is now taken into account
- all fields passed to the `MarkerRenderSettings` are correctly taken into account
- optimizations to `GemImprovedPosition`
- stability improvements on Android

## [3.1.5] - 2026-01-19

### Fixed

- Issue regarding automatic activation on Android devices

## [3.1.4] - 2026-01-15

### Added

- `ActivationInfo`, `DurationID`, `ProductID`, `ActivationService` classes and `ActivationStatus` enum
- `registerOnWorldwideRoadMapRefreshed` methods to the `OffBoardListener` class
- `immutableRoadblockAvoidance`, `accurateWaypointsApproach`, `avoidGeofenceAreas`, `roundTripRange`, `defaultEBikeProfile`, `roundTripRangeType`, `buildConnectionsMaxLength`, `roundTripRandomSeed`, `fitnessFactor`, `avoidGeofenceAntiAreas` properties to the `RoutePreferences` class
- `createInFolder`static  method to the `RouteBookmarks` class

### Removed

- `setCoordinates` methods from the `MarkerInfo` class
- `create` methods from the `ParameterList` and `SearchableParameterList` classes. Use the default constructor instead
- `notifyOnNewImprovedPosition`, `notifyOnNewPosition` methods from the `GemPositionListener` class
- `routeResultType` setter from the `RoutePreferences` class
- `roundTripParameters` getter from the `RoutePreferences` class
- `setClippingArea` method from the `GemMapController` class is deprecated.
- `roadname`, `shieldType` setters and constructor from the `RoadInfo` class.
- many methods such as `on...` methods for event handling, `fromJson` and `toJson`, `create` are now internal and not accessible from the public API

### Changed

- In `MarkerMatch`, the `getMarker` method was replaced with the `marker` property (old method deprecated).  
- In `MarkerInfo`, the `getCoords` method was replaced with the `coords` property (old method deprecated).  
- In `ContentStore`, the `getStoreFilteredList` method was replaced with the `storeFilteredList` property (old method deprecated).  
- In `LandmarkStore`, the `getFilePath` method was replaced with the `filePath` property (old method deprecated).  
- In `MapDetails`, the `getMapProviderIds`, `getCountryDataCount`, and `getMapReleaseInfo` methods were replaced with the `mapProviderIds`, `countryDataCount`, and `mapReleaseInfo` properties respectively (old methods deprecated).  
- In `MapDownloaderService`, the `getMaxSquareKm` and `setMaxSquareKm` methods were replaced with the `maxSquareKm` property (old methods deprecated).  
- In `SdkSettings`, the `getVoice` method was replaced with the `voice` property (old method deprecated).  
- In `DriverBehaviour`, the `getOngoingAnalysis`, `getAllDriverBehaviourAnalyses`, `getInstantaneousScores`, and `getLastAnalysis` methods were replaced with the `ongoingAnalysis`, `allDriverBehaviourAnalyses`, `instantaneousScores`, and `lastAnalysis` properties respectively (old methods deprecated).  
- In `MappedDrivingEvent`, the `getTimestamp` and `getCoordinates` methods were replaced with the `timestamp` and `coordinates` properties respectively (old methods deprecated).  
- In `Path`, the `getLandmarkList` method was replaced with the `landmarkList` property (old method deprecated).  
- In `TimezoneService`, the `getTimezoneInfoTimezoneIdSync` method was replaced with the `getTimezoneInfoFromTimezoneIdSync` method (renamed API entry; old method deprecated).  
- In `Debug`, the legacy debug getters were consolidated into properties: `getUsedMemory` → `usedMemory`, `getTotalMemory` → `totalMemory`, `getFreeMemory` → `freeMemory`, `getMaxUsedMemory` → `maxUsedMemory`, `getAndroidVersion` → `androidVersion`, `getAppIOInfo` → `appIOInfo`, `getStyleBuilderUrls` → `styleBuilderUrls`, `getRoutingAlgoModifiers` → `routingAlgoModifiers`, `getNavigationModifiers` → `navigationModifiers`, `timeToBetterRouteSec` → `timeToBetterRoute`,  `getServicesIds` → `servicesIds`, `getAllWeatherConditions` → `allWeatherConditions`, `isMainThread` → `mainThread`, `getMapViewMaxZoomRanges` → `mapViewMaxZoomRanges`, `isRawPositionTrackerEnabled` → `rawPositionTrackerEnabled`, `getSdkLogDumpPath` → `sdkLogDumpPath` (all old methods deprecated)
- In `MapSceneObject`, the `getDefPositionTrackerAccuracyCircleColor` method was replaced with the `defPositionTrackerAccuracyCircleColor` property (old method deprecated).
- In `RoutePreferences`, the `getRoundTripRange`, `getRoundTripRangeType`, `getRoundTripRandomSeed` methods were replaced with the `roundTripRange`, `roundTripRangeType`, `roundTripRandomSeed` properties respectively (old methods deprecated).
- `RoutePreferences` class has now been rewritten and additional checks are performed when setting properties. The behaviour may differ in some edge cases.
- the `items` parameter of the `onComplete` callback from the `asyncGetStoreFilteredList` method from the `ContentStore` class changed from `List<ContentStoreItem>?` to `List<ContentStoreItem>`
- the type of the `area` property from the `TilesCollectionGeographicArea` class changed from `RectangleGeographicArea` to `GeographicArea`
- the type of the `area` property from the `centerOnAreaRect` method from the `GemView` class changed from `RectangleGeographicArea` to `GeographicArea`
- the `area` parameter of the `centerOnArea` and `centerOnAreaRect` methods from the `GemMapController` class changed from `RectangleGeographicArea` to `GeographicArea`
- the type of the `locationHint` parameter from the `search` and `searchInArea` methods from the `SearchService` class changed from `RectangleGeographicArea?` to `GeographicArea?`
- return type of the `report`, `confirmReport`, `deleteReport`, `updateReport`, `denyReport`, `addComment` methods from the `SocialOverlay` class changed from `EventHandler?` to `ProgressListener?`
- the type of the parameter from the `cancel` method from the `SocialOverlay` class changed from `EventHandler` to `ProgressListener`
- return type of the `addListener` method from the `Recorder` class changed from `EventHandler?` to `ProgressListener?`
- the parameter of the `removeListener` method from the `Recorder` class changed from `EventHandler` to `ProgressListener`
- the parameters of the `cancelWikiInfo` method from the `ExternalInfoService` class changed from `EventHandler` to `ProgressListener`
- return type of the `requestWikiInfo` method from the `ExternalInfoService` class changed from `EventHandler?` to `ProgressListener?`
- the type of the `persistentRoadblockListener` property from the `TrafficService` class changed from `PersistentRoadblockListener` to `PersistentRoadblockListener?`
- return type of the `setAllowInternetConnection` method from the `SdkSettings` class changed from `void` to `Future<void>`
- the type of the `bikeProfile` property from the `RoutePreferences` class changed from `BikeProfileElectricBikeProfile?` to `BikeProfileElectricBikeProfile`
- the type of the `truckProfile` property from the `RoutePreferences` class changed from `TruckProfile?` to `TruckProfile`
- the type of the `carProfile` property from the `RoutePreferences` class changed from `CarProfile?` to `CarProfile`
- the type of the `roundTripParameters` property from the `RoutePreferences` class changed from `RoundTripParameters?` to `RoundTripParameters`
- the type of the `language` property from the `ContentStoreItem` class changed from `Language` to `Language?`
- the type `callback` parameter of the `registerOnVolumeChangedByKeys` method from the `SoundPlayingListener` class changed to nullable
- return type of the `getCollectionAt` method from the `MapViewMarkerCollections` class changed from `MarkerCollection` to `MarkerCollection?`
- the type of the `onPlayingStatusChanged` parameter of the `registerOnPlayingStatusChanged` method from the `DataSourceListener` class changed to nullable
- the type of the `onProgressChanged` parameter of the `registerOnProgressChanged` method from the `DataSourceListener` class changed to nullable
- the type of the `onNewData` parameter of the `registerOnNewData` method from the `DataSourceListener` class changed to nullable
- the type of the `onDataInterruptionEvent` parameter of the `registerOnDataInterruptionEvent` method from the `DataSourceListener` class changed to nullable
- return type of the `getPreviewExtendedData` method from the `OverlayItem` class changed from `ProgressListener` to `ProgressListener?`
- the `playText` method from the `SoundPlayingService` class is now asynchronous and returns a `Future<void>`
- changed the values of the `ExternalImageQuality` enums to reflect changes regarding the wikipedia image retrieval
- the SDK now performs auto activation when a valid token is set

### Fixed

- Images retrieved sometimes had corrupt data instead of transparent pixels
- `GemMap` constructed with specific parameters now have consistent angle behavior
- `setTrackDataDepartureAndDestination` method from the `Landmark` class now works as expected
- internal network checks no longer override user set value for `setAllowInternetConnection` method from the `SdkSettings` class
- `AddressInfo` optimizations for faster retrieval
- fix occasional crash at app startup on Android devices caused by concurrent operations
- crash on Android x32 when using `RoutePreferences` class
- `getRoadInfoImg` method from the `NavigationInstruction` class now returns the correct image

## [3.1.3] - 2025-11-13

### Added

- `ExternalImageQuality`, `AudioStreamType`, `EVChargingConnector`, `AudioCategory`, `RangeType` enums
- `SoundSessionRequestPreferences`, `SoundPlayingPreferences`, `TtsLocalizationService`, `LocalizationService`, `Metrics`, `LogMark`, `RoundTripParameters`, `LocalizationStringIds` classes
- `clearRouteInstruction` method to the `GemMapController` class
- `applicationVersion` property to the `SdkSettings` class
- `setProgressListener` method and `progressListener` property to the `ContentStoreItem` class
- `clearRouteInstruction` method to the `GemView` class
- `requestWikiImage` methods to the `ExternalInfo` class
- `activeDurationMillis` getter to the `LogMetadata` class
- `getSoundPlayingPreferences`, `setSoundPlayingPreferences` methods and `audioLowLatencyOutputFrameSize`, `nativeOutputSampleRate`, `ttsDefaultLanguage`, `soundSessionRequestPreferences` properties to the `SoundPlayingService` class
- `registerOnInterruptionStarted`, `registerOnInterruptionEnded` methods and `isInterrupted` getter to the `SoundPlayingListener` class
- `roundTripRange`, `roundTripRangeType`, `roundTripRandomSeed`, `roundTripParameters`, `isTrackResume` properties to the `RoutePreferences` class
- `getReportSnapshot` method to the `SocialOverlay` class
- `setTrackDataDepartureAndDestination`, `reverseTrackData` methods and `trackData`, `hasTrackData` properties to the `Landmark` class

### Changed

- `setSdkVersion` method from the `SdkSettings` class was deprecated and replaced with the `setApplicationVersion` method
- `image` getter from `OverlayItem` class was deprecated and replaced with the `getImage` method
- the return type of the `getNavigationRoute` method from the `NavigationService` class changed from `Route` to `Route?`
- the `part` optional parameter from the `update` and `setCoordinates` methods from the `Marker` class has changed type from `int?` to `int`. The default value is now `0` instead of `null`
- the camera now has a back into bounds animation when the `zoomLevel` is outside the allowed bounds
- the `SoundMark` and `TextMark` now implement the newly added `LogMark` interface
- the `LogMetrics` and `RecordMetrics` now implement the newly added `Metrics` interface
- some members were made internal and others were deprecated
- some classes were moved to new files to improve project structure

### Fixed

- `reset` method from the `TilesCollectionGeographicArea` now works as expected
- `update` method from the `RouteBookmarks` class no longer resets the `RoutePreferences` when optional parameter is not passed.
- `createStampUtc` getter from the `SafetyParameters` and `PublicTransportParameters` now has the correct value
- operations on the `SoundPlayingService` now set the correct API error level in `ApiErrorService`
- fix for some crashes on Android x32 regarding image retrieval
- the SDK now receives the correct network type on Android


## [3.1.2] - 2025-10-20

### Added

- `clearRouteInstruction` method to the `MavView` class

### Changed

- `image` getter from the `OverlayItem` class is now deprecated and has been replaced with the `getImage` method

### Fixed

- Issues regarding callbacks in `startNavigation` and `startSimulation` methods from the `NavigationService` class


## [3.1.1] - 2025-10-16

### Added

- `vehicleRegistration` getter in the `RoutePreferences` class

### Fixed

- Distribution via pub.dev now works without errors on iOS
- `mapDetailsQualityLevel` setter from the `MapViewPreferences` no longer crashes on iOS
- Swift Package Manager integration issues


## [3.1.0] - 2025-10-16 [YANKED]

### Note

- Yanked because of Swift Package Manager (SPM) integration issues that make the project fail to build or run on iOS.

### Added

- `polygonArea` property to the `MapViewRenderInfo` class
- `plateNumber` property to classes extending `VehicleRegistration`: `ElectricBikeProfile`, `ElectricBikeProfile`, `MotorVehicleProfile`, `CarProfile`, `TruckProfile`
- `VehicleRegistration` class

### Removed 

- `area` and `areaSecond` members from the `MapViewRenderInfo` class are now deprecated

### Changed

- updated minimum SDK version to `3.9.0` and flutter version to `3.35.0`
- added `scenicRoutingAttributes` and `utf8Strings` values to the `MapExtendedCapability` enum
- the `area` property from the `MapViewRenderInfo` class changed from field to getter
- `VehicleRegistration` is now base class for `ElectricBikeProfile` and `MotorVehicleProfile`

### Fixed

- the `onProgress` callback from the `asyncDownload` method from the `ContentStoreItem` now gets called when it should
- the SDK language now matches the device language by default. The default voice is now a TTS computer voice matching the default SDK language


## [3.0.0] - 2025-10-02 [YANKED]

### Note

- Yanked because of Swift Package Manager (SPM) integration issues that make the project fail to build or run on iOS.

### Added

- `magiclane_maps_flutter.dart` barrel export file
- `TrafficParameters`, `InvalidParameterFormat`, `PublicTransportParameters`, `SocialReportParameters`, `RoadMapParameters`, `SafetyParameters`, `ContentParameters`, `OverlayItemParameters`, `VoiceParameters`, `StyleParameters` classes
- `isScalable` getter to the `ImgBase` class and extending classes (`LaneImg`, `SignpostImg`, `RoadInfoImg`, `AbstractGeometryImg`)
- `size` getter to the `RenderableImg` class
- `remove` method to the `ExtraInfo` class
- `grabOverlayOfflineData`, `cancelGrabOverlayOfflineData`, `enableOverlayOfflineDataGrabber`, `disableOverlayOfflineDataGrabber`, `isOverlayOfflineDataGrabberSupported`, `isOverlayOfflineDataGrabberEnabled` methods to the `OverlayService` class
- `tollSections` getter to the `RouteSegmentBase` class and extending classes
- `tollSections` properties to the `RouteBase` class and extending classes
- `roadInfo` getter to the `GemImprovedPosition` class


### Removed

- `instance` static property from the `PositionService` class
- `registerMoveCallback`, `registerLongPressCallback`, `registerPinchSwipeCallback`, `registerTouchMoveCallback`, `registerRenderMapScaleCallback`, `registerCursorSelectionUpdatedMapSceneObjectCallback`, `registerCursorSelectionUpdatedPathCallback`, `registerTouchCallback`, `registerHoveredMapLabelHighlightedOverlayItemCallback`, `registerViewRenderedCallback`, `registerCursorSelectionUpdatedTrafficEventsCallback`, `registerHoveredMapLabelHighlightedLandmarkCallback`, `registerCursorSelectionUpdatedOverlayItemsCallback`, `registerPinchCallback`, `registerTwoDoubleTouchesCallback`, `registerTwoTouchesCallback`, `registerDoubleTouchCallback`, `registerViewportResizedCallback`, `registerMapViewMoveStateChangedCallback`, `registerCursorSelectionUpdatedRoutesCallback`, `registerTouchPinchCallback`, `registerSwipeCallback`, `registerFollowPositionStateCallback`, `registerTouchHandlerModifyFollowPositionCallback`, `registerShoveCallback`, `registerCursorSelectionUpdatedMarkersCallback`, `registerMapAngleUpdateCallback`, `registerSetMapStyleCallback`, `registerHoveredMapLabelHighlightedTrafficEventCallback`, `registerCursorSelectionUpdatedLandmarksCallback` methods from the `GemMapController` class as they were deprecated and replaced with the `registerOnTouchHandlerModifyFollowPosition`, `registerOnMove`, `registerOnLongPress`, `registerOnTwoDoubleTouches`, `registerOnSwipe`, `registerOnMapAngleUpdate`, `registerOnViewRendered`, `registerOnTouch`, `registerOnTwoTouches`, `registerOnPinchSwipe`, `registerOnShove`, `registerOnFollowPositionState`, `registerOnCursorSelectionUpdatedLandmarks`, `registerOnCursorSelectionUpdatedMapSceneObject`, `registerOnCursorSelectionUpdatedRoutes`, `registerOnCursorSelectionUpdatedMarkers`, `registerOnHoveredMapLabelHighlightedOverlayItem`, `registerOnDoubleTouch`, `registerOnCursorSelectionUpdatedTrafficEvents`, `registerOnHoveredMapLabelHighlightedLandmark`, `registerOnRenderMapScale`, `registerOnMapViewMoveStateChanged`, `registerOnTouchMove`, `registerOnTouchPinch`, `registerOnCursorSelectionUpdatedOverlayItems`, `registerOnViewportResized`, `registerOnCursorSelectionUpdatedPath`, `registerOnHoveredMapLabelHighlightedTrafficEvent`, `registerOnSetMapStyle`, `registerOnPinch` methods
- `registerOnProgressCallback` and `registerOnCompleteWithDataCallback` methods from the `ProgressListener` class were deprecated and replaced with the `registerOnProgress`, `registerOnCompleteWithData` methods
- `EVRoute`, `EVRouteSegment`, `EVRouteInstruction`, `EVProfile` classes, `toEVRoute` method from the `Route` class, `toEVRouteSegment` method from the `RouteSegment` class, `toEVRouteInstruction` method from the `RouteInstruction` class, `evProfile` property from the `RoutePreferences` class
- `getPreferences` method from `DataSource` class


### Changed

- the package name has been renamed from `gem_kit` to `magiclane_maps_flutter`. The main distribution method is now pub.dev
- the `MapStatus` enum renamed to `ContentStoreStatus`. The `status` parameter from the `registerOnAvailableContentUpdate` and `registerOnWorldwideRoadMapSupportStatus` method from the `OffBoardListener` class
- all previous instance methods and properties from `PositionService` are now static methods
- the `previewData` getter has been renamed to `previewDataParameterList` in the `OverlayItem` class. A new `previewData` property from the `OverlayItem` class changed from `SearchableParameterList` to `OverlayItemParameters?`
- added `allowResize` named optional parameter to the `getRoadInfoImage` method from the `RouteInstruction`, `RouteInstructionBase`, `EVRouteInstruction`, `PTRouteInstruction` classes
- added `allowResize` named optional parameter to the `getLaneImage` method from the `NavigationInstruction` class
- added `allowResize` named optional parameter to the `getImage` method from the `SignpostDetails` class
- added `dataSource` named optional parameter to the `prepareReporting` method from the `SocialOverlay` class
- the `data` parameter of the `onResult` callback from the `getPreviewData` method from the `RouteTrafficEvent` and `TrafficEvent` classes changed type from `SearchableParameterList?` to `TrafficParameters?`
- the `data` parameter of the `onResult` callback from the `getPreviewData` method from the `RouteTrafficEvent` class changed type from `SearchableParameterList?` to `TrafficParameters?`
- the type of the `contentParameters` property from the `ContentStoreItem` class changed from `SearchableParameterList` to `ContentParameters?`
- the `onProgressCallback` optional parameter of the `asyncDownload` method from the `ContentStoreItem` class was removed as it was deprecated and replaced with `onProgress` callback
- the `items` and `isCached` parameters of the `onComplete` callback from the `asyncGetStoreContentList` method from the `ContentStore` class are no longer nullable. When operation finishes with error the `items` is empty list and `isCached` is false.

### Fixed

- App freezing when the SDK is released and dangling `DataSource` are kept alive by `RecorderConfiguration` instances
- `centerOnRoutePart` method from the `GemView` class throwing exception
- `addList` method from the `MapViewMarkerCollections` class displaying markers with incorrect aspect ratio icons when the images are in portrait mode
- `nextNextTurnInstruction` and `nextTurnInstruction` from the `NavigationInstruction` class now return capitalized strings if the first letter is a latin character
- `getPTStopInfo` from the `OverlayItem` class no longer crashes and has improved performance
- `clearAllButMainRoute` method from the `MapViewRoutesCollection` class no longer crashes when no routes are present or no render settings are set for the main route

## [2.27.0] - 2025-09-18

### Added

- `viewportCenter` getter to the `GemView` class
- `getCoordinate`, `getCoordinatesCount`, `deleteRange` methods to the `Marker` class
- `polylineType` property to the `MarkerRenderSettings` class
- `getSdkLogDumpPath` method to the `Debug` class
- `hitTest`, `save`, `load` methods to the `MarkerCollection` class and extending `MapViewMarkerCollections` and `MarkerSketches` classes
- `registerOnBrowseSessionInvalidated` method to the `LandmarkStoreListener` class
- `roadInfo` getter to the `GemImprovedPosition` class
- `dispose` method and `pointerId` getter to most classes


### Removed

- `NavigationEventType` enums as they were deprecated and the functionality is already implemented via other callbacks
- `ExternalPositionData` class and the `positionFromExternalData` method from the `SenseDataFactory` as they were deprecated. The `producePosition` method from the `SenseDataFactory` class should be used instead
- `MapViewOverlayCollection`, `MarkerCustomRenderData` classes as they were unused
- `pitchInDegrees`, `headingInDegrees` properties from the `GemView` class as they were deprecated. Other properties exist, providing the same features
- `isEmpty` getter from the `GeographicArea` and extending `TilesCollectionGeographicArea`, `RectangleGeographicArea`, `PolygonGeographicArea` and `CircleGeographicArea` classes. The `isDefault` getter should be used instead
- `timestamp` properties from the `GemPosition` class as it was deprecated. Use the `acquisitionTime` property instead
- `getImprovedPosition`, `getPosition` methods from the `PositionService` class as they were deprecated. Use the existing `improvedPosition` and `position` getters instead
- `setTTSLanguage`, `setAllowConnection` methods from the `SdkSettings` class as they were deprecated. Use the `setTTSVoiceByLanguage` and `setAllowInternetConnection` methods instead
- `horizontalaccuracy`, `verticalaccuracy` properties from the `Coordinates` class as they were deprecated
- `deviceModel` property from the `RecorderConfiguration` class as it was deprecated. Set the value in the `hardwareSpecifications` property instead
- `refreshContentStore` method from the `ContentStore` class as it was deprecated. Use `refresh` instead
- `setActivityRecord` methods from the `Recorder` class as they were deprecated. Use `activityRecord` setter instead
- `setNorthFixedFlag`, `rotationAngle` properties from the `MapViewPreferences` class as they were deprecated. Other properties exist, providing the same features
- `overlays` property from the `MapViewPreferences` class as the returned object had very limited functionality.
- `getWikiPageTitle`, `getWikiImagesCount`, `getWikiPageDescription`, `getWikiPageUrl`, `getWikiPageLanguage` methods from the `ExternalInfo` class as they were deprecated. Use the existing getters instead


### Changed

- Renamed `IGemPositionListener` to `GemPositionListener` and previous `GemPositionListener` to `GemPositionListenerImpl`.  The `addPositionListener` and `addImprovedPositionListener` methods from `PositionService` now return an object whose current class is the new `GemPositionListener`. The `GemPositionListener` method takes as parameter a `GemPositionListener` object instead of `IGemPositionListener`.
- `registerOnProgressCallback` and `registerOnCompleteWithDataCallback` methods from the `ProgressListener` class were deprecated and replaced with the `registerOnProgress`, `registerOnCompleteWithData` methods
`registerTouchHandlerModifyFollowPositionCallback`, `registerMoveCallback`, `registerLongPressCallback`,`registerTwoDoubleTouchesCallback`,`registerSwipeCallback`,`registerMapAngleUpdateCallback`,`registerViewRenderedCallback`,`registerTouchCallback`,`registerTwoTouchesCallback`,`registerPinchSwipeCallback`,`registerShoveCallback`,`registerFollowPositionStateCallback`,`registerCursorSelectionUpdatedLandmarksCallback`,`registerCursorSelectionUpdatedMapSceneObjectCallback`,`registerCursorSelectionUpdatedRoutesCallback`,`registerCursorSelectionUpdatedMarkersCallback`,`registerHoveredMapLabelHighlightedOverlayItemCallback`,`registerDoubleTouchCallback`,`registerCursorSelectionUpdatedTrafficEventsCallback`,`registerHoveredMapLabelHighlightedLandmarkCallback`,`registerRenderMapScaleCallback`,`registerMapViewMoveStateChangedCallback`,`registerTouchMoveCallback`,`registerTouchPinchCallback`,`registerCursorSelectionUpdatedOverlayItemsCallback`,`registerViewportResizedCallback`,`registerCursorSelectionUpdatedPathCallback`,`registerHoveredMapLabelHighlightedTrafficEventCallback`,`registerSetMapStyleCallback`,`registerPinchCallback` methods from the `GemMapController` class were deprecated and replaced with the `registerOnTouchHandlerModifyFollowPosition`, `registerOnMove`, `registerOnLongPress`, `registerOnTwoDoubleTouches`, `registerOnSwipe`, `registerOnMapAngleUpdate`, `registerOnViewRendered`, `registerOnTouch`, `registerOnTwoTouches`, `registerOnPinchSwipe`, `registerOnShove`, `registerOnFollowPositionState`, `registerOnCursorSelectionUpdatedLandmarks`, `registerOnCursorSelectionUpdatedMapSceneObject`, `registerOnCursorSelectionUpdatedRoutes`, `registerOnCursorSelectionUpdatedMarkers`, `registerOnHoveredMapLabelHighlightedOverlayItem`, `registerOnDoubleTouch`, `registerOnCursorSelectionUpdatedTrafficEvents`, `registerOnHoveredMapLabelHighlightedLandmark`, `registerOnRenderMapScale`, `registerOnMapViewMoveStateChanged`, `registerOnTouchMove`, `registerOnTouchPinch`, `registerOnCursorSelectionUpdatedOverlayItems`, `registerOnViewportResized`, `registerOnCursorSelectionUpdatedPath`, `registerOnHoveredMapLabelHighlightedTrafficEvent`, `registerOnSetMapStyle`, `registerOnPinch` methods
- removed `me` value from the `RoutePathAlgorithm` enum as it was deprecated. Use the `ml` value instead
- removed `downloadWaiting` value from the `ContentStoreItemStatus` enum as it was deprecated. Use the other more specialized `waiting...` values instead
- added `geofence`, `overlays`, `values` value to the `ContentStoreItemStatus` enum
- the type of the `nextNextInstruction`, `previousInstruction`, `nextInstruction` properties from the `NavigationInstruction` class changed from `RouteInstruction` to `RouteInstruction?`
- the type of the `json` property from the `MapDisposedException` and `ObjectNotAliveException` classes changed from `String` to `Map<String, dynamic>`
- the parameters `onCompleteCallback` parameter of the `convert` method from the `ProjectionService` class, the `getTimezoneInfoFromTimezoneId` and `getTimezoneInfoFromCoordinates` methods from the `TimezoneService` class, the `getHourlyForecast`, `getCurrent`, `getDailyForecast`, `getForecast` method from the `WeatherService` classes, the `importLandmarksWithDataBuffer` and `importLandmarks` methods from the `LandmarkStore` class, the `asyncGetStoreFilteredList` method from the `ContentStore` class and the `update` method from the `ContentUpdater` class has been removed as it was deprecated. The `onComplete` parameter with the same arguments should be used instead.
- the `onRouteCalculationStarted` and `onRouteCalculationCompleted` callbacks were added to the parameters of the `startSimulation` and `startNavigation` methods from the `NavigationService` class
- the `onNavigationInstructionUpdate` positional callback parameter was removed from the parameters of the `startSimulation` and `startNavigation` methods from the `NavigationService` class as it was deprecated
- the `autoPlaySound` parameter was removed from the parameters of the `startSimulation` and `startNavigation` methods from the `NavigationService` class as it was deprecated. Use the `SoundPlayingService` class to toggle playing TTS instructions at any time instead
- the `index` parameter of the `getCountryFlagImgByIndex` method from the `MapDetails` class is now positional instead on named
- the `RectType<T>` was replaced with `Rectangle` everywhere in the public API: the parameter of the `centerOnRoute`, `getOptimalRoutesCenterViewport`, `getOptimalHighlightCenterViewport`, `transformScreenToWgsRect`, `centerOnRoutePart`, `checkObjectVisibility`, `centerOnAreaRect`, `centerOnRoutes`, `centerOnMapRoutes`, `setClippingArea`, `getVisibleRouteInterval` methods from the `GemView` and `GemMapController` classes, the return type of `getOptimalRoutesCenterViewport` and `getOptimalHighlightCenterViewport` methods from the `GemView` and `GemMapController` classes, the return type of the `viewportF` and `viewport` getters from the `GemView` class, the return type of the `getScreenRect` method from the `MapSceneObject` class, the type of the `focusViewport` property from the `MapViewPreferences` class, the type of the `mapScalePosition` property from the `MapViewPreferences` class, 
- the default value of the `provider` parameter of the `producePosition` method from the `SenseDataFactory` class changed from `Provider.unknown` to `Provider.gps`
- the `angle` parameter of the `setMapRotationMode` method from the `FollowPositionPreferences` class has been removed as it was deprecated. Use the `mapAngle` parameter instead
- `ContentStoreItemStatus` enum numeric values


### Fixed

- the `producePosition` method from the `SenseDataFactory` class now produces positions usable in the engine with minimal configuration, as the provider is now `gps` instead of `unknown`
- the `visibility` property from the `MapSceneObject` class now works as expected
- the `startRecording` method of the `Recorder` class now works even if one of the passed data types is not supported, the recording now records the supported data tyoes
- the last instruction from the list of `RouteInstruction` objects returned from the `instructions` getter of the `RouteSegmentBase` class has a correct `turnInstruction` string
- when the `touchHandlerModifyPersistent` property is set to true, the calls of `startFollowPosition` method use the correct zoom level and no longer zoom in
- the `currentPosition` of the `NavigationInstruction` class now returns the correct value
- the logging no longer logs the token and `log` method calls
- app no longer crashes when trying to call a method that is not existent on native classes, an exception with a suitable message is raised instead
- properties which return `ContentStoreItemStatus` values now provide the correct values.


## [2.26.0] - 2025-09-04

### Added

- `ProxyType`, `SdkEvent` enums
- `MapDisposedException`, `ProxyDetails`, `MarkerSketches` classes
- `registerOnConnectionFailed`, `registerOnConnectFinished`, `registerOnMobileCountryCodeChanged` methods to the `NetworkProvider` class. They only work on Android for now.
- `segment`, `partIndex`, `distance`, `type`, `markerCollection`, `coordinates`, `markerIndex` properties to the `MarkerMatch` class
- `getType` method to the `ISOCodeConversions` class
- `getSketches` method to the `MapViewMarkerCollections` class
- `getIsFollowingPosition` method to the `GemMapController` and `GemView` classes
- `isActive`, `isExpired`, `isAntiArea`, `area` properties to the `TrafficEvent` class
- `isRightToLeft` property to the `Language` class
- `elevationAlphaFactor` property to the `MapViewPreferences` class
- `getDataSource`, `updateNavigationSound` methods to the `NavigationService` class
- `exportAs`, `getRoadInfoImg` methods to the `NavigationInstruction` class
- `currentPosition`, `nextNextInstruction`, `returnToRoutePosition`, `returnToRouteImage`, `nextInstruction`, `navigationRoute`, `previousInstruction` properties to the `NavigationInstruction` class
- `metrics` getter to the `Recorder` class
- `allowReroutingEvent` const static field to the `DSPrefKeysPosition` class
- `allowReroutingEvent` property to the `PositionSensorConfiguration` class
- `ExpiredContent` class
- `registerOnExpiredContent` method to the `OffBoardListener` class

### Removed

- `ActivityType`, `TrafficTransportMode`, `ActivityConfidence` enums as some were related to `Activity` and `TrafficTransportMode` was not used
- `Activity` class as it was unstable and not fully suported
- `imagePointer`, `packedLabelingMode`, `imagePointerSize` properties from the `MarkerRenderSettings` class are now internal
- `produceActivity` method from the `SenseDataFactory` class as the `Activity` was removed
- `create` method from the `TimezoneResult` class is now internal as the instances should be obtained only via conversion operations
- `scroll` method from the `GemMapController` and `GemView` classes as it was not working

### Changed

- `calculateRoute` method from the `RoutingService` now considers passed `RoutePreferences.truckProfile` dimensions and weights even when transportMode is `car`
- `getPlayback` method from the `PositionService` replaced with `playback` getter
- added `free` value to the`TrafficEventSeverity` enum
- added `waitingReturnToRoute` value to the`NavigationStatus` enum
- added `textureView` value to the `AndroidViewMode` enum
- added `groupTopRight` value to the `MarkerLabelingMode` enum
- added `packedGeometry` and `polyline` values to the `PathFileFormat` enum
- removed `activity` value to the `DataType` enum
- return type of the `getCountryData` method from the `MapDetails` class changed from `CountryData` to `CountryData?`
- removed redundant `type` parameter from the `setMockData` method from the `DataSource` class
- the `area` parameter of the `hitTest` method from the `MapViewMarkerCollections` has been removed. The new `coordinates` parameter is now used instead
- added `lmkStoreTypesIds` and `radius` named parameters with default values of the `getNearestLocations` method from the `GemMapController`, `GemMapController` and `GemView` classes
- return type of the `getBestLanguageMatch` method from the `SdkSettings` class changed from `Language` to `Language?`
- replaced the type of the `variant` parameter of the `getBestLanguageMatch` method from the `SdkSettings` from `int` to `ScriptVariant`. The `regionCode`, `scriptCode` and `variant` parameters are now named and have suitable default values.


### Fixed

- `getBestLanguageMatch` method from the `SdkSettings` class changed has been fixed
- `getPersistentRoadblock` method from the `TrafficService` class now also works for path areas
- `startFollowPosition` without parameters had incorrect behaviour when `setTouchHandlerModifyPersistent` is true and a previous `startFollowPosition` call with parameters had been issued.
- calling methods from classes such as `MapViewPreferences`, `MapViewRoutesCollection`, `MapViewPathCollection`, `LandmarkStoreCollection`, `MapViewMarkerCollections`, `FollowPositionPreferences` and `MapViewExtensions` objects now throw exception when the associated `GemMapController` has been destroyed. Previously the app crashed.
- the `asyncDownload` method of the `ContentStoreItem` class and the `asyncGetStoreFilteredList`, `asyncGetStoreContentList` methods from the `ContentStore` class now provide the correct result in case of failure via the `onComplete` callback method


## [2.25.0] - 2025-08-14

### Added

- `MapDownloaderService`, `CountryData` classes
- `stopTrackPositions`, `startTrackPositions` methods and `isTrackedPositions`, `trackedPositions` properties to the `MapViewExtensions` class
- `mapLabelsFading`, `mapLabelsContinuousRendering`, `disableFastLoading`, `isFastBrowsingEnabled` properties to the `MapViewPreferences` class
- `getPointMapCoverage`, `getCountryData` methods and `allCountriesData` property to the `MapDetails` class
- `playback` getter to the `PositionService` class
- `getScreenRect` methods to the `MapSceneObject` class
- `import_custom_landmarks` example for showing how to import and use landmarks.

### Removed

- `create` method from the `AddressInfo` class. The public constructor should be used instead.

### Changed

- the type of the `coordinates` property from the `Projection` class changed from `Coordinates?` to `Coordinates`
- added optional `language` parameter to the `setVoiceByPath` method from the `SdkSettings` class.

### Fixed

- the `overlayInfos` getter of the `OverlayCollection` class now returns usable list of `OverlayInfo` objects. Previously the app crashed when accessing members of these returned `OverlayInfo`.
- a computer voice matching with the default SDK language is now set by default. Previously the language needed to be set manually.
- the `getDepartureTime` and `getArrivalTime` methods of the `PTRouteInstruction` class now return correct values.
- the `asyncGetStoreFilteredList` method of the `ContentStore` class now returns correct values when the provided `countries` parameter is null.
- the `cancelNavigation` method of the `NavigationService` class no longer crashes randomly when called.
- the `setSdkDumpLevel` method from the `Debug` class now works on Android.


## [2.24.0] - 2025-07-31

### Added

- `GemCameraPlayer`, `GemCameraPlayerController`, `GemCameraPlayerValue`, `CameraConfiguration`, `Camera` classes
- `labelIcons` parameter to the `add` method in `MapViewRouteCollection` class
- `ImagePixelFormat`, `GemCameraPlayerStatus`, `SdkCapability` enums
- `capabilitties` getter in `SdkSettings` class
- `mapAngle` properties to the `MapViewPreferences` class
- `produceCamera` method in `SenseDataFactory`
- `getTimezoneInfoFromCoordinatesSync` and `getTimezoneInfoTimezoneIdSync` methods in `Timezone` class
- `isRenderEnabled` getter and setter in `MapView`
- `azimuth` and `reset` methods in `Coordinates` class
- `reset`, `convert` methods and `isDefault` getter in all `GeographicArea` classes
- `setFromBounds` and `setFromCenterAndRadii` methods in `RectangleGeographicArea` class
- `img` setter in `LandmarkCategory`
- `ferry` and `toll` values in `GemIcon` enum
- `labelIcons` optional parameter to `add` method of `MapViewRoutesCollection`
- `Camera feed` example for showing how to use `GemCameraPlayer` to retrieve the live camera feed image


### Removed

- `accurateResult` parameter in `getTimezoneInfoFromCoordinates` and `getTimezoneInfoFromTimezoneId` methods
- `RenderRule` enums
- `render`, `markNeedsRender` methods from the `GemView` class
- `renderingRule` properties from the `GemView` class
- `render`, `markNeedsRender` methods from the `GemMapController` class

### Changed

- `onCompleteCallBack` has been deprecated in all classes. This parameter was replaced with `onComplete` in all classes.
- `DataTypeExtension` id values
- `headingInDegrees` method of `MapView` has been deprecated. This method was replaced with `mapAngle`in `MapView`.
- `pitchInDegrees` method of `MapView` has been deprecated. This method was replaced with `viewAngle` in `MapView`.
- `angle` parameter of `setMapRotationMode` has been deprecated. This parameter was replaced with `mapAngle` in `setMapRotationMode` method in `FollowPositionPreferences` class
- `rotationAngle` getter from `FollowPositionPreferences` has been deprecated. This method was replaced with `mapAngle` in `FollowPositionPreferences` class
- `rotationAngle` setter from `MapViewPreferences` has been deprecated. This method was replaced with `mapAngle` in `MapViewPreferences` class
- `isEmpty` getter from `GeographicArea` classes has been deprecated. This method was replaced with `isDefault` in all `GeographicArea` classes
- return type of the `getWaypoints` method from the `RouteBookmarks` class changed from `List<Landmark>` to `List<Landmark>?`
- return type of the `getName` method from the `RouteBookmarks` class changed from `String` to `String?`
- return type of the `getTimestamp` method from the `RouteBookmarks` class changed from `DateTime` to `DateTime?`


## [2.23.0] - 2025-07-17

### Added

- `AlertSeverity`, `ISOCodeType`, `GemDumpSdkLevel` enums
- `TextMark`, `ISOCodeConversions` classes
- `removeListener`, `addTextMark`, `addListener` methods to the `Recorder` class
- `getLandmarkStoreType` method to the `LandmarkStoreService` class
- `overlaysLandmarkStoreId`, `geofenceLandmarkStoreId`, `mapRoadsLandmarkStoreId` getters to the `LandmarkStoreService` class
- `getIntermediateWaypointDropParameters` method to the `NavigationService` class
- `textMarks` getter to the `LogMetadata` class
- `getLandmark` method to the `LandmarkStore` class
- `setSdkDumpLevel`, `log` methods to the `Debug` class
- `getStoreFilteredList`, `asyncGetStoreFilteredList` methods to the `ContentStore` class

### Removed

- `setTouchHandlerModifyVerticalAngleLimits` methods from the `FollowPositionPreferences` class
- most classes based on the `GemList` are now only for internal use and are no longer exposed in the public API: `GemList`, `GenericIterator`, `LandmarkList`, `LandmarkPositionList`, `OverlayItemList`, `RouteList`, `RouteInstructionList`, `RouteSegmentList`, `OverlayItemPositionList`, `MarkerMatchList`, `MarkerList`, `TrafficEventList`, `RouteTrafficEventList`, `LandmarkCategoryList`, `ContentStoreItemList`, `SignpostItemList`.

### Changed

- added `hike` to the `RecordingTransportMode` enum; 
- removed `none` from the `OnlineRestrictions` enum; 
- the type of the `fromLandmark` property from the `RouteTrafficEvent` class changed from `Pair<Landmark, bool>` to `(Landmark, bool)`
- the type of the `toLandmark` property from the `RouteTrafficEvent` class changed from `Pair<Landmark, bool>` to `(Landmark, bool)`
- return type of the `getOngoingAnalysis` method from the `DriverBehaviour` class changed from `DriverBehaviourAnalysis` to `DriverBehaviourAnalysis?`
- return type of the `getInstantaneousScores` method from the `DriverBehaviour` class changed from `DrivingScores` to `DrivingScores?`
- return type of the `getLastAnalysis` method from the `DriverBehaviour` class changed from `DriverBehaviourAnalysis` to `DriverBehaviourAnalysis?`
- return type of the `stopAnalysis` method from the `DriverBehaviour` class changed from `DriverBehaviourAnalysis` to `DriverBehaviourAnalysis?`
- return type of the `getCombinedAnalysis` method from the `DriverBehaviour` class changed from `DriverBehaviourAnalysis` to `DriverBehaviourAnalysis?`
- added `severity` named parameter to the `playText` method from the `SoundPlayingService` class
- return type of the `toPTRouteInstruction` method from the `RouteInstruction` class changed from `PTRouteInstruction` to `PTRouteInstruction?`
- return type of the `getNavigationInstruction` method from the `NavigationService` class changed from `NavigationInstruction` to `NavigationInstruction?`
- added `onTurnAround` optional parameter to the `startNavigation` and `startSimulation` methods from the `NavigationService` class
- return type of the `getAvailableOverlays` method from the `OverlayService` class changed from `Pair<OverlayCollection, bool>` to `(OverlayCollection, bool)`
- return type of the `getVisibleRouteInterval` method from the `GemView` class changed from `Pair<int, int>` to `(int, int)`
- return type of the `getElevationSamples` method from the `RouteTerrainProfile` class changed from `Pair<List<double>, double>` to `(List<double>, double)`
- return type of the `getElevationSamplesByCount` method from the `RouteTerrainProfile` class changed from `Pair<List<double>, double>` to `(List<double>, double)`
- return type of the `getVisibleRouteInterval` method from the `GemMapController` class changed from `Pair<int, int>` to `(int, int)`
- return type of the `toPTRouteSegment` method from the `RouteSegment` class changed from `PTRouteSegment` to `PTRouteSegment?`
- the type of the `drivingScores` property from the `DriverBehaviourAnalysis` class changed from `DrivingScores` to `DrivingScores?`
- return type of the `getUserMetadata` method from the `LogMetadata` class changed from `Uint8List` to `Uint8List?`
- return type of the `getBuyTicketInformation` method from the `PTRoute` class changed from `PTBuyTicketInformation` to `PTBuyTicketInformation?`
- the parameters of the `getLandmarkCount` method from the `LandmarkStore` class changed (added: {'int categoryId = LandmarkStore.invalidLandmarkCategId'}, removed: {'int categoryId'})
- return type of the `getOnlineServiceRestriction` method from the `SdkSettings` class changed from `OnlineRestrictions` to `Set<OnlineRestrictions>`
- return type of the `addPersistentRoadblockByCoordinates` method from the `TrafficService` class changed from `Pair<TrafficEvent?, GemError>` to `(TrafficEvent?, GemError)`
- return type of the `addAntiPersistentRoadblockByArea` method from the `TrafficService` class changed from `Pair<TrafficEvent?, GemError>` to `(TrafficEvent?, GemError)`
- return type of the `addPersistentRoadblockByArea` method from the `TrafficService` class changed from `Pair<TrafficEvent?, GemError>` to `(TrafficEvent?, GemError)`
- return type of the `getUrlTranslation` method from the `PTAlert` class changed from `PTTranslation` to `PTTranslation?`
- return type of the `getDescriptionTextTranslation` method from the `PTAlert` class changed from `PTTranslation` to `PTTranslation?`
- return type of the `getHeaderTextTranslation` method from the `PTAlert` class changed from `PTTranslation` to `PTTranslation?`
- return type of the `generatePositionAndOrientationTargetCentered` method from the `MapCamera` class changed from `Pair<GemError, PositionOrientation>` to `(GemError, PositionOrientation)`
- return type of the `generatePositionAndOrientationHPR` method from the `MapCamera` class changed from `Pair<GemError, PositionOrientation>` to `(GemError, PositionOrientation)`
- return type of the `generatePositionAndOrientationRelativeToCenteredTarget` method from the `MapCamera` class changed from `Pair<GemError, PositionOrientation>` to `(GemError, PositionOrientation)`
- return type of the `generatePositionAndOrientation` method from the `MapCamera` class changed from `Pair<GemError, PositionOrientation>` to `(GemError, PositionOrientation)`
- return type of the `generatePositionAndOrientationRelativeToTarget` method from the `MapCamera` class changed from `Pair<GemError, PositionOrientation>` to `(GemError, PositionOrientation)`
- the type of the `touchHandlerModifyVerticalAngleLimits` property from the `FollowPositionPreferences` class changed from `Pair<double, double>` to `(double, double)`
- the `touchHandlerModifyVerticalAngleLimits` property from the `FollowPositionPreferences` class changed from getter to getter/setter pair
- the type of the `touchHandlerModifyHorizontalAngleLimits` property from the `FollowPositionPreferences` class changed from `Pair<double, double>` to `(double, double)`
- the type of the `touchHandlerModifyDistanceLimits` property from the `FollowPositionPreferences` class changed from `Pair<double, double>` to `(double, double)`
- the type of the `mapRotationMode` property from the `FollowPositionPreferences` class changed from `Pair<FollowPositionMapRotationMode, double>` to `(FollowPositionMapRotationMode, double)`
- the type of the `track` property from the `OTRoute` class changed from `Path` to `Path?`
- return type of the `getPreferences` method from the `RouteBookmarks` class changed from `RoutePreferences` to `RoutePreferences?`
- the type of the `nextTurnDetails` property from the `NavigationInstruction` class changed from `TurnDetails` to `TurnDetails?`
- the type of the `signpostDetails` property from the `NavigationInstruction` class changed from `SignpostDetails` to `SignpostDetails?`
- the type of the `nextNextTurnDetails` property from the `NavigationInstruction` class changed from `TurnDetails` to `TurnDetails?`
- return type of the `getRouteConnections` method from the `Debug` class changed from `MarkerCollection` to `MarkerCollection?`
- return type of the `createContentUpdater` method from the `ContentStore` class changed from `Pair<ContentUpdater, GemError>` to `(ContentUpdater, GemError)`
- return type of the `getStoreContentList` method from the `ContentStore` class changed from `Pair<List<ContentStoreItem>, bool>` to `(List<ContentStoreItem>, bool)`
- return type of the `getSunriseAndSunset` method from the `MapDetails` class changed from `Pair<DateTime, DateTime>` to `(DateTime, DateTime)`
- return type of the `getAlert` method from the `PTRouteSegment` class changed from `PTAlert` to `PTAlert?`

### Fixed

- the `safety` value of the `CommonOverlayId` enum now works when used within methods
- the `hasTerrainTopography` method of the `GemMapController` now returns correct value
- the `hasTerrainTopography` method of the `GemMapController` now returns correct value
- the `driveSide` getter of the `NavigationInstruction` class now matches the correct street and returns the correct value
- the `getLandmarksInArea` of the `LandmarkStore` now works correctly when no area is provided.
- the `canPlaySounds` property of the `SoundPlayingService` class only affects TTS instructions triggered by the navigation service.


## [2.22.0] - 2025-07-03

### Added

- `ProjectionType`, `SoundPlayType`, `Hemisphere` enums
- `MGRSProjection`, `BNGProjection`, `Projection`, `WProjection`, `GKProjection`, `LAMProjection`, `UTMProjection`, `ProjectionService`, `SoundPlayingListener` classes
- `soundPlayingListener` property to the `SoundPlayingService` class
- `searchCountries` method to the `GuidedAddressSearchService` class

### Changed

- Added `scenic` value to the `RouteType` enum 
- return type of the `getTopicNotificationsServiceRestriction` method from the `SdkSettings` class changed from `OnlineRestrictions` to `Set<OnlineRestrictions>`
- the `taskHandler` parameter of the `cancelNavigation` method from the `NavigationService` class is optional. The default value is `null` and cancels the currently active navigation.
- the `ignoreAltitude` named parameter has been added to the `distance` method from the `Coordinates` class. The parameter defaults to `false` in order to preserve current behavior.
- return type of the `getLogMetadata` method from the `RecorderBookmarks` class changed from `LogMetadata` to `LogMetadata?`

### Fixed

- the `release` method of the `GemKit` class clears resources and resets state of the singleton instances of the SDK. Changes made on previous sessions no longer affect the current session.
- the `getByKey` method of the `ExtraInfo` class returns null instead of raising an exception on non-existing key
- the `addUserMetadata` method of the `LogMetadata` class works with larger payloads
- the `containsCoordinates` method of the `CircleGeographicArea` works as expected when coordinates contain altitude.
- the `setMockData` method of the `DataSource` class returns `GemError.notSupported` when the `senseData` and `type` parameters do not match.

## [2.21.0] - 2025-06-05

### Added

- the `LandmarkOrder` enum
- the `SettingsService` class
- the `LandmarkBrowseSession` class
- the `createLandmarkBrowseSession` method to the `LandmarkBrowseSession` class
- the `warningsVolume`, `audioOutput` and `callTimingDelay` setters and getters to the `SoundPlayingService`, 
- the `getAndroidVersion` static method of the `Debug` class
- the `SocialReportListener` class.
- the `registerReportListener` and `unregisterReportListener` methods to the `SocialOverlay` class.

### Removed

- the `automaticTimestamp` field of the `RoutePreferences` class has been removed. 

### Changed

- the `dispose` method of the `LandmarkStore` class is now synchronous
- the type of the `publicTransportFare` getter of the `PTRoute` class changed from `String` to `String?`
- the type of the `stopPlatformCode` field of the `PTTrip` class changed from `String` to `String?`
- the type of the `autoPlaySound` parameter of the `startNavigation` method of the `NavigationService` class has been changed from `bool` to `bool?`. The parameter has been deprecated
- the `importLandmarks` and `importLandmarksWithDataBuffer` methods of the `LandmarkStore` class can take an additional `onProgressUpdated` callback optional parameter. the `categoryId` is no longer required and has a suitable default value.
- methods in the `SocialOverlay` class now provide an `onComplete` callback which gives the `GemError` result. These methods now return `EventHandler?` instead of `GemError` and `GemError.scheduled` (in case of operation started with success) was removed in favor of providing `GemError.success` via the callback when the operation completed.  
- the `report` method of `SocialOverlay` now uses named parameters; `snapshot`, `format`, and `params` are optional, and `description` has a default value.

### Fixed

- the `cameraState` setter of the `MapCamera` now sets the correct value
- the `PTAlgorithmType` enum set within `RoutingSettings` now has the correct effect on the calculated routes.
- the `addList` method of the `MapViewMarkerCollections` class now works
- the `renderingRule` no longer flickers the map on Android
- the `setAllowConnection` and `setAllowInternetConnection` methods now allow internet connection when `allowInternetConnection` is set to true and the previous value was set to false.
- the `getCountryFlagImgByIndex` method of the `MapDetails` class correctly returns `null` when the index is invalid.
- the `importLandmarksWithDataBuffer` method no longer crashes on release builds

## [2.20.0] - 2025-05-22

### Added

- `RenderRule`, `LandmarkFileFormat`, `MapStatus` enums
- `TrafficService`, `TrafficPreferences`, `UserRoadblockPathPreviewCoordinate`, `PathMatch`, `PersistentRoadblockListener`, `ExternalInfoService` classes
- `isConnected`, `isMobileDataConnected`, `isWifiConnected` methods to the `NetworkProvider` class
- `enableSocialReportsWithCategory`, `disableSocialReports`, `enableSafetyCamera`, `unmonitorAllAreas`, `enableSocialReports`, `isSocialReportsEnabledWithCategory`, `disableSafetyCamera`, `disableSocialReportsWithCategory`, `unmonitorAreasByIds` methods to the `AlarmService` class
- `monitoredAreas`, `isSocialReportsEnabled`, `isSafetyCameraEnabled` getters to the `AlarmService` class
- `render`, `markNeedsRender`, `cursorSelectionTrafficEvents` methods to the `GemView` and `GemMapController` classes
- `renderingRule` getter/setter to the `GemView` class
- `cancelGetPreviewData`, `getPreviewData` methods to the `TrafficEvent` class
- `getElevationSamplesByCount`, `getTotalUp`, `getTotalDown` methods to the `RouteTerrainProfile` class
- `getCategoriesFromLandmark`, `importLandmarksWithDataBuffer`, `setImage`, `getLandmarkCount`, `stopFastUpdateMode`, `getLandmarksInArea`, `startFastUpdateMode`, `setLandmarkCategory`, `isFastUpdateMode`, `cancelImportLandmarks`, `importLandmarks`, `getFilePath` methods to the `LandmarkStore` class
- `image` property to the `LandmarkStore` class
- `cancelGetPreviewData`, `getPreviewData` methods to the `RouteTrafficEvent` class
- `requestWikiImageInfo`, `cancelWikiImageInfoRequest` methods to the `ExternalInfo` class
- `hitTest` methods to the `MapViewPathCollection` class

### Removed

- `crossedBoundaries` properties from the `AlarmService` class as the `AlarmListener` has been improved and provides the list of entered and exited areas
- `hasWikiInfo`, `cancelWikiInfo`, `getExternalInfo` methods from the `ExternalInfo` class. These methods were moved to the `ExternalInfoService` class as the API was confusing.

### Changed

- `NetworkProvider` no loger implements `EventHandler`
- the `Status` enum has been renamed to `MapStatus`. The change has affected the `registerOnWorldwideRoadMapSupportStatus` and `registerOnAvailableContentUpdate` methods of the `OffBoardListener` class and the `setAllowConnection` of the `SdkSettings` class
- return type of the `getMarkerAt` method from the `MarkerCollection` class changed from `Marker` to `Marker?`
- return type of the `getMarkerById` method from the `MarkerCollection` class changed from `Marker` to `Marker?`
- return type of the `getPointsGroupHead` method from the `MarkerCollection` class changed from `Marker` to `Marker?`
- the parameters of the `monitorArea` method from the `AlarmService` class changed, added `String id` optional parameter
- the parameters of the `registerOnBoundaryCrossed` method from the `AlarmListener` class changed and now requires a `void Function(List<String> enteredAreas, List<String> exitedAreas)` callback.
- the type of the `labelGroupTextSize` property from the `MarkerCollectionRenderSettings` class changed from `int` to `double`
- return type of the `getCoordinates` method from the `EntranceLocations` class changed from `Coordinates` to `Coordinates?`
- the type of the `affectedTransportModes` property from the `TrafficEvent` class changed from `Set<TrafficTransportMode>` to `RouteTransportMode`
- the `addList` method from the `MapViewMarkerCollections` class is now async and needs to be awaited
- return type of the `getPathAt` method from the `MapViewPathCollection` class changed from `Path` to `Path?`
- return type of the `getPathByName` method from the `MapViewPathCollection` class changed from `Path` to `Path?`
- `requestLocationPermission` getter of the `PositionService` class is now method.
- deprecated the `getWikiPageUrl`, `getWikiPageLanguage`, `getWikiPageTitle`, `getWikiPageDescription`, `getImagesCount` of the `ExternalInfo` class. These methods were replaced with the `wikiPageUrl`, `wikiPageLanguage`, `wikiPageTitle`, `wikiPageDescription`, `imagesCount` getters.

### Fixed

- the `getPathAt` and `getPathByName` methods of the `MapViewPathCollection` class no longer freeze the app when called with invalid input
- the `Orientation` objects provided by the SDK now come with correct values
- the `addList` method of the `MapViewMarkerCollections` class no longer crashes on 32-bit Android systems
- the `harshBrakingScore` method of the `DrivingScores` class no longer crashes and returns the correct value
- the `CircleGeographicAreas` and `PolygonGeographicArea` objects provided by the SDK are now correctly deserialized
- the `insideAreas` and `outsideAreas` getters of the `AlarmService` class no longer crash the app and return the correct values
- the `getForecast` method of the `WeatherService` class now returns `LocationForecast` objects with correct `updated` fields. The method now returns `GemError.invalidInput` if the given coordinates are invalid
- the `TransferStatistics` class now returns correct value on extra charged networks

## [2.19.0] - 2025-05-08

### Added

- `TimeZoneStatus`, `VoiceType`, `HardwareSpecification` enums
- `NmeaChunk`, `TimezoneService`, `SoundPlayingService`, `LogMetrics`, `Voice`, `PTRouteInfo`, `TimezoneResult`, `WeatherDurationCoordinates` classes
- `hardwareSpecifications` getter/setter pair to the `RecorderConfiguration` class
- `produceNmeaChunk` method to the `SenseDataFactory` class
- `getVoice`, `setVoiceByPath` methods to the `SdkSettings` class
- `getOptimalHighlightCenterViewport`, `cursorSelectionMapSceneObject`, `centerOnRouteTrafficEvent`, `cursorSelectionPath`, `getAltitude`, `transformScreenToWgsRect`, `getVisibleRouteInterval`, `checkObjectVisibility`, `canZoom`, `getHighlight`, `getOptimalRoutesCenterViewport`, `setClippingArea` methods and `hasTerrainTopography`, `isAnimationInProgress`, `pitchInDegrees`, `minZoomLevel`, `cursorWgsPosition`, `headingInDegrees`, `viewportF`, `isCameraMoving` to the `GemView` and extending `GemMapController` class
- `logMetrics` getter to the `LogMetadata` class
- `mapRotationMode` getter to the `FollowPositionPreferences` class
- `camera` setter to the `GemView` class
- `maxZoomLevel` setter to the `GemView` class

### Removed

- `osInfo` properties from the `SdkSettings` class as it was not valuable and the Flutter SDK provides better built-in alternatives
- `deviceModel` getter/setter pair from the `RecorderConfiguration` class has been deprecated. The same functionality is now achieved via the settings set in the `hardwareSpecifications` getter/setter.
- `ExternalPositionData` class and the `positionFromExternalData` method from the `SenseDataFactory` class have been deprecated. The same functionality can now be achieved using the `producePosition` method from the `SenseDataFactory` class.
- `setNorthFixedFlag` method from the `MapViewPreferences` has been deprecated and replaced with the `northFixedFlag` setter
- `setTTSLanguage` method from the `SdkSettings` class has been deprecated and replaced with the `setTTSVoiceByLanguage` method
- `refreshContentStore` method from the `ContentStore` class has been deprecated and replaced with the `refresh` method
- `setActivityRecord` method from the `Recorder` class has been deprecated and replaced with the `activityRecord` getter

### Changed

- the map file structure has been changed. The SDK version must be updated to at least the current version in order to continue receiving map updates in the future. Map support for older SDK versions is still available for 2 years.
- updated the `pubspec.yaml` requirements: the minimum Flutter version required is 3.27.0 and the minimum Dart version required is 3.6.0
- added `nmeaChunk` value to `DataType` enum 
- added `dr` value to `FileType` enum 
- changed the `coords` parameter type of the `getForecast` method from the `WeatherService` from `List<TimeDistanceCoordinate>` to `List<WeatherDurationCoordinates>`
- the type of the `overlayInfo` property from the `OverlayItem` class changed from `OverlayInfo` to `OverlayInfo?`
- added optional `restoreCameraMode` parameter to the `stopFollowingPosition` method from the `GemView` and `GemMapController` classes
- the type of the `image` property from the `OverlayInfo` class changed from `Uint8List` to `Uint8List?`
- the type of the `image` property from the `OverlayCategory` class changed from `Uint8List` to `Uint8List?`
- return type of the `getElevationSamples` method from the `RouteTerrainProfile` class changed from `Pair<List, double>` to `Pair<List<double>, double>`
- added optional `autoPlaySound` parameter to the `startSimulation` and `startNavigation` methods from the `NavigationService`
- `isStopped` method from the `DataSource` class has been replaced with getter
- `PtRoute` class from the`pt_stop_info.dart` file has been renamed to `PtRouteInfo`. A class with the `PtRoute` name already exists in the `route.dart` file
- `registerCursorSelectionMapSceneObjectCallback` method from the `GemMapController` class has been renamed to `registerCursorSelectionUpdatedMapSceneObjectCallback`

### Fixed

- `getLatestData` method from the `Playback` class now returns correct data
- `overlayInfos` getter from the `OverlayCollection` class no longer throws exception and returns correct items.

## [2.18.0] - 2025-04-24

### Added

- `PTAgency`, `PTRoute`, `PTStop`, `PTStopTime`, `PTTrip`, `PTStopInfo` classes
- `PTRouteType` enum
- `MappedDrivingEvent`, `DrivingScores`, `DriverBehaviourAnalysis`, `DriverBehaviour` classes
- `DrivingEvent` enum
- `TransferStatistics` class
- `ViewOnlineServiceType` enum
- `TransferStatistics` getter method in `ContentStore`, `MapView`, `GuidedAddressSearchService`, `NavigationService`, `RoutingService`, `SdkSettings`, `SearchService`, `SocialOverlay`, `Weather` classes
- `setAllowConnection` and `autoUpdate` methods in `SdkSettings` class
- `onAutoUpdateComplete` callback in `SdkSettings` class
- `allowInternetConnection` flag in `GemMap` constructor
- `asJson` method in `GemParameter` and `GemParameterList` classes
- `cursorSelectionOverlayItemsByType` method in `MapView` class
- `isOfType` and `getPTStopInfo` methods in `OverlayItem` class

### Removed

- `RoadInfoImageRenderSettings` class

### Changed
- updated the `pubspec.yaml` requirements: the minimum Flutter version required is 3.27.0 and the minimum Dart version required is 3.6.0
- the `addUserMetadata` method from the `LogMetadata` is now async and should be awaited
- `OffBoardListener`
- `handleTouchEvent` is now async


## [2.17.0] - 2025-04-10

### Added

- `RoutingAlgoModifiers`, `ImageType` enums
- `MountInfo`, `LaneImg`, `AbstractGeometryImg`, `SignpostImg`, `RoadInfoImg`, `RenderableImg`, `Img`, `ImgBase` classes
- `laneImg`, `nextNextTurnImg`, `nextTurnImg` properties to the `NavigationInstruction` class
- `img` property to the `OverlayItem` class
- `img` property to the `Conditions` class
- `img` properties to the `TrafficEvent` class
- `imgPreview` properties to the `ContentStoreItem` class
- `getImgById` method to the `SdkSettings` class
- `getCountryFlagImg`, `getCountryFlagImgByIndex` methods to the `MapDetails` class
- `abstractGeometryImg` properties to the `TurnDetails` class
- `img` properties to the `OverlayCategory` class
- `extraImg`, `overlayItem`, `img` properties to the `Landmark` class
- `img` properties to the `LandmarkCategory` class
- `roadInfoImg`, `realisticNextTurnImg`, `turnImg` properties to the `RouteInstructionBase` class
- `img` properties to the `OverlayInfo` class
- `image` properties to the `SignpostDetails` class
- `getDefUrls`, `isRawPositionTrackerEnabled`, `getRoutingAlgoModifiers`, `getAppIOInfo`, `oneToOnePedestrianCalculation`, `setRoutingAlgoModifiers`, `getNavigationModifiers`, `timeToCheckTrafficAlongRoutesSec`, `getRouteConnections`, `getMapViewMaxZoomRanges`, `getTotalMemory`, `getMaxUsedMemory`, `refreshContentStore`, `setCustomUrl`, `getServiceName`, `updateMaps`, `getStyleBuilderUrls`, `isMainThread`, `cleanupSocialCache`, `getAllWeatherConditions`, `replayStreamActivityLog`, `getUsedMemory`, `getFreeMemory`, `timeToBetterRouteSec`, `manyToManyPedestrianCalculation`, `getServicesIds` methods to the `Debug` class
- `calculate_bike_route`, `center_area`, `center_traffic`, `gpx_routing_thumbnail_image`, `gpx_thumbnail_image`, `map_style_update`, `route_alarms`, `send_debug_info`, `simulate_navigation_without_map`, `speed_tts_warning`, `what_is_nearby_category` examples

### Removed

- `networkProvider` properties from the `SdkSettings` class as it was not working
- `searchReportsAlongRoute`, `searchReportsAround` methods from the `SocialOverlay` class as searching for reports can now be done via the `SearchService`
- the `image` setter from the `Conditions` class.
- the `image` setter from the `OverlayCategory` class.

### Changed

- the `pauseDownload` method from the `ContentStoreItem` now takes an optional `onComplete` parameter
- the `clear` method from the `MapViewMarkerCollections` is now async and should be awaited


## [2.16.0] - 2025-03-27

### Added

- `AutoUpdateSettings` class
- `handleTouchEvent` method to the `GemMapController` and `GemView` classes

### Removed

- `DataBuffer` class as it was not fully implemented and all operations are exposed in the Dart SDK using the predefined `Uint8List` type
- `updateCurrentStyleFromJson` method from the `MapViewPreferences` class as it depended on the non-functional `DataBuffer` class
- `save`, `load` methods from the `MapViewMarkerCollections` class as they depended on the non-functional `DataBuffer` class

### Changed

- return type of the `createLogDataSource`, `createLiveDataSource`, `createExternalDataSource` and `createSimulationDataSource` methods from the `DataSource` class changed from `DataSource` to `DataSource?`
- renamed the `allow` parameter to `allowInternetConnection` and `canDoAutoUpdate` to `canDoAutoUpdateResources` in the `setAllowConnection` method from the `SdkSettings` class.
- the `initialize` method from the `GemKit` class takes an additional optional parameter `autoUpdateSettings` of type `AutoUpdateSettings` 
- return type of the `hitTest` method from the `MapViewMarkerCollections` class changed from `MarkerMatchList` to `List<MarkerMatch>`

### Fixed

- the `alarmListener` setter from the `AlarmService` class now correctly sets the listener
- the `pictogramType` getter from the `SignpostItem` class now returns the correct value
- `Weather` related methods on older `iOS` devices
- issue when navigating with multiple waypoints


## [2.15.0] - 2025-03-13

### Added

- `FileSortType`, `AppTheme`, `NextSpeedLimitStatus`, `FileSortOrder`, `OnlineRestrictions`, `LogUploaderState` enums
- `LogUploader` class
- `getOnlineServiceRestriction`, `getBestLanguageMatch`, `getTopicNotificationsServiceRestriction`, `setSdkVersion` methods to the `SdkSettings` class
- `actualAppTheme`, `sdkVersion`, `appTheme`, `deviceModel`, `deviceName`, `digitGroupSeparator`, `applicationName`, `decimalSeparator` properties to the `SdkSettings` class
- `hasSignpostInfo` getter to the `NavigationInstruction` class
- `deleteLog`, `markLogUploaded`, `getLogDurationInSeconds`, `markLogProtected` methods to the `RecorderBookmarks` class
- `protectedLogsList` getter to the `RecorderBookmarks` class
- `status` properties to the `NextSpeedLimit` class
- `requestLocationPermission` properties to the `PositionService` class

### Removed

- `setVoiceByPath` method from the `SdkSettings` class as they are not fully supported by the Flutter SDK.
- `smallMode` field of the `SignpostImageRenderSettings` as this feature is not fully implemented.

### Changed

- renamed `EPlayingStatus` enum to `PlayingStatus`, `UnitOfMearsurementAcceleration` enum to `UnitOfMeasurementAcceleration`
- `MarkerLabelingMode` enum values: fixed typo in `textBellow` (renamed to `textBelow`) and removed deprecated `group` and `item` values
- fixed typo in the `SignpostPictogramType` enum. Renamed the `hoteMotel` value to `hotelMotel`
- `logsList` getter from the `RecorderBookmarks` replaced with the `getLogsList` method. It also provides sorting functionality.
- `setTouchHandlerModifyHorizontalAngleLimits`, `setTouchHandlerModifyDistanceLimits` methods from the `FollowPositionPreferences` class replaced with `touchHandlerModifyHorizontalAngleLimits` and `touchHandlerModifyDistanceLimits` setters.
- `FileType` enum changed values: `csv`, `tcx`, `fit` values; 
- `getState`, `getDuration`, `getCurrentPosition`, `getSpeedMultiplier`, `getMaxSpeedMultiplier`, `getLogPath`, `getRoute`, `getMinSpeedMultiplier` methods from the `Playback` class were replaced by the `state`, `duration`, `currentPosition`, `speedMultiplier`, `maxSpeedMultiplier`, `logPath`, `route` and `minSpeedMultiplier` getters
- return type of the `update` method from the `ContentUpdater` class changed from `GemError` to `ProgressListener?`. Added `onCompleteCallback` named optional parameter which provides the update result.
- fixed typo in the `insideCityAea` named parameter of the `getOverSpeedThreshold` method from the `AlarmService` class. Renamed to `insideCityArea`
- return type of the `step` method from the `Playback` class changed from `GemError` to `void`
- return type of the `getItemById` method from the `ContentStore` class changed from `ContentStoreItem` to `ContentStoreItem?`
- return type of the `createContentUpdater` method from the `ContentStore` class changed from `ContentUpdater` to `Pair<ContentUpdater, GemError>`
- the `recorderConfiguration` setter from the `Recorder` class replaced with the `setRecorderConfiguration` method. The method also provides the operation error code.
- type of the `zoom` parameter of the `createLandmarkStore` method of the `LandmarkStoreService` class from `int?` to `int`. A default value of `-1` has also been provided
- type of the `overwrite` parameter of the `add` method of the `RouteBookmarks` class from `bool?` to `bool`. A default value of `false` has also been provided
- type of the `removeLmkContent` parameter of the `removeCategory` method of the `LandmarkStore` class from `bool?` to `bool`. A default value of `false` has also been provided
- type of the `updateItem` property from the `ContentStoreItem` class changed from `ContentStoreItem` to `ContentStoreItem?`
- the `locationForecasts` parameter of the `onCompleteCallback` callback within the parameters of the `getDailyForecast`, `getHourlyForecast`, `getCurrent`, `getForecast` methods from the `WeatherService` class has changed type from `List<LocationForecast>?` to `List<LocationForecast>`. The result list provided by the callback is now empty instead of `null` when the operation fails
- the `RenderSettings` class is now a generic template. The `options` property changed type from `Set<dynamic>` to `Set<T>`. The type of the `options` property from the `RouteRenderSettings` class changed from `Set<dynamic>` to `Set<RouteRenderOptions>`. The type of the `options` property from the `HighlightRenderSettings` class changed from `Set<dynamic>` to `Set<HighlightOptions>`

### Fixed

- the `activateHighlight` method from the `GemMapController` class (the `innerColor` field of the `HighlightRenderSettings` class was not taken into account, the operation did not work when no `renderSettings` value was provided)
- the `renderSettings` parameter from the `getLaneImage` method provided by the `NavigationInstruction` class is now taken into account
- the `asyncGetStoreContentList` method from the `ContentStore` class now provides result via callback when the operation fails
- the `referencePosition` getter from the `AlarmService` class now returns correct value
- the `step` method from the `Playback` class now works correctly
- the `enableDrawMarkersMode` method now works correctly


## [2.14.1] - 2025-03-03

### Fixed

- map rotation when in navigation mode


## [2.14.0] - 2025-02-27

### Added

- `TrafficEvent`, `PositionOrientation`, `AlarmMonitoredArea` classes
- `insideAreas`, `referencePosition`, `outsideAreas`, `trackedPositionSource` properties to the `AlarmService` class
- `TilesCollectionGeographicArea` class implements `GeographicArea` interface and now provides the `isEmpty`, `type` getters
- `contains`, `containsCategory` methods and `overlayInfos` getter to the `OverlayCollection` class and extending class `OverlayMutableCollection`
- `resetDefPositionTrackerAccuracyCircleColor`, `setDefPositionTrackerAccuracyCircleColor`, `getDefPositionTrackerAccuracyCircleColor` methods to the `MapSceneObject` class
- `imagePosition` field to the `RenderSettings` class
- `setCameraTargetCentered`, `setCameraRelativeToCenteredTarget`, `generatePositionAndOrientationHPR`, `setCameraRelativeToTarget`, `generatePositionAndOrientationRelativeToTarget`, `generatePositionAndOrientationTargetCentered`, `generatePositionAndOrientationRelativeToCenteredTarget`, `generatePositionAndOrientation` methods and `cameraPosition`, `cameraOrientation` properties to the `MapCamera` class
- `touchHandlerModifyDistanceLimits`, `touchHandlerModifyVerticalAngleLimits`, `touchHandlerModifyHorizontalAngleLimits` properties to the `FollowPositionPreferences` class
- `getCountryFlagByIndex` methods to the `MapDetails` class
- `checkBetterRoute` method and `logCreateObject`, `logListenerMethod`, `logCallObjectMethod`, `logLevel` properties to the `Debug` class
- `activateHighlightOverlayItems` method to the `GemView` and `GemMapController` classes
- `registerCursorSelectionUpdatedPathCallback`, `registerHoveredMapLabelHighlightedLandmarkCallback`, `registerShoveCallback`, `registerPinchSwipeCallback`, `registerTouchHandlerModifyFollowPositionCallback`, `registerHoveredMapLabelHighlightedOverlayItemCallback`, `registerPinchCallback`, `registerTouchMoveCallback`, `registerSetMapStyleCallback`, `registerSwipeCallback`, `registerCursorSelectionUpdatedLandmarksCallback`, `registerTouchPinchCallback`, `registerCursorSelectionMapSceneObjectCallback`, `registerCursorSelectionUpdatedMarkersCallback`, `registerCursorSelectionUpdatedRoutesCallback`, `registerHoveredMapLabelHighlightedTrafficEventCallback`, `registerCursorSelectionUpdatedOverlayItemsCallback`, `registerDoubleTouchCallback`, `registerCursorSelectionUpdatedTrafficEventsCallback`, `registerTwoTouchesCallback` methods to the `GemMapController` class

### Removed

- YELP related features (`getYelpPhoneNumber`, `getYelpRating`, `getYelpImagesCount`, `cancelYelpInfo`, `getYelpName`, `getYelpUrl`, `hasYelpInfo`, `getYelpImagePath`, `getYelpAddress` methods from the `ExternalInfo` class)
- `isPrintSdkDebugInfoEnabled` property from the `Debug` class as it was replaced with more fine-tuned properties in the `Debug` class.
- `registerOnMapAngleUpdateCallback`, `registerOnMapViewMoveStateChangedCallback`, `registerPointerMoveCallback`, `registerPointerUpCallback`, `registerPointerDownCallback`, `registerOnLongPressCallback` methods from the `GemMapController` class. The `registerOn...` methods were deprecated in a previous release and are replaced with other methods. The methods related to pointer operations were removed as they were not working

### Changed

- `getOverlayById` method from the `OverlayCollection` and `OverlayMutableCollection` classes renamed to `getOverlayByUId`
- `getContourGeograficArea` method from the `Landmark` class renamed to `getContourGeographicArea`
- `RouteTrafficEvent` class now extends `TrafficEvent`. Some methods were replaced with getters.
- `onYelpDataAvailable` parameter of the `getExternalInfo` method from the `ExternalInfo` class was removed
- return type of the `customizeDefPositionTracker` method from the `MapSceneObject` class changed from `int` to `GemError`
- return type of the `getField` method from the `AddressInfo` class changed from `String` to `String?`
- return type of the `getRenderSettings` method from the `MapViewRoutesCollection` class changed from `RouteRenderSettings` to `RouteRenderSettings?`
- return type of the `getMapViewRoute` method from the `MapViewRoutesCollection` class changed from `MapViewRoute` to `MapViewRoute?`
- the type of the `mainRoute` property from the `MapViewRoutesCollection` class changed from `Route` to `Route?`
- the parameters of the `asyncUpdateToFromData` method from the `RouteTrafficEvent` class changed from `ProgressListener` to callback method.
- the type of the `toLandmark` property from the `RouteTrafficEvent` class changed from `bool` to `Pair<Landmark, bool>`
- the parameter `moveCallback` of the `registerMoveCallback` method from the `GemMapController` class changed from `TouchCallbackMove` to `MoveCallback`
- the `zoomLevel` parameter of the `startFollowingPosition` method from the `GemMapController` class changed from `int?` to `int`. A value of `-1` is given by default
- the `duration` parameter of the `setZoomLevel` method from the `GemMapController` class changed from `int?` to `int`. A value of `0` is given by default
- the `duration` parameter of the `setSlippyZoomLevel` method from the `GemMapController` class changed from `int?` to `int`. A value of `0` is given by default
- the `displayMode` parameter of the `centerOnRoutes` method from the `GemMapController` class changed from `RouteDisplayMode?` to `RouteDisplayMode`. A value of `RouteDisplayMode.full` is given by default.
- the `zoomLevel` parameter of the `startFollowingPosition` method from the `GemView` class changed from `int?` to `int`. A value of `-1` is given by default
- the `duration` parameter of the `setZoomLevel` method from the `GemView` class changed from `int?` to `int`. A value of `0` is given by default
- the `duration` parameter of the `setSlippyZoomLevel` method from the `GemView` class changed from `int?` to `int`. A value of `0` is given by default
- the `displayMode` parameters of the `centerOnRoutes` method from the `GemView` class changed from `RouteDisplayMode?` to `RouteDisplayMode`. A default value of `RouteDisplayMode.full` is given by default

### Fixed

- `getNextAddressDetailLevel` method of the `GuidedAddressSearchService` no longer crashed app on invalid input
- `getField` method of the `AddressInfo` class
- recording now works without requiring the existence of a map widget
- `textColor` field of a `RouteRenderSettings` object is now working as expected
- `captureImage` method of the `GemView` class now completes when multiple calls are done in quick succession
- `getLaneImage` method of the `NavigationInstruction` now takes into account the given `LaneImageRenderSettings` parameter
- `getImage` method of the `SignpostDetails` now correctly takes into account the given `SignpostImageRenderSettings` parameter
- all methods/getters returning `UInt8List?` result as image now return `null` instead of returning invalid data


## [2.13.0] - 2025-02-13

### Added 

- `soundMarks`, `activityRecord`, `soundMarks` getters to the `LogMetadata` class.
- `Playback` and `Soundmark`, `ActivityRecord` classes
- `currentRecordPath` getter and `setActivityRecord` getters from the `Recorder` class
- `playback` getter to the `DataSource` class. `createSimulationDataSource` and `createLogDataSource`
- `previewDataJson` getter to the `OverlayItem` class
- `activityRecord` getter on `LogMetaData` class
- `heartRate` value to the `DataType` enum. Implies id changes. Renamed `altitude` value to `attitude`
- `RotationRate`, `Attitude`, `Battery`, `MagneticField`, `Orientation`, `Temperature`, `MountInformation`, `Activity` classes and related `SenseDataFactory` methods
- `isPrintSdkDebugInfoEnabled` and `isObjectAliveCheckEnabled` getters/setters to the `Debug` class
- `DataSourceListener` class
- `addListener`, `removeListenerAllDataTypes` and `removeListener` to the `DataSource` class.
- `removeListener` method from the `RouteBase`.
- `withBool`, `withInt`, `withReal`, `withString`, `withList` factory methods to `GemParameter`

### Changed

- Most images from the SDK return `Uint8List?` instead of `Uint8List`
- Updated `ColorExtension` in regards to the Flutter version 3.27 (https://docs.flutter.dev/release/breaking-changes/wide-gamut-framework). Might require API users to update to the latest Flutter version
- Renamed `registerOnLongPressCallback`, `registerOnMapAngleUpdateCallback` and `registerOnMapViewMoveStateChangedCallback` methods from the `GemMapController` class to `registerLongPressCallback`, `registerMapAngleUpdateCallback`, `registerMapViewMoveStateChangedCallback`. Old methods are still available but they are deprecated and will be removed in a future release
- `RecorderBookmarks.create` now returns `RecorderBookmarks?` instead of `RecorderBookmarks`
- `getMapExtendedCapabilities` now returns `Set<MapExtendedCapability>` instead of packed `int`
- `stopRecording` from `Recorder` class is now async and needs to be awaited
- `getOverlayById` and `getOverlayAt` methods of the `OverlayCollection` now return `OverlayItem?` instead of `OverlayItem`
- `setConfiguration` method of the `DataSource` class has named parameters. The `getConfiguration` now returns `SensorConfiguration` instead of `Map<String, String>` 
- `alignNorthUp` takes `Animation` instead of `Duration` as a parameter
- `SearchableParameterList` extends `ParameterList`. Created default constructors for `ParameterList` and `SearchableParameterList`. The `SearchableParameterList` constructor can take an optional `ParameterList`
- `GemView`, `NetworkProvider`, `RouteListener`, `OffboardListener`, `NavigationListener`, `LandmarkStoreListener`, `AlarmListener`, `PositionListener`, `DataSourceListener` classes no longer implement `EventDrivenProgressListener`. They now implement `EventHandler`
- `getPosition` and `getImprovedPosition` methods from `PositionService` class replaced by `position` and `improvedPosition` getters
- `getCountryLevelItem` method of the `GuidedAddressSearchService` class now returns `Landmark?` instead of `Landmark`
- `exportAs` methods of the `Route` and `Path` classes return `String` instead of `Uint8List`
 
### Fixed

- `setMapStyle` method from the `MapViewPreferences` class
- `setCameraFocus` from the `FollowPositionPreferences` class returns correct value
- `getMarkerById` from the `MarkerCollection` class
- `getBorderColorAt`, `getFillColorAt`, `getBorderSizeAt`, `getInnerSizeAt` methods of `MapViewPathCollection` class
- `format` method of the `AddressInfo` class
- `add` method of the `ParameterList` class
- `getPreferences` method from the `RouteBookmarks` class
- `searchLandmarkDetails` method from the `SearchService` class

### Removed

- `registerOnNotifyCustom` method from the `ProgressListener` class
- `serializeListOfMarkers` method is no longer public


## [2.12.0] - 2025-01-30

### Added
 
- `SenseData`, `GemImprovedPosition`, `Compass` and `Acceleration` interfaces and implementations.
- `SenseDataFactory` class
- `provider`, `latitude`, `longitude`, `altitude`, `speedAccuracy`, `hasSpeedAccuracy`, `hasCourse`, `hasCourseAccuracy`, `hasHorizontalAccuracy`, `hasVerticalAccuracy` getters to the `GemPosition` class
- `isDataTypeAvailable`, `getDataTypeDescription`, `setConfiguration`, `getConfiguration`, `getPreferences`, `isMockData`, `getLatestData`, `setMockData` and `availableDataTypes`, `isSDKInstance`, `origin`, `dataSourceType` getters of `DataSource` class
- `showMapScale` and `areMapScalesDrawnByUser` getters and setters to the `MapViewPreferences` class
- `notifyProgressInterval` setter to the `ProgressListener` class
- `getImprovedPosition` and `getDataSource` methods and `sourceType` getter to the `PositionService` class

### Changed
 
- `GemPosition` is now an interface. All the fields contained within are now getters. `GemPosition` now extends `SenseData`.
- Deprecated `timestamp` getter from `GemPosition` class.
- `pushData` method of `DataSource` class takes a single required positional `SenseData` parameter instead of optional `ExternalAccelerationData` and `ExternalPositionData` parameters
- `startRecording` method of the `Recorder` class is now async and needs to be awaited
- `skipAnimation` method of `GemView` takes optional `jumpToDestination` parameter

### Fixed
 
- `activateHighlight` method of `GemView` not taking `renderSettings` parameter into consideration
- methods from the `MapViewRoute` class
- more methods use `ApiErrorService` for signaling failure and success
- `notifyProgressInterval` and `progressMultiplier` getters of `ProgressListener`

### Removed
 
- `roadModifiers`, `speedLimit` fields from the `GemPosition` class as they are moved to `GemImprovedPosition`.
- `GemPosition` constructor and `to/fromJson` methods


## [2.11.0] - 2024-12-20

### Added

- `ApiErrorService` class
- `OTRoute` class
- `pause` and `resume` methods to `Recorder` class
- `isOTRoute` and `toOTRoute` methods to `Route` class
- `setNavigationModifiers` method of `Debug` class and `NavigationModifiers` enum
- `pauseRecording` and `resumeRecording` methods of `Recorder`
- `createExternalDataSource` and `createLiveDataSource` static methods of `DataSource`
- `setTTSLanguage` method of `SdkSettings`

### Changed

- Replace `XyType` with `Point` as input parameter to methods from `MapView` and `GemMapController` classes: `highlightHoveredMapLabel`, `centerOnRouteInstruction`, `setSlippyZoomLevel`, `setZoomLevel`, `transformScreenToWgs`
- Replace `XyType` with `Point` as input parameter to methods from `FollowPositionPreferences` class: `setCameraFocus`, `setDrawFPS`
- Replace return type `XyType` with `Point` to methods and getters from `MapView` and `GemMapController` classes: `transformWgsListToScreen`, `transformWgsToScreen`, `cursorScreenPosition`
- Replace return type `XyType` with `Point` to `cameraFocus` getter from `FollowPositionPreferences` class
- Fields which should not be publicly accessible from listeners are now private. The `notify...` methods are now internal. Affected classes are `NetworkProvider`, `RouteListener`, `ProgressListener`, `OffBoardListener`, `NavigationListener`, `LandmarkStoreListener`, `IGemPositionListener`, `EventDrivenProgressListener`, `AlarmListener`. Use the provided `register...` methods instead of setting the callback function directly. 
- `labelingMode` field of the `MarkerRenderSettings` class (and `MarkerCollectionRenderSettings` extending class) is now `Set<MarkerLabelingMode>` instead of `int?`.
- Fields from `ClimbSection`, `SurfaceSection`, `RoadTypeSection`, `SteepSection`, `AbstractGeometryItem`, `AbstractGeometry`, `RectType`, `RenderSettings`, `RouteRenderSettings`, `HighlightRenderSettings`, `TimeDistance`, `MarkerCollectionRenderSettings`, `MarkerRenderSettings`, `RoadInfo`, `Language`, `RecorderConfiguration` and  `TimeDistanceCoordinate` classes are no longer nullable. Initiated default constructor values with appropriate values.
- `RouteInstruction`, `PTRouteInstruction` and `EVRouteInstruction` extend `RouteInstructionBase`. The `toEVRouteInstruction` and `toPTRouteInstruction` are only in the `RouteInstruction` class
- `RouteSegment`, `PTRouteSegment` and `EVRouteSegment` extend `RouteSegmentBase`. The `toEVRouteSegment` and `toPTRouteSegment` are only in the `RouteSegment` class
- `register...` methods from `GemMapController` have nullable parameters to allow unregistering.
- `vizibility` getter and setter from `MapSceneObject` class to `visibility`.
- `insideCityAea` named parameter from `Alarm.setOverSpeedThreshold` method to `insideCityArea`.
- return type from `int` to `GemError` from `setRouteRoadBlock` method from the `RoutingService`
- `enableDrawMarkersMode` method of `MapView` now takes optional `MakerRenderSettings` parameter
- `getContourGeograficArea` method of `Landmark` replaced with `getContourGeographicArea`
- `item` and `group` values of `MarkerLabelingMode` enum are new deprecated. Added `itemLabelVisible` and `groupLabelVisible` values.
- `arrivalTime` and `departureTime` getters of `PTRouteSegment` and `arrivalTime` and `departureTime` getters of `PTRouteInstruction` now return `DateTime?` instead of `DateTime`.
- external `DataSource` objects are instantiated using the `createExternalDataSource` static method instead of constructor.
- deprecated `NavigationEventType` enum.
- Made `onNavigationInstructionUpdate` callback of the `startNavigation` and `startSimulation` methods of `NavigationService` nullable. The `onNavigationInstructionUpdate` method will be removed as all features are already provided by more specialized callbacks.
- `startNavigation` and `startSimulation` methods of `NavigationService` return `TaskHandler?` instead of `TaskHandler`. The value `null` is returned when starting the operation fails and the `onError` callback is called with the error code.
- `search`, `searchLandmarkDetails`, `searchAlongRoute`, `searchInArea`, `searchAroundPosition` of the `SearchService` class return `TaskHandler?` instead of `TaskHandler`. The value `null` is returned when starting the operation fails and the `onCompleteCallback` callback is called with the error code. Changed `onCompleteCallback` callback `results` parameter to non-nullable list of Landmarks. On error the list will be empty instead of null.
- `calculateRoute` of the `RoutingService` class return `TaskHandler?` instead of `TaskHandler`. The value `null` is returned when starting the operation fails and the `onCompleteCallback` callback is called with the error code. Changed `onCompleteCallback` callback `routes` parameter to non-nullable list of Routes. On error the list will be empty instead of null.
- `searchReportsAlongRoute` and `searchReportsAround` of the `SocialOverlay` class return `TaskHandler?` instead of `TaskHandler`. The value `null` is returned when starting the operation fails and the `onCompleteCallback` callback is called with the error code. Changed `onCompleteCallback` callback `routes` parameter to non-nullable list of OverlayItemPosition. On error the list will be empty instead of null.

### Fixed

- `setRouteRoadBlock` method from the `RoutingService` class.
- `registerOnMapViewMoveStateChangedCallback` callback now provides correct area
- Marker disapearing while passing nearby
- `exportLog` returns correct filename when no name is provided
- `isTouchGestureEnabled` method of `MapViewPreferences` class
- `setMapViewPerspective` method of `MapViewPreferences` class

### Removed

- `CameraConfiguration`, `SizeType`, `AutoDisposableObject` classes
- `TimezoneResult` class and related enums
- `fromJson` method of `MarkerRenderSettings` and `MarkerCollectionRenderSettings` classes
- `hasRoutesCollectionInit`, `hasPathCollectionInit`, `hasFollowPositionPrefsInit` fields from `MapViewPreferences` class
- `routeTrack` getter from the `RouteBase` as it was replaced with the `track` getter from  the `OTRoute` class
- `toJson` methods from `Parameter` and `Conditions` classes
- `overrideOverheatCheck` field of `RecorderConfiguration` class


## [2.10.0] - 2024-11-29

### Added

- `getLocalContentList`, `getStoreContentList`, `cancel` methods of `ContentStore` class
- `orientation` getter, `visibility` setter and getter, `maxScale` getter for `MapSceneObject` class
- `addUserMetadata` and `getUserMetadata` methods and `logSize` getter of `LogMetadata` class
- `isValid` getter of `Version` class
- `fromLatLong` constructor of `Coordinates` class

### Changed

- `startSimulation` and `startNavigation` of `NavigationService` have more optional callback functions parameters:  `onNavigationInstruction`, `onNavigationStarted`, `onDestinationReached`, `onBetterRouteRejected`, `onBetterRouteInvalidated`, `onSkipNextIntermediateDestinationDetected`, `onError`, `onNotifyStatusChange`
- Constructor of `GemMap` has optional `initialMapStyleAsset` parameter
- renamed `GemMapController` register methods: `registerFollowPositionState` to `registerFollowPositionStateCallback`, `registerOnMapAngleUpdate` to `registerOnMapAngleUpdateCallback`, `registerOnMapViewMoveStateChanged` to `registerOnMapViewMoveStateChangedCallback`
- `resetMapSelection` method of `GemView` class is now async
- default value for `latitude` and `longitude` fields of `Coordinates` class are now `2147483647`
- `IMapViewListener` class is now abstract
- `GemView` class implements `IMapViewListener` abstract class
- `init` and `releaseView` methods of `GemView` ckass are now internal
- `onFollowPostionState` renamed to `onFollowPositionState` in `IMapViewListener` class and subclasses
- `GemMap` and `GemMapState` fields and methods are now private
- type of `localTime` field of `TimezoneResult` is now `DateTime` instead of `Time`

### Fixed

- `setNavigationRoadBlock` of `NavigationService` class now takes length into account
- `getUserMetadata` method of `LogMetadata` class
- `isDataTypeAvailable` method of `LogMetadata` class
- `cancelRoute` method of `RoutingService` class
- `cancelSearch` method of `SearchService` class
- `viewport` getter of `GemView` has value as soon as `onMapCreated` is called
- `timestamp` setter of `Landmark` class

### Removed

- `coordinates` setter of `MapSceneObject` class
- `SignpostImage`, `RoadInfoImage`, `LaneImage`, `TransferStatistics`, `Time` classes
- `getImageByBitmap` method of `LandmarkCategory` class
- `listener` getter, `setListener` setter abd `hasPrefsInit` field of `GemView` class


## [2.9.0] - 2024-11-12

### Added

- `monitorArea`, `unmonitorArea` methods and `crossedBoundaries` getter of `AlarmService` class
- `getMapReleaseInfo`, `getMapProviderIds`, `getProviderName`, `getProviderSentence` methods of `MapDetails` class
- `algorithmType`, `allowOnlineCalculation` `buildConnections`, `sortingStrategy` fields of `RoutingPreferences` class
- `landmarks` getter and `easyAccessOnlyResults` getter and setter of `SearchPreferences` class
- `getOverlayById` method of `OverlayCollection` class
- `paused`, `pausing`, `resuming` values to `RecorderStatus` enum
- `MapProviderId` enum
- `PTAlgorithmType` enum

### Changed

- `overlays` of `SearchPreferences` class field type to `OverlayMutableCollection` and it is now a getter
- constructor of `SearchPreferences` now takes optional `easyAccessOnlyResults` parameter
- `setCursorScreenPosition` method of `GemView` is now async

### Fixed

- distorted markers rendered on map when images are not square
- `setCursorScreenPosition` method of `GemView` no longer freezes the app on some Android devices

### Removed

- `waypointReached` value of `NavigationEventType` enum
- `strictTrackFollow` field of `RoutingPreferences` class
- `landmarkCategories`, `allStoreCategoriesList`, `hasLandmarkCategoryList` members of `SearchPreferences` class
- `OverlayUuidCategoryUuid` class


## [2.8.0] - 2024-11-01

### Added

- `getMapCoverage`, `getCountryMapCoverage`, `getCountryName`, `getCountryNameByIndex`, `getCountryNameByISO`, `getLanguageCodeByIndex`,  `getLanguageCode` of `MapDetails`
- `currentRoadInformation`, `nextRoadInformation`, `nextNextRoadInformation` getters of `NavigationInstruction` class
- `searchReportsAround`, `addComment`, `updateReport` methods of `SocialOverlay` class
- `hasPreviewExtendedData`, `previewData`, `categoryId`, `getPreviewExtendedData`, `cancelGetPreviewExtendedData` methods of `OverlayItem` class
- `updateReport` method of `SocialOverlay` class
- `AlarmsList` class
- `LandmarkPosition` class
- `OverlayMutableCollection` class
- `AlarmSerivce` class
- `AlarmListener` class
- `WeatherService` class
- `Parameter` class
- `Conditions` class
- `LocationForecast` class
- `Daylight` enum
- `Location Wikipedia` example for showing how to render the wikipedia page information for a point of interest
- `What is Nearby` example for showing how to search for points of interest (POIs) near the current location looking for a certain type of POIs
- `Truck Profile` example for showing how to compute a route based on the accessibility given by the physical characteristics of a truck
- `Public Transit` example for showing how to compute and render a public transit route on the map
- `Assets Map Style` example for showing how to apply a style from a `.style` asset
- `Display Cursor Street Name` example for showing how to display the street name of the location at the cursor position 
- `External Position Source Navigation` example for showing how to navigate by custom positions pushed to a external data source
- `Lane Instructions` example for showing how to display the lane image for the current instruction
- `Overlapped Maps` example for showing how to display two overlapped maps
- `Weather Forecast` example for showing how to display the different types of weather forecasts for a location

### Changed

- renamed `isCursorRenderEnabled` method of `MapViewPreferences` class to `cursorRenderEnabled`
- added `autoGenerateLabel` parameter to `add` method of `MapViewRouteCollection` class
- added `onWaypointReached` callback parameter to `startNavigation` and `startSimulation` methods from `NavigationService`
- `MarkerRenderSettings` default constructor value of imageSize from -1 to 4
- deprecated `waypointReached` value of `NavigationEventType` enum as it was replaced with `onWaypointReached` callback

### Fixed

- `at` method of `SearchableParameterList`
- `add` method of `MarkerCollection` class
- `Markers` icon size recalculation

### Removed

- `create` method of `MapViewPathCollection`


## [2.7.0] - 2024-10-17

### Added

- `SocialOverlay`, `SocialReportsOverlayCategory`, `SocialReportsOverlayInfo`, `OverlayItemPosition` classes
- `checkTrafficAlongRoutes` method of `Debug`
- `RouteListener` class
- `routeListener` getter and setter of `RouteBase`
- `LandmarkStoreType` enum
- `RoutePathAlgorithmFlavor` enum
- `RouteTypePreferences` enum

### Changed

- `alternativesSchema`, `pedestrianProfile`, `resultDetails`, `routeResultType`, `routeType` and `routeTypePreferences` fields of `RoutePreferences` are no longer nullable.
- `routeGroupIdsEarlierLater` field of `RoutePreferences` is of type `List<int>` instead of `dynamic`
- `routeTypePreferences` field of `RoutePreferences` is of type `Set<RouteTypePreferences>` instead of `int`
- `type` getter of `LandmarkStore` returns `LandmarkStoreType` instead of `int`
- `release` method of `GemKit` is async

### Fixed

- `preferences` getter of `GuiddedAddressSearch` returns valid object after calling `GemKit.release()`


## [2.6.0] - 2024-10-10

### Added

- `MapViewRenderInfo` class
- `MotorVehicleProfile` class
- `LandmarkStoreListener` class
- `fromCoordinates` constructor of `Path`
- `navigationRouteLowRateUpdate` getter and setter of `MapViewExtension`
- `getHighlightGroupItemIndex` method of `MapViewExtension`
- `getCategoryCount`, `removeAllStoreCategories`, `getStoreIdAt` methods of `LandmarkStoreCollection`
- `landmarkStores` getter of `LandmarkStoreService`
- `scale` method of `MapController`
- `ViewDataTransitionStatus` and `ViewDataTransitionStatus` enums
- `addListener` and `removeListener` methods of `LandmarkStoreService`
- more values to the `RoutePathAlgorithm` enum

### Changed

- `latitude` and `longitude` members of `Coordinates` are no longer nullable
- `topLeft` and `bottomRight` members of `RectangleGeographicArea` are no longer nullable
- `radius` and `centerCoordinates` members of `CircleGeographicArea` are no longer nullable
- `OverlayCategory` fields no longer nullable
- `onNewPosition` method of `IGemPositionListener` is abstract
- constructor of `GuidedAddressSearchPreferences` is private
- `create` method of `Path` has required parameters and replaced `format` parameter type to `PathFileFormat` from `int`
- `setMinimumAllowedZoomLevel` and `setLowEndCPUOptimizations` replaced with setters `minimumAllowedZoomLevel` and `lowEndCPUOptimizations`
- `registerViewRenderedCallback` of `GemMapController` callback parameter type from `dynamic` to `MapViewRenderInfo`
- `onMapViewRendered` callback takes `MapViewRenderInfo` as argument instead of `dynamic`
- `getAvailableOverlays` method of `OverlayService` takes callback function parameter instead of `ProgressListener`
- `contentType` getter of `ContentUpdater` returns `ContentType` instead of `int`
- `getRoute` method of `MapViewRoutesCollection` returns null for invalid index
- `RouteBookmarks` class moved to `route_bookmarks.dart` file. Added the new file to `routing` lib
- `TruckProfile` and `CarProfile` extend `MotorVehicleProfile`

### Removed

- `setPlaybackDataSource` method of `PositionService`
- `create` method of `GuidedAddressSearchPreferences`.
- `create` method of `PositionService`
- `create` method of `TurnDetails`

### Fixed

- `getNextSpeedLimitVariation` method of `NavigationInstruction`
- `getLandmarks`, `getCategoryCount`, `getStoreIdAt` and `removeAllStoreCategories` methods of `LandmarkStore`
- `getPartArea` method and `area` getter of `Marker`
- `lowEndCPUOptimizations` getter and setter of `MapViewExtension`
- `getCategory` and `hasCategories` methods of `OverlayInfo`
- `getDistanceOnRoute` method of `RouteBase`
- `captureImage` method of `GemView`
- `customizeDefPositionTracker` method of `MapSceneObject`
- `imageSize` field of `MarkerCollectionRenderSettings` breaking alignment


## [2.5.0] - 2024-09-26

### Added

- `importLog` method of `RecorderBookmarks`
- `setParallelDownloadsLimit` method of `ContentStore`
- `registerOnMapViewMoveStateChanged` method of `GemMapController`
- `centerOnAreaRect` method of `GemView`
- `registerLandmarkStore` method of `LandmarkStoreService`
- `removeLandmarkStore` method of `LandmarkStoreService`
- `updateLandmark` method of `LandmarkStore`
- `clear` method of `MarkerCollection`
- `delete` method of `MarkerCollection`
- `getPointsGroupHComponents` method of `MarkerCollection`
- `getPointsGroupHead` method of `MarkerCollection`
- `indexOf` method of `MarkerCollection`
- `getBetterRouteTimeDistanceToFork` method of `NavigationService`
- `getNavigationInstruction` method of `NavigationService`
- `getNavigationParameters` method of `NavigationService`
- `getNavigationRoute` method of `NavigationService`
- `isNavigationActive` method of `NavigationService`
- `isSimulationActive` method of `NavigationService`
- `isTripActive` method of `NavigationService`
- `isTripActive` method of `NavigationService`
- `simulationMaxSpeedMultiplier` method of `NavigationService`
- `simulationMinSpeedMultiplier` method of `NavigationService`
- `diskSpaceUsedPerSecond` getter of `Recorder`
- `getAvailableDataTypes` getter of `Recorder`
- `recorderConfiguration` getter and setter of `Recorder`
- `status` getter of `Recorder`
- `chunkDurationSeconds`, `continuousRecording`, `overrideOverheatCheck`, `maxDiskSpaceUsed`, `keepMinSeconds`, `deleteOlderThanKeepMin`, `transportMode` fields of `RecorderConfiguration`
- `getTimeDistanceCoordinateOnRoute` method of `RouteBase`
- `isCurrentThreadMainThread` getter of `SdkSettings`
- overload for `==` operator and `hashCode` method for `BikeProfileElectricBikeProfile`, `BuildTerrainProfile`, `DepartureHeading`, `ElectricBikeProfile`, `EVProfile`, `CarProfile`
- `EntranceLocations` class
- `PTRoute` class
- `PTRouteSegment` class
- `PTRouteInstruction` class
- `PTBuyTicketInformation` class
- `PTAlert` class
- `RouteTrafficEvent` class

### Changed

- constructors of classes which should not be directly instantiated by the user are now private
- classes consisting only of static methods are abstract (`RouteBase`, `RoutingService`, `MapDetails`, `LandmarkStoreService`, `GuidedAddressSearchService`, `GenericCategories`, `SearchService`, `NavigationService`)
- all methods from `NavigationService` are static
- `getNextAddressDetailLevel` method of `GuidedAddressSearchService` returns `List<AddressDetailLevel>` instead of `List<int>`
- `getStoreContentList` method of `ContentStore` returns `Pair<List<ContentStoreItem>, bool>` instead of `Pair<ContentStoreItemList, bool>` and is now static
- `waypoints` getter of `RouteBase` transformed to `getWaypoints` method and takes a parameter of type `GetWaypointsOptions`
- `startRecording` and `stopRecording` methods of `Recorder` return `GemError` instead of `int`
- `exportLog` method of `RecorderBookmarks` returns `GemError` instead of `int`
- `id` getter from all enum extensions no longer return `-1` on default case
- `fromId` method of `ContactInfoFieldTypeExtension` no longer returns nullable `ContactInfoFieldType`, throwing exception on invalid input
- `isProtected` and `isUploaded` members of `LogMetadata` are getters instead of methods
- `MarkerCollectionRenderSettings` extends `MarkerRenderSettings`
- `TerrainProfile`, `ClimbSection`, `SurfaceSection`, `RoadTypeSection`, `SteepSection` and related enums moved to a new file

### Removed

- `create` method from classes where it is not appropriate
- empty classes (`ClimbSectionList`, `RouteCollection`, `MapViewRouteCollection`)
- `first` and `last` values from `ContentType` enum

### Fixed

- caching mechanism of Marker images
- `getId` method of `LandmarkCategory`
- `route` getter of `LogMetadata`
- `recorderConfiguration` getter of `Recorder`
- `current` getter of `GenericIterator`
- `buildTerrainProfile` field of `RoutePreferences` returned by `preferences` getter of `RouteBase` incorrect value


## [2.4.0] - 2024-09-04

### Added

- `addList` method of `MapViewMarkerCollections`
- `devicePixelSize` method of `GemMapController`
- `centerOnRoutePart` method of `MapView`
- `LandmarkJson` and `MarkerJson` for optimization
- labels for `Markers`

### Removed

- `MarkerSketches` class and example

### Changed

- Moved some methods to safecall
- Callback functions with multiple parameters now have named parameters
- `remove` method of `MapViewMarkerCollections` renamed to `removeAt`

### Fixed

- `getRenderSettings` method of `MapViewRoutesCollection` returns `RouteRenderSettings` with correct values previously set with `setRenderSettings` method
- `cursorSelectionMarkers` method of `GemView`
- `searchInArea` method of `SearchService`
- `getCoordinates` method of `Marker`
- `labelTextSize` and `labelTextColor` of `MarkerRenderSettings`
- `indexOf` method of `MapViewMarkerCollections`
- `setRenderSettings` method of `MapViewMarkerCollections`
- `contains` method of `MapViewMarkerCollections`
- `isSketches` method of `MapViewMarkerCollections`
- `removeAt` method of `MapViewPathCollection`
- zoom out effect when tapping fast on markers


## [2.3.1] - 2024-08-09

### Added

- More fields in `RouteRenderSettings`
- `NavigationStatus` enum
- Caching mechanism for images in `SdkSettings` class and `getImageById` method

### Changed

- Some fields in `MarkerRenderSettings` are no longer `nullable`
- `routes` parameter of `centerOnRoutes` is named and `nullable`
- `navigationStatus` method of `NavigationInstruction` class returns `NavigationStatus`
- `DataSource` methods return `GemError` instead of `int`

### Fixed

- `setMapStyleByPath` method of `MapViewPreferences` class
- `enableOverlay` and `disableOverlay` methods of `OverlayService` class
- `centerOnRoutes` method of `MapView` class
- waypoints getters of `RouteSegment` and `RouteBase` classes
- `removeLandmarkStoreId` method of `LandmarkStoreCollection` class
- `RouteRenderSettings` constructor


## [2.3.0] - 2024-08-05

### Added

- `setMapStyle` with binary data
- `removeAllLandmarks` method of `LandmarkStore` class
- `ExternalInfo` class
- `MapSceneObject` class
- `addList` method of `MarkerSketches` class
- `MarkerSketches` example
- `enableTouchGestures` method of `MapViewPreferences` class
- More values to `RoadModifier`
- `RoadModifierExtension`

### Changed

- return type of method `hasChargeStop` of `EVRouteSegment` class from `int` to `bool`
- `cursorSelectionOverlays` method returns `OverlayItem`
- `OverlayService` methods return `GemError` instead of `int`
- `LandmarkStoreCollection` methods return `GemError` instead of `int`
- `MapViewMarkerCollections` methods return `GemError` instead of `int`
- `FollowPositionPreferences` methods return `GemError` instead of `int`
- `setImageFromIconId` method to `setImageFromIcon`. `GemIcon` parameter instead of `int`
- `ContentStoreItemStatus.downloadWaitingNetwork` ID to 5
- `DataType.gyroscope` ID to 1024
- `PositionRoadModifier` to `RoadModifier`
- `AnimationExtension` to `AnimationTypeExtension`
- `FixQualityExtension` to `PositionQualityExtension`
- `PositionRoadModifier` to `RoadModifier`
- `EMarkerLabelingModeExtension` to `MarkerLabelingModeExtension`
- `ERouteRenderOptionsExtension` to `RouteRenderOptionsExtension`
- `GenericCategoriesIDsExtension` to `GenericCategoriesIdExtension`
- `mapDetailsQuality` getter of `MapViewPreferences` returns `MapDetailsQualityLevel` instead of `int`
- More methods throws exception instead of `String`

### Fixed

- `getMapViewRoute`, `getLabel`, `setLabel` methods of `MapViewRoutesCollection` class
- `add`, `update`, `addTrips`, `sortOrder` methods of `RouteBookmarks`
- `fromJson` method of `EVProfile` class
- `clear` method of `MapViewMarkerCollections` class
- `timeStamp` getter of `Landmark` class
- `releaseView` Android native behaviour
- `setMapRotationMode` IOS native behaviour


## [2.2.0] - 2024-07-10

### Added

- `getRouteStatus` and `CalculationRunning` methods of `RoutingService` class
- `getRoadInfoImage`, `getRoadInfo`, `hasRoadInfo`, `isExit` and `getExitDetails` methods of `Route Instruction` class,
- `getExtraInfo`, `setExtraInfo`, `setRouteListener` and `getRouteListener` methods of `Route` class
- `isCalculationRunning`, `getRouteStatus` methods of `RoutingService` class
- `verifyAppAuthorization` method of `SDKSettings` class

### Changed

- replaced `Time` object with `DateTime` dart object in following methods: get and set timeStamp for `Landmark` class, get timeStamp for `Route` object, get timeStamp for `RoutingPreferences` class

### Fixed

- `altitude` field of `GemPosition` class
- `geographicArea` method of `Landmark` class could cause app freeze


## [2.1.0] - 2024-06-17

### Added

- `PositionService` custom data source
- `uncategorizedLandmarkCategId` and `invalidLandmarkCategId` constants
- `getLogMetadata` method of `RecorderBookmarks` class and `LogMetadata` class
- `EVRoute` methods
- `SearchPreferences` overlays
- `SignpostItem` class
- `getTimeDistanceCoordinates` and `getWaypointsVia` methods of `Route` class
- `MapCamera` methods
- `GeographicArea` classes and methods
- `OverlayService` class and `getAvailableOverlays` method
- `captureAsImage` method of `MapController` class [iOS only]
- `getLatestOnlineMapVersion` method of `MapDetails` class

### Changed

- `selectMapObjects` method has been replaced with `setCursorScreenPosition`
- `asyncGetContentStoreList` and `asyncDownload` are now FFI methods
- images default size and format can be set with `setDefaultWidthHeightImageFormat` of `SdkSettings` class
- `getAbstractGeometry` method has a new parameter, `AbstractGeometryRenderSettings`
- `setCursorScreenPosition`, `skipAnimation`, `scroll`, `getHighlightArea` and `resetMapSelection` methods of `MapController` class are now non-async
- `setLiveDataSource` now returns GemError
- `segments` getter of `Route` class returns `List<RouteSegment>` instead of `RouteSegmentList`
- `getPath` method of `Route` class now returns null path for invalid start and/or end instead of a Path with empty coordinates list
- `getTimeDistance` now has a bool parameter `activePart`

### Fixed

- `cancelSearch` issue which caused `onCompletedCallback` to not be called with `GemError.canceled`
- `polygonGeographicArea` getter of `Route` class
- `getRealisticNextTurnImage` method and `getTurnImage` of `Route` class
- `getCoordinatesAtPercent` static method of `Path` class
- `trafficEvents` method for `Route`
- `toEVRoute` method of `Route` class
- `routeTrack` getter of `Route` class
- `exportAs` method of `Path` class
- `cloneReverse` method of `Path` class
- `cloneStartEnd` method of `Path` class
- `getWaypoints` method of `Path` class
- `getElevationSamples` method of `RouteTerrainProfile` class behavior when callind with countSamples = 1
- `SignPostDetails` class getters
- `waypoints` getter of `RouteSegment` class
- `abstractGeometry` getter of `TurnDetails` class
- `containsLandmark` method of `LandmarkStore` class
- `getCategoryById` method of `LandmarkStore` class now returns null object for an invalid id
- `getLandmarks` method of `LandmarkStore` class now returns all landmarks for an unspecified categoryId
- `getLandmarkStoreById` method of `ContentStoreService` class now returns null object for an invalid id
- `Map` widget issues on Android which caused map to overlap other UI elements when rotating the device or opening a webview page over the one with the map
- `isFollowingPosition` getter of `MapController` class
- `accuracyCircleVisibility` getter and setter of `MapViewPreferences` class
- `getFieldName`, `getFieldValue`, `getFieldType` methods of `ContanctInfo` class when calling with an invalid index
- `getAllowOffboardServiceOnExtraChargedNetwork` method of `SdkSettings` class
- `getContourGeographicArea` method of `Landmark` class
- `extraInfo` getter of `Landmark` class


## [2.0.0] - 2024-05-22

### Added

- `releaseNative` method
- `RouteRenderSettings` optional parameter for `add` method of `MapViewRouteCollection`
- Map creation parameters: initial coordinates, zoomLevel, area and appAuthorization
- `Marker` class that allows drawing user defined polygons/polylines on the map
- `refreshContentStore` method
- `getContentParameters` method for `ContentStoreItem`

### Changed

- Imports
- Replaced methods with `get` and `set` prefixes with Dart get and set
- Renamed various members to match camelCase standard
- Replaced `create` factory with default constructor for multiple classes
- Multiple methods are now non-async
- SDK initialization changed from `GemKitPlatfor.instance.loadNative()` to `GemKit.initize()`
  - `appAuthorization` is now a parameter of `GemKit.initize()`
- `setAllowConnection` of `SdkSettings` has now callback parameters of `OffboardListener` instead of `OffboardListener` object
- `update` method of `ContentUpdater` has now `onStatusUpdated` and `onProgressUpdate` parameters instead of `ProgressListener`
- `GemAnimation` has now `onCompleted` parameter instead of `ProgressListener`
- Replaced `ProgressListener` with `TaskHandler`
- Replaced error type from int to `GemError` enum
- Replaced `Rgba` with `Color`
- Replaced `width` and `height` image parameters with `Size`
- Replaced `LandmarkList`, `RouteList`, `ContentStoreItemList`, `LandmarkCategoryList` with Dart lists
- Added named parameters for some methods
- Renamed enums to match Dart standard

### Fixed

- `getImage`, `setImage`, `setExtraImage` methods of `Landmark`
- `ContactInfo` class
- `centerOnArea` of `GemMapController` class
- set and get language for `SdkSettings`
- Check against null the MapView, when activity is paused / resumed


## [1.9.0] - 2024-04-02

### Added

- Address Search
- Offboard Listener
- Content Updater for ContentStore
- `dispatchonmainThread` on safecallObject
- `canDoAutoUpdate` flag for offboardlistener constructor
- safe call for `gem_path` methods
- compare operator in Version class
- `dispatchOnMainThread` flag defaults true for `clear` method in Routingservice
- AllStoreCategoriesList field in SearchPreferences
- ExternalRendererMarkers
- `setMapLanguage` method
- `setCameraFocus` and `getCameraFocus` methods
- `getMapVersion` method
- `getExtraImage` method

### Changed

- Refactor - modified more methods to non async
- Removed err == 0 check from `onNotifyComplete` method on Search results
- `setAllowAutoMapUpdate` flag defaults to false
- initSdk to initCoreSdk
- dispatchOnMainThread to true for route removal and setImageFromIcon
- NavigationProgressListener to ProgressListener in `setNavigationRoadBlock`
- `add` method from LandmarkStoreCollection
- Landmark and landmark store methods to safecall
- `setNavigationRoadBlock` to static method
- `setImage` method for landmark to safecall
- The way images can be obtained

### Fixed

- `SetName` method in Landmark
- speed issue for position on Android
- Version class
- Map update/Resource update listener(Works on Android)
- Version's minor and major fields
- ElectricBikeProfile
- `setBuildingVisibility` method
- `addStoreCategoryList` method


## [1.8.0] - 2024-01-30

### Added

- `appDidEnterBackground`, `appDidBecomeActive` methods
- `onAngleMapUpdate`, `alignNorthUp` methods
- `cursorSelectionStreets`, `cursorSelectionOverlayItems` methods
- `getImageById`, `getImageUId`, `getImage`, `getImageByBitmap` methods
- `clearAllButMainRoute`, `centerOnMapRoutes` method
- `hasCoordinates`, `hasSpeed` methods
- `getNearestLocation` method
- arguments for `asyncDownload` method
- `addRoute` method
- `getOsVersion`
- automatic destructor
- `OffscreenBitmap` object
- position listener methods non async
- default values for `RoutePreferences`
- `GenericCategories` and `LandmarkListCategories` classes
- `FollowPositionPreferences`
- `[]` operator to `GemList`
- More methods in `RouteBookmarks`
- `routeRenderSettings` parameter when adding a route to view
- auto for `AndroidViewMode`
- check for calling methods before the Native is loaded

### Changed

- Made `LandmarkList` iterable
- Initialize the SDK earlier on Android
- Modified `cancelRoute` and `cancelNavigation` to non async
- Modified `centerOnArea`, `setCoordinates`, `centerOnRoutes` to non async
- Modified `removeLandmark` to non async
- Modified all `LandmarkStore` and `LandamrkStoreCollection` methods to non async
- Created a base class for lists ( `Iterable` )
- Made the getter for displayed routes non async
- Modified `getTurnInstruction` non async
- Made `cancelSearch` static
- Modified `ContentStoreItemList` to use GemList

### Fixed

- Activity lifecycle on Android
- Real position issue
- Path: clear and getArea issues
- Blackscreen issue on Android 12


## [Unreleased] - 2023-10-04

### Added

- More parameters to route preferences
- `MinDuration` parameter for `Recorder`
- `onRouteUpdated` and `onBetterRouteDetected` methods
- `getAbstractGeometryUId` method

### Changed

- Modified cancel search method to non async

### Fixed

- `cancelRoute` issue
- `setLiveDataSource` error throw


## [1.5.6] - 2023-09-06

### Added

- Content Store: Map Styles, Human Voices, Offline Maps
- Weather Service: Current Forecast, Hourly Forecast, Daily Forecast
- New map gesture: Long Press
- Recorder: Record route, export as .GPX
- SDK Settings: Unit System, Language, Set Navigation Voice, Allow Offboard Service on Charged Network
- Map Details: Get Country Flag by ISO code
- Map Styles: Apply Map Style, Get Current Map Style

### Changed

- SDK Settings methods are now static and non-async

### Fixed

- Fixed an issue where screen rotate on Android would cause loss of connection to SDK


## [1.5.2] - 2023-08-09

### Added

- Draw route
- Route preferences
- Route profile sections: Surfaces, Road types, Climb
- Route path
- WGS to screen coordinates converter

### Changed

- Modified Landmark to use direct FFI calls for getters.
- Bug fixing and improvements


## [1.5.1] - 2023-08-01

### Changed

- Bug fixing and improvements


## [1.5.0] - 2023-07-25

### Added

- Distance between 2 coordinates
- Image for landmarks
- Landmark selection on map
- `SearchService`: `searchInArea` & `searchAroundPosition`
- Route segments & route instructions
- `MapViewRouteCollection` methods
- Center camera on routes
- Abstract geometry image for navigation instructions
- Navigation events callback: new instruction, waypoint reached & destination reached
- Voice instructions with text-to-speech
- Animations for center camera on coordinates & follow position
- `PositionService`
- Follow position enter/exit events
- `LandmarkStoreContent`: custom stores
- `LandmarkStoreContent`: add, remove & contains methods


## [1.4.6] - 2023-07-22

### Changed

- Bug fixing and improvements


## [1.4.5] - 2023-07-18

### Changed

- Bug fixing and improvements


## [1.4.0] - 2023-07-13

### Added

- Start navigation simulation on route
- Cancel navigation
- Start follow position (for simulation only)
- Navigation instruction callback
- Landmark image
- Abstract geometry for navigation instructions
- Route time and distance


## [1.3.0] - 2023-07-07

### Added

- Activate highlight
- Deactivate highlight
- Route calculation
- Cancel route calculation
- Center camera on route


## [1.2.0] - 2023-07-05

### Added

- ExtraInfo field containing result distance, type, native name and English name

### Fixed

- Search working on Android and IOS


## [1.1.0] - 2023-07-04

### Changed

- Bug fixing and improvements


## [1.0.0] - 2023-06-30

Initial release
