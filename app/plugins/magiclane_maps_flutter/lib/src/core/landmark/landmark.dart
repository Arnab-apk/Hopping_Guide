// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/obj_type.dart';

/// Represents a predefined, permanent location with rich metadata.
///
/// A landmark contains structured information about a place such as its name, address, description,
/// geographic area (centroid and full boundary), categories (for example Gas Station or Shopping),
/// entrance locations, contact details, and optional media (icons or images). Landmarks are used
/// throughout the SDK for display, search, routing, and alarms.
///
/// ## Use cases
/// - Displaying points of interest on maps.
/// - Searching for nearby services or attractions.
/// - Routing based on specific landmarks.
///
/// ## See also:
/// - [LandmarkStore] — for creating and managing collections of landmarks.
/// - [LandmarkCategory] — for the categories used to classify landmarks.
///
/// {@category Landmarks}
class Landmark extends GemAutoreleaseObject {
  factory Landmark() {
    return Landmark._create();
  }

  /// Creates a landmark tied to specific geographic coordinates.
  ///
  /// Use this constructor to create a new landmark and immediately set its centroid coordinates.
  ///
  /// ## Parameters
  ///
  /// - [latitude]: The latitude of the landmark's centroid in decimal degrees.
  /// - [longitude]: The longitude of the landmark's centroid in decimal degrees.
  factory Landmark.withLatLng({
    required final double latitude,
    required final double longitude,
  }) =>
      Landmark()
        ..coordinates = Coordinates(latitude: latitude, longitude: longitude);

  /// Creates a landmark from an existing [Coordinates] object.
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: The [Coordinates] instance that defines the landmark's centroid.
  factory Landmark.withCoordinates(final Coordinates coordinates) =>
      Landmark()..coordinates = coordinates;

  @internal
  Landmark.init(super.id);

  /// Retrieves the address information for this landmark.
  ///
  /// Some or all address fields may be empty depending on the source of the landmark data.
  ///
  /// Changes made to an [AddressInfo] do not automatically propagate to the
  /// associated [Landmark]. To apply changes, set the modified [AddressInfo]
  /// back on the landmark via [Landmark.address].
  ///
  /// ## Returns
  ///
  /// - [AddressInfo]: The address details associated with the landmark.
  AddressInfo get address {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getAddress',
    );

    return AddressInfo.fromJson(resultString['result']);
  }

  /// Retrieves the author or creator of this landmark's information.
  ///
  /// The field may be empty when the author is not specified by the data source.
  ///
  /// ## Returns
  ///
  /// - [String]: The author name, or an empty string if not available.
  String get author {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getAuthor',
    );

    return resultString['result'];
  }

  /// Returns the categories assigned to this landmark.
  ///
  /// Categories classify the landmark into predefined types (for example Gas Station,
  /// Shopping, etc.). A landmark can belong to zero or more categories.
  ///
  /// ## Returns
  ///
  /// - [List<LandmarkCategory>]: The list of categories for this landmark.
  List<LandmarkCategory> get categories {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getCategories',
    );

    return LandmarkCategoryList.init(resultString['result']).toList();
  }

  /// Retrieves contact information for this landmark.
  ///
  /// The returned [ContactInfo] may contain phone numbers, emails, URLs and textual
  /// descriptions. If you modify the returned object, assign it back to [contactInfo]
  /// to persist the change on the landmark.
  ///
  /// ## Returns
  ///
  /// - [ContactInfo]: Contact details associated with the landmark.
  ContactInfo get contactInfo {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getContactInfo',
    );

    return ContactInfo.init(resultString['result']);
  }

  /// Retrieves the contour geographic bounding rectangle for this landmark.
  ///
  /// Landmarks can have complex contours; this method returns a rectangle that bounds
  /// the contour. Use [relevantOnly] to request a reduced bounding box when available.
  ///
  /// ## Parameters
  ///
  /// - [relevantOnly]: If true, returns the relevant (smaller) contour bounding box when available;
  ///   otherwise returns the full contour bounding box.
  ///
  /// ## Returns
  ///
  /// - [RectangleGeographicArea]: A rectangle representing the contour's bounding box.
  RectangleGeographicArea getContourGeographicArea({
    final bool relevantOnly = true,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getContourGeograficArea',
      args: relevantOnly,
    );

    return RectangleGeographicArea.fromJson(resultString['result']);
  }

  /// Retrieves the centroid coordinates of this landmark.
  ///
  /// The centroid is used for distance calculations and map centering. For the landmark's
  /// full spatial extent use [geographicArea].
  ///
  /// ## Returns
  ///
  /// - [Coordinates]: The landmark's centroid coordinates.
  Coordinates get coordinates {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getCoordinates',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// Retrieves the description text for this landmark.
  ///
  /// The description may be localized depending on SDK language settings and can be empty.
  ///
  /// ## Returns
  ///
  /// - [String]: The description text, or an empty string when not available.
  String get description {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getDescription',
    );

    return resultString['result'];
  }

  /// Retrieves the entrance locations for this landmark.
  ///
  /// This returns an [EntranceLocations] object containing named entrance points and
  /// their access types (for example pedestrian or vehicle).
  ///
  /// ## Returns
  ///
  /// - [EntranceLocations]: The landmark's entrances and access types.
  EntranceLocations get entrances {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getEntrances',
    );

    return EntranceLocations.init(resultString['result']);
  }

  /// Retrieves the landmark's secondary (extra) image as raw bytes.
  ///
  /// The returned bytes may be null when no extra image exists. The caller is responsible
  /// for validating and decoding the bytes. For higher-level handling use [extraImg]
  /// which returns an [Img] wrapper.
  ///
  /// ## Parameters
  ///
  /// - [size]: Optional desired image size. If omitted, original size is used.
  /// - [format]: Optional [ImageFileFormat] describing preferred format.
  ///
  /// ## Returns
  ///
  /// - [Uint8List?]: Raw image bytes, or null when no image is available.
  ///
  /// ## See also:
  /// - [extraImg] for a higher-level image wrapper.
  Uint8List? getExtraImage({final Size? size, final ImageFileFormat? format}) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'LandmarkgetExtraImage',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
    );
  }

  /// Get the extra image as a [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getExtraImage] when you only need raw image bytes.
  ///
  /// ## Returns
  ///
  /// - [Img]: The extra image wrapper instance.
  Img get extraImg {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getExtraImg',
    );

    return Img.init(resultString['result']);
  }

  /// Sets the landmark's secondary image from an [Img] instance.
  ///
  /// ## Parameters
  ///
  /// - [value]: The [Img] instance to use as the extra image.
  set extraImg(Img value) {
    objectMethod(pointerId, 'Landmark', 'setExtraImg', args: value.pointerId);
  }

  /// Retrieves additional metadata associated with this landmark.
  ///
  /// The [ExtraInfo] object is a flexible key/value store used by the SDK to attach
  /// auxiliary information.
  /// If you modify the returned object you must reassign it to [extraInfo] to persist the changes.
  ///
  /// ## Returns
  ///
  /// - [ExtraInfo]: Key/value metadata for the landmark.
  ExtraInfo get extraInfo {
    try {
      final OperationResult resultString = objectMethod(
        pointerId,
        'Landmark',
        'getExtraInfo',
      );

      return ExtraInfo.fromList(resultString['result']);
    } catch (e) {
      return ExtraInfo();
    }
  }

  /// Retrieves the geographic area that represents the landmark's spatial extent.
  ///
  /// The returned [GeographicArea] can be a rectangle, circle, or polygon depending
  /// on the landmark data. The centroid is available via [coordinates].
  ///
  /// ## Returns
  ///
  /// - [GeographicArea]: The landmark's full geographic area.
  GeographicArea get geographicArea {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getGeographicArea',
    );

    switch (GeographicAreaTypeExtension.fromId(
      resultString['result']['type'],
    )) {
      case GeographicAreaType.rectangle:
        return RectangleGeographicArea.fromJson(resultString['result']);
      case GeographicAreaType.circle:
        return CircleGeographicArea.fromJson(resultString['result']);
      case GeographicAreaType.polygon:
        return PolygonGeographicArea.fromJson(resultString['result']);
      case GeographicAreaType.tileCollection:
        return RectangleGeographicArea.fromJson(resultString['result']);
      case GeographicAreaType.undefined:
        return RectangleGeographicArea.fromJson(resultString['result']);
    }
  }

  /// Returns the landmark's unique identifier within its landmark store.
  ///
  /// If the landmark is not associated with a store this getter returns -1.
  ///
  /// ## Returns
  ///
  /// - [int]: Landmark ID, or -1 when not assigned to a store.
  int get id {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getLandmarkId',
    );

    return resultString['result'];
  }

  /// Retrieves the primary (main) image for this landmark as raw bytes.
  ///
  /// This image is typically used as the icon shown on the map. If no image exists
  /// the result is null. For higher-level access use [img] which returns an [Img].
  ///
  /// ## Parameters
  ///
  /// - [size]: Optional desired size for the returned image.
  /// - [format]: Optional [ImageFileFormat] preference.
  ///
  /// ## Returns
  ///
  /// - [Uint8List?]: Raw image bytes, or null if not available.
  ///
  /// ## See also:
  ///
  /// - [img] for a higher-level image wrapper.
  Uint8List? getImage({final Size? size, final ImageFileFormat? format}) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'Landmark',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
    );
  }

  /// Get the image as a [Img].
  ///
  /// It is also the icon displayed on maps for this landmark.
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getImage] when you only need raw image bytes.
  ///
  /// ## Returns
  ///
  /// - [Img]: The primary image wrapper for this landmark.
  Img get img {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getImg',
    );

    return Img.init(resultString['result']);
  }

  /// Sets the landmark's primary image from an [Img] instance.
  ///
  /// It is also the icon displayed on maps for this landmark.
  ///
  /// ## Parameters
  ///
  /// - [value]: The [Img] instance to use as the primary image.
  set img(Img value) {
    objectMethod(pointerId, 'Landmark', 'setImg', args: value.pointerId);
  }

  /// Retrieves the unique identifier for the landmark's primary image.
  ///
  /// ## Returns
  ///
  /// - [int]: The image UID.
  ///
  /// ## See also:
  ///
  /// - [img] for a higher-level image wrapper.
  int get imageUid {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getImageUid',
    );

    return resultString['result'];
  }

  /// Returns the ID of the landmark store that contains this landmark.
  ///
  /// If the landmark is not attached to any store this returns -1.
  ///
  /// ## Returns
  ///
  /// - [int]: Landmark store ID, or -1 when not attached.
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] for retrieving the [LandmarkStore] instance.
  int get landmarkStoreId {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getLandmarkStoreId',
    );

    return resultString['result'];
  }

  /// Returns the type code of the landmark store this landmark belongs to.
  ///
  /// See [LandmarkStoreType] for the set of valid store type values.
  ///
  /// ## Returns
  ///
  /// - [int]: Store type code, or -1 on error.
  int get landmarkStoreType {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getLandmarkStoreType',
    );

    return resultString['result'];
  }

  /// Retrieves the display name of this landmark.
  ///
  /// The name may be localized according to the SDK language settings and can be empty.
  /// It is also the label shown on maps for this landmark.
  ///
  /// ## Returns
  ///
  /// - [String]: The landmark name, or an empty string when not set.
  String get name {
    try {
      final OperationResult resultString = objectMethod(
        pointerId,
        'Landmark',
        'getName',
      );

      return resultString['result'];
    } catch (e) {
      return '';
    }
  }

  /// Returns the provider identifier for this landmark's data source.
  ///
  /// ## Returns
  ///
  /// - [int]: The provider ID (see [MapProviderId]).
  int get providerId {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getProviderId',
    );

    return resultString['result'];
  }

  /// Returns the timestamp when this landmark was created or last updated.
  ///
  /// If a user-defined timestamp is not set, it typically reflects the insertion time
  /// into the landmark store. The returned value is in UTC.
  ///
  /// ## Returns
  ///
  /// - [DateTime]: The timestamp in UTC.
  DateTime get timeStamp {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getTimeStamp',
    );

    return DateTime.fromMillisecondsSinceEpoch(
      resultString['result'],
      isUtc: true,
    );
  }

  /// Sets the address information for this landmark.
  ///
  /// ## Parameters
  ///
  /// - [addr]: The [AddressInfo] instance to assign to the landmark.
  set address(final AddressInfo addr) {
    objectMethod(pointerId, 'Landmark', 'setAddress', args: addr);
  }

  /// Sets the author/creator name for this landmark.
  ///
  /// ## Parameters
  ///
  /// - [auth]: The author name string.
  set author(final String auth) {
    objectMethod(pointerId, 'Landmark', 'setAuthor', args: auth);
  }

  /// Sets the contact information for this landmark.
  ///
  /// ## Parameters
  ///
  /// - [contactInfo]: The [ContactInfo] instance with phone, email, URLs, etc.
  set contactInfo(final ContactInfo contactInfo) {
    objectMethod(
      pointerId,
      'Landmark',
      'setContactInfo',
      args: contactInfo.pointerId,
    );
  }

  /// Sets the centroid coordinates for this landmark.
  ///
  /// ## Parameters
  ///
  /// - [coords]: The [Coordinates] instance that defines the new centroid.
  set coordinates(final Coordinates coords) {
    objectMethod(
      pointerId,
      'Landmark',
      'setCoordinates',
      args: coords.toJson(),
    );
  }

  /// Sets the description for this landmark.
  ///
  /// ## Parameters
  ///
  /// - [desc]: The description text (may be empty).
  set description(final String desc) {
    objectMethod(pointerId, 'Landmark', 'setDescription', args: desc);
  }

  /// Sets the extra metadata for this landmark.
  ///
  /// The provided [ExtraInfo] may contain fields used internally for contour boxes,
  /// geographic area metadata or Wikipedia information. It is recommended to preserve those entries when
  /// updating to avoid losing auxiliary data.
  ///
  /// ## Parameters
  ///
  /// - [list]: The [ExtraInfo] instance to assign.
  set extraInfo(final ExtraInfo list) {
    objectMethod(
      pointerId,
      'Landmark',
      'setExtraInfo',
      args: list.toInputFormat(),
    );
  }

  /// Appends an extra information entry to the landmark's metadata.
  ///
  /// ## Parameters
  ///
  /// - [info]: A string containing the extra information to append.
  void addExtraInfo(String info) {
    objectMethod(pointerId, 'Landmark', 'addExtraInfo', args: info);
  }

  /// Finds the first extra info entry that begins with [startStr].
  ///
  /// The returned string will have leading non-alphanumeric characters trimmed.
  ///
  /// ## Parameters
  ///
  /// - [startStr]: Prefix string to search for.
  ///
  /// ## Returns
  ///
  /// - [String]: The first matching extra info entry with leading non-alphanumeric
  ///   characters removed, or an empty string when no match is found.
  String findExtraInfo(String startStr) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'findExtraInfo',
      args: startStr,
    );

    String result = resultString['result'];
    result = result.replaceFirst(RegExp(r'^[^a-zA-Z0-9]+'), '');
    return result;
  }

  /// Sets the geographic area that defines this landmark's extent.
  ///
  /// Use a [RectangleGeographicArea], [CircleGeographicArea] or [PolygonGeographicArea]
  /// as appropriate.
  ///
  /// ## Parameters
  ///
  /// - [area]: The [GeographicArea] instance describing the landmark boundary.
  /// If the area is empty, [GeographicArea.isDefault] will be `true`.
  set geographicArea(final GeographicArea area) {
    final Map<String, dynamic> serializedGeographicArea = area.toJson();
    serializedGeographicArea['type'] = area.type.id;

    objectMethod(
      pointerId,
      'Landmark',
      'setGeographicArea',
      args: serializedGeographicArea,
    );
  }

  /// Sets the primary image for this landmark from raw image data.
  ///
  /// ## Parameters
  ///
  /// - [imageData]: The image data as [Uint8List].
  /// - [format]: The image file format (defaults to PNG).
  ///
  /// ## See also:
  ///
  /// - [img] for a higher-level image wrapper.
  void setImage({
    required final Uint8List imageData,
    final ImageFileFormat format = ImageFileFormat.png,
  }) {
    final dynamic gemImage = GemKitPlatform.instance.createGemImage(
      imageData,
      format.id,
    );
    try {
      objectMethod(pointerId, 'Landmark', 'setImage', args: gemImage);
    } finally {
      GemKitPlatform.instance.deleteCPointer(gemImage, ObjType.gemImage);
    }
  }

  /// Sets the primary image for this landmark from a predefined icon.
  ///
  /// See [GemIcon] for available icons.
  ///
  /// ## Parameters
  ///
  /// - [icon]: [GemIcon] object representing the icon to use.
  void setImageFromIcon(final GemIcon icon) {
    objectMethod(pointerId, 'Landmark', 'setImageFromIconId', args: icon.id);
  }

  /// Sets the extra image for this landmark from raw image data.
  ///
  /// ## Parameters
  ///
  /// - [imageData]: The image data as [Uint8List].
  /// - [format]: The image file format.
  ///
  /// ## See also:
  ///
  /// - [extraImg] for a higher-level image wrapper.
  void setExtraImage({
    required final Uint8List imageData,
    required final ImageFileFormat format,
  }) {
    final dynamic gemImage = GemKitPlatform.instance.createGemImage(
      imageData,
      format.id,
    );
    try {
      objectMethod(pointerId, 'Landmark', 'setExtraImage', args: gemImage);
    } finally {
      GemKitPlatform.instance.deleteCPointer(gemImage, ObjType.gemImage);
    }
  }

  /// Sets the name for this landmark.
  ///
  /// ## Parameters
  ///
  /// - [name]: The landmark name as a string.
  set name(final String name) {
    objectMethod(pointerId, 'Landmark', 'setName', args: name);
  }

  /// Sets the provider ID for this landmark.
  ///
  /// See [MapProviderId] for available values.
  ///
  /// ## Parameters
  ///
  /// - [providerId]: The provider ID as an integer.
  set providerId(final int providerId) {
    objectMethod(pointerId, 'Landmark', 'setProviderId', args: providerId);
  }

  /// Sets the timestamp for this landmark.
  ///
  /// ## Parameters
  ///
  /// - [time]: [DateTime] object representing the timestamp.
  set timeStamp(final DateTime time) {
    objectMethod(
      pointerId,
      'Landmark',
      'setTimeStamp',
      args: time.millisecondsSinceEpoch,
    );
  }

  /// Retrieves the overlay item associated with this landmark.
  ///
  /// Returns an overlay item if the landmark originated from search results in overlays.
  ///
  /// ## Returns
  ///
  /// - [OverlayItem] object if available, otherwise null.
  OverlayItem? get overlayItem {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getOverlayItem',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return OverlayItem.init(resultString['result']);
  }

  /// Detaches this landmark from its associated landmark store.
  ///
  /// After detachment, [landmarkStoreId] will return -1.
  /// The landmark is no longer associated with store properties and is not removed from the store.
  void detachFromStore() {
    objectMethod(pointerId, 'Landmark', 'detachFromStore');
  }

  /// Checks if this landmark contains waypoint track data.
  ///
  /// ## Returns
  ///
  /// - True if track data is present, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [trackData] for retrieving the actual track data.
  bool get hasTrackData {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'waypointHasTrackData',
    );

    return resultString['result'];
  }

  /// Retrieves the waypoint track data for this landmark.
  ///
  /// Returns the track as a [Path] object.
  ///
  /// ## Returns
  ///
  /// - [Path] object containing the track data, or empty if none present.
  ///
  /// ## See also:
  ///
  /// - [hasTrackData] to check for the presence of track data.
  Path get trackData {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getWaypointTrackData',
    );

    return Path.init(resultString['result']);
  }

  /// Sets the waypoint track data for this landmark.
  ///
  /// Replaces the current track with the provided path.
  ///
  /// ## Parameters
  ///
  /// - [path]: [Path] object representing the new track data.
  set trackData(Path path) {
    objectMethod(
      pointerId,
      'Landmark',
      'setWaypointTrackData',
      args: path.pointerId,
    );
  }

  /// Reverses the sequence of points in the waypoint track data.
  ///
  /// Changes the order of the track points.
  void reverseTrackData() {
    objectMethod(pointerId, 'Landmark', 'reverseWaypointTrackData');
  }

  /// Truncates the track data between specified departure and destination coordinates.
  ///
  /// Set departure and destination to the same coordinate to create a circuit.
  ///
  /// ## Parameters
  ///
  /// - [departure]: [Coordinates] for the new track start.
  /// - [destination]: [Coordinates] for the new track end.
  void setTrackDataDepartureAndDestination(
    Coordinates departure,
    Coordinates destination,
  ) {
    objectMethod(
      pointerId,
      'Landmark',
      'setWaypointTrackDepartureAndDestination',
      args: <String, dynamic>{
        'first': departure.toJson(),
        'second': destination.toJson(),
      },
    );
  }

  static Landmark _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'Landmark'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final Landmark retVal = Landmark.init(decodedVal['result']);
    return retVal;
  }

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  Map<String, dynamic> getJson(
    final int landmarkImageWidth,
    final int landmarkImageHeight,
  ) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Landmark',
      'getJson',
      args: XyType<int>(x: landmarkImageWidth, y: landmarkImageHeight),
    );

    final Map<String, dynamic> retMap = <String, dynamic>{};
    final dynamic result = resultString['result'];

    retMap['name'] = result['name'];
    retMap['description'] = result['description'];
    retMap['author'] = result['author'];
    retMap['image'] = Uint8List.fromList(result['image'].cast<int>());
    retMap['extrainfo'] = result['extrainfo'];
    retMap['address'] = result['address'];
    final dynamic categorieslist = result['categories'];
    retMap['categories'] = LandmarkCategoryList.init(categorieslist);

    return retMap;
  }
}

/// Lightweight structure for serializing landmark information.
///
/// Use `LandmarkJson` to construct a data object that can be serialized and passed to
/// SDK import or bulk operations. This class focuses on storing commonly-used fields
/// (coordinates, name, description, author, image, address and extra info).
///
/// {@category Landmarks}
class LandmarkJson {
  LandmarkJson({
    required this.coordinates,
    this.name,
    this.description,
    this.author,
    this.image,
    this.extrainfo,
    this.address,
  });
  String? name;
  String? description;
  String? author;
  GemImage? image;
  ExtraInfo? extrainfo;
  AddressInfo? address;
  final Coordinates? coordinates;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (image != null) {
      json['image'] = image;
    }
    if (coordinates != null) {
      json['coordinates'] = coordinates;
    }
    if (name != null) {
      json['name'] = name;
    }
    if (description != null) {
      json['description'] = description;
    }
    if (author != null) {
      json['author'] = author;
    }
    if (extrainfo != null) {
      json['extraInfo'] = extrainfo!.toInputFormat();
    }
    return json;
  }
}
