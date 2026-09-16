// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/content_store.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/routing/ev_car_model.dart';
import 'package:magiclane_maps_flutter/weather.dart';
import 'package:meta/meta.dart';

/// A generic list of SDK objects.
///
/// The SDK user should not instantiate this class directly.
/// It is used as a base class for other classes and is also
/// used internally. The object collection is typically returned as a
/// `List<T>` to the API consumer.
///
/// @nodoc
class GemList<T> extends GemAutoreleaseObject implements Iterable<T> {
  // ignore: use_super_parameters
  GemList(
    dynamic pointerId,
    this._className,
    this._initializer, {
    this.dependencyId = -1,
  }) : super(pointerId);

  GemList.init(
    super._pointerId,
    this._className,
    this._initializer, {
    this.dependencyId = -1,
  });

  dynamic get _pointerId => super.pointerId;
  final int dependencyId;
  final T Function(dynamic) _initializer;
  final String _className;

  @override
  Iterator<T> get iterator => GenericIterator<T>(
    _pointerId,
    length,
    _className,
    _initializer,
    dependencyId,
  );

  @Deprecated('Use length getter instead')
  int size() {
    final OperationResult resultString = objectMethod(
      _pointerId,
      _className,
      'size',
      dependencyId: dependencyId,
    );

    return resultString['result'];
  }

  T operator [](final int index) => at(index);
  T at(final int position) {
    if (position > length - 1) {
      throw RangeError.range(position, 0, length - 1, 'Index out of bounds');
    } else {
      final OperationResult resultString = objectMethod(
        _pointerId,
        _className,
        'at',
        args: position,
        dependencyId: dependencyId,
      );

      return _initializer(resultString['result']);
    }
  }

  @override
  bool any(final bool Function(T element) test) {
    for (final T item in this) {
      if (test(item)) {
        return true;
      }
    }
    return false;
  }

  @override
  Iterable<R> cast<R>() {
    return toList().cast<R>();
  }

  @override
  bool contains(final Object? element) {
    for (final T route in this) {
      if (route == element) {
        return true;
      }
    }
    return false;
  }

  @override
  T elementAt(final int index) {
    if (index < 0 || index >= length) {
      throw RangeError.index(index, this);
    }
    return at(index)!;
  }

  @override
  bool every(final bool Function(T element) test) {
    for (final T item in this) {
      if (!test(item)) {
        return false;
      }
    }
    return true;
  }

  @override
  Iterable<R> expand<R>(
    final Iterable<R> Function(T element) toElements,
  ) sync* {
    for (final T element in this) {
      yield* toElements(element);
    }
  }

  @override
  T get first {
    if (isEmpty) {
      throw StateError('No elements');
    }
    return at(0)!;
  }

  @override
  T firstWhere(
    final bool Function(T element) test, {
    final T Function()? orElse,
  }) {
    for (final T item in this) {
      if (test(item)) {
        return item;
      }
    }
    if (orElse != null) {
      return orElse();
    }
    throw StateError('No matching element');
  }

  @override
  R fold<R>(
    final R initialValue,
    final R Function(R previousValue, T element) combine,
  ) {
    R result = initialValue;
    for (final T route in this) {
      result = combine(result, route);
    }
    return result;
  }

  @override
  Iterable<T> followedBy(final Iterable<T> other) {
    return <T>[...this, ...other];
  }

  @override
  void forEach(final void Function(T element) action) {
    // ignore: prefer_foreach
    for (final T item in this) {
      action(item);
    }
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length > 0;

  @override
  String join([final String separator = '']) {
    return toList().join(separator);
  }

  @override
  T get last {
    if (isEmpty) {
      throw StateError('No elements');
    }
    return at(length - 1)!;
  }

  @override
  T lastWhere(
    final bool Function(T element) test, {
    final T Function()? orElse,
  }) {
    for (int i = length - 1; i >= 0; i--) {
      final T item = at(i);
      if (test(item)) {
        return item;
      }
    }
    if (orElse != null) {
      return orElse();
    }
    throw StateError('No matching element');
  }

  @override
  int get length {
    final OperationResult resultString = objectMethod(
      _pointerId,
      _className,
      'size',
      dependencyId: dependencyId,
    );

    return resultString['result'];
  }

  @override
  T reduce(final T Function(T value, T element) combine) {
    if (isEmpty) {
      throw StateError('No elements');
    }
    T result = first;
    for (int i = 1; i < length; i++) {
      result = combine(result, at(i)!);
    }
    return result;
  }

  @override
  T get single {
    if (length != 1) {
      throw StateError('Not a single element');
    }
    return first;
  }

  @override
  T singleWhere(
    final bool Function(T element) test, {
    final T Function()? orElse,
  }) {
    T? result;
    for (final T item in this) {
      if (test(item)) {
        if (result != null) {
          throw StateError('More than one matching element');
        }
        result = item;
      }
    }
    if (result != null) {
      return result;
    }
    if (orElse != null) {
      return orElse();
    }
    throw StateError('No matching element');
  }

  @override
  Iterable<T> skip(final int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'Must be non-negative');
    }
    return <T>[for (int i = count; i < length; i++) at(i)];
  }

  @override
  Iterable<T> skipWhile(final bool Function(T value) test) {
    int index = 0;
    while (index < length && test(at(index))) {
      index++;
    }
    return skip(index);
  }

  @override
  Iterable<T> take(final int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'Must be non-negative');
    }
    return <T>[for (int i = 0; i < count && i < length; i++) at(i)];
  }

  @override
  Iterable<T> takeWhile(final bool Function(T value) test) {
    int index = 0;
    while (index < length && test(at(index))) {
      index++;
    }
    return take(index);
  }

  @override
  List<T> toList({final bool growable = true}) {
    final List<T> list = <T>[];
    // ignore: prefer_foreach
    for (final T item in this) {
      list.add(item);
    }
    return list;
  }

  @override
  Set<T> toSet() {
    final Set<T> set = <T>{};
    // ignore: prefer_foreach
    for (final T item in this) {
      set.add(item);
    }
    return set;
  }

  @override
  Iterable<T> where(final bool Function(T element) test) {
    return <T>[
      for (final T item in this)
        if (test(item)) item,
    ];
  }

  @override
  Iterable<U> whereType<U>() {
    return toList().whereType<U>();
  }

  @override
  Iterable<R> map<R>(final R Function(T e) toElement) {
    final List<R> result = <R>[];
    for (final T route in this) {
      result.add(toElement(route));
    }
    return result;
  }
}

/// A generic iterator for [GemList].
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class GenericIterator<T> implements Iterator<T> {
  GenericIterator(
    this._listId,
    this._currentSize,
    this._className,
    this._initializer,
    this._dependencyId,
  );
  final dynamic _listId;

  int _currentIndex = -1;
  final int _dependencyId;
  final int _currentSize;
  final String _className;
  final T Function(dynamic) _initializer;

  @override
  T get current {
    if (_currentIndex == -1) {
      throw StateError('No current element');
    }
    if (_currentIndex >= _currentSize) {
      throw StateError('No more elements');
    }

    final OperationResult resultString = objectMethod(
      _listId,
      _className,
      'at',
      args: _currentIndex,
      dependencyId: _dependencyId,
    );

    return _initializer(resultString['result']);
  }

  @override
  bool moveNext() {
    _currentIndex++;
    return _currentIndex < _currentSize;
  }
}

/// A [Landmark] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class LandmarkList extends GemList<Landmark> {
  factory LandmarkList() {
    return LandmarkList._create();
  }

  factory LandmarkList.fromJsonList(final List<LandmarkJson> landmarks) {
    return _fromLandmarkListJson(landmarks);
  }

  factory LandmarkList.fromList(final List<Landmark> landmarks) {
    final LandmarkList landmarkList = LandmarkList();
    landmarks.forEach(landmarkList.add);
    return landmarkList;
  }

  @internal
  LandmarkList.init(final dynamic id)
    : super(id, 'LandmarkList', (final dynamic data) => Landmark.init(data));

  static LandmarkList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'LandmarkList'}),
    );
    final Map<String, dynamic> decodedVal = jsonDecode(resultString);
    return LandmarkList.init(decodedVal['result']);
  }

  void add(final Landmark landmmark) {
    objectMethod(
      _pointerId,
      'LandmarkList',
      'push_back',
      args: landmmark.pointerId,
    );
  }

  static LandmarkList _fromLandmarkListJson(
    final List<LandmarkJson> landmarks,
  ) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{'class': 'LandmarkList', 'args': landmarks}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return LandmarkList.init(decodedVal['result']);
  }

  @override
  List<Landmark> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'LandmarkList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => Landmark.init(e))
        .toList(growable: growable);
  }
}

/// A [LandmarkPosition] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class LandmarkPositionList extends GemList<LandmarkPosition> {
  factory LandmarkPositionList() {
    return LandmarkPositionList._create();
  }

  factory LandmarkPositionList.fromList(
    final List<LandmarkPosition> landmarks,
  ) {
    final LandmarkPositionList landmarkList = LandmarkPositionList();
    landmarks.forEach(landmarkList.add);
    return landmarkList;
  }

  @internal
  LandmarkPositionList.init(final dynamic id)
    : super(
        id,
        'LandmarkPositionList',
        (final dynamic data) => LandmarkPosition.init(data),
      ) {
    super.registerAutoReleaseObject(id);
  }

  static LandmarkPositionList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'LandmarkPositionList'}),
    );
    final Map<String, dynamic> decodedVal = jsonDecode(resultString);
    return LandmarkPositionList.init(decodedVal['result']);
  }

  void add(final LandmarkPosition landmmark) {
    objectMethod(
      _pointerId,
      'LandmarkPositionList',
      'push_back',
      args: landmmark.pointerId,
    );
  }
}

/// A [OverlayItem] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class OverlayItemList extends GemList<OverlayItem> {
  factory OverlayItemList() {
    return OverlayItemList._create();
  }

  factory OverlayItemList.fromList(final List<OverlayItem> landmarks) {
    final OverlayItemList landmarkList = OverlayItemList();
    landmarks.forEach(landmarkList.add);
    return landmarkList;
  }

  OverlayItemList.init(final dynamic id)
    : super(
        id,
        'OverlayItemList',
        (final dynamic data) => OverlayItem.init(data),
      ) {
    super.registerAutoReleaseObject(id);
  }

  static OverlayItemList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'OverlayItemList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return OverlayItemList.init(decodedVal['result']);
  }

  void add(final OverlayItem overlayItem) {
    objectMethod(
      _pointerId,
      'OverlayItemList',
      'push_back',
      args: overlayItem.pointerId,
    );
  }

  @override
  List<OverlayItem> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'OverlayItemList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => OverlayItem.init(e))
        .toList(growable: growable);
  }
}

/// A [Route] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class RouteList extends GemList<Route> {
  factory RouteList() {
    return RouteList._create();
  }

  factory RouteList.fromList(final List<Route> routes) {
    final RouteList routeList = RouteList._create();
    routes.forEach(routeList.add);
    return routeList;
  }

  @internal
  RouteList.init(final int id)
    : super(id, 'RouteList', (final dynamic data) => Route.init(data)) {
    super.registerAutoReleaseObject(id);
  }

  static RouteList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'RouteList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return RouteList.init(decodedVal['result']);
  }

  void add(final Route route) {
    objectMethod(_pointerId, 'RouteList', 'push_back', args: route.pointerId);
  }

  @override
  List<Route> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'RouteList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => Route.init(e))
        .toList(growable: growable);
  }
}

/// A [RouteInstruction] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class RouteInstructionList extends GemList<RouteInstruction> {
  factory RouteInstructionList() {
    return RouteInstructionList._create();
  }

  @internal
  RouteInstructionList.init(final int id)
    : super(
        id,
        'RouteInstructionList',
        (final dynamic data) => RouteInstruction.init(data),
      ) {
    super.registerAutoReleaseObject(id);
  }
  static RouteInstructionList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'RouteInstructionList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return RouteInstructionList.init(decodedVal['result']);
  }

  @override
  List<RouteInstruction> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'RouteInstructionList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => RouteInstruction.init(e))
        .toList(growable: growable);
  }
}

/// A [RouteSegment] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class RouteSegmentList extends GemList<RouteSegment> {
  factory RouteSegmentList() {
    return RouteSegmentList._create();
  }

  @internal
  RouteSegmentList.init(final int id)
    : super(
        id,
        'RouteSegmentList',
        (final dynamic data) => RouteSegment.init(data),
      ) {
    super.registerAutoReleaseObject(id);
  }

  static RouteSegmentList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'RouteSegmentList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return RouteSegmentList.init(decodedVal['result']);
  }

  @override
  List<RouteSegment> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'RouteSegmentList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => RouteSegment.init(e))
        .toList(growable: growable);
  }
}

/// A [OverlayItemPosition] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class OverlayItemPositionList extends GemList<OverlayItemPosition> {
  factory OverlayItemPositionList() {
    return OverlayItemPositionList._create();
  }

  factory OverlayItemPositionList.fromList(
    final List<OverlayItemPosition> landmarks,
  ) {
    final OverlayItemPositionList landmarkList = OverlayItemPositionList();
    landmarks.forEach(landmarkList.add);
    return landmarkList;
  }

  OverlayItemPositionList.init(final dynamic id)
    : super(
        id,
        'OverlayItemPositionList',
        (final dynamic data) => OverlayItemPosition.init(data),
      ) {
    super.registerAutoReleaseObject(id);
  }

  static OverlayItemPositionList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'OverlayItemPositionList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return OverlayItemPositionList.init(decodedVal['result']);
  }

  void add(final OverlayItemPosition overlayItemPosition) {
    objectMethod(
      _pointerId,
      'OverlayItemPositionList',
      'push_back',
      args: overlayItemPosition.pointerId,
    );
  }

  @override
  List<OverlayItemPosition> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'OverlayItemPositionList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => OverlayItemPosition.init(e))
        .toList(growable: growable);
  }
}

/// A [MarkerMatch] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class MarkerMatchList extends GemList<MarkerMatch> {
  factory MarkerMatchList() {
    return MarkerMatchList._create();
  }

  MarkerMatchList.init(final dynamic id)
    : super(
        id,
        'MarkerMatchList',
        (final dynamic data) => MarkerMatch.init(data),
      ) {
    super.registerAutoReleaseObject(id);
  }

  static MarkerMatchList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'MarkerMatchList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return MarkerMatchList.init(decodedVal['result']);
  }

  @override
  List<MarkerMatch> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'MarkerMatchList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => MarkerMatch.init(e))
        .toList(growable: growable);
  }
}

/// A [Marker] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class MarkerList extends GemList<Marker> {
  factory MarkerList() {
    return MarkerList._create();
  }

  factory MarkerList.fromList(final List<MarkerList> landmarks) {
    final MarkerList landmarkList = MarkerList();
    landmarks.forEach(landmarkList.add);
    return landmarkList;
  }

  MarkerList.init(final dynamic id)
    : super(id, 'MarkerList', (final dynamic data) => Marker.init(data)) {
    super.registerAutoReleaseObject(id);
  }

  static MarkerList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'MarkerList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return MarkerList.init(decodedVal['result']);
  }

  void add(final MarkerList landmmark) {
    objectMethod(
      _pointerId,
      'MarkerList',
      'push_back',
      args: landmmark._pointerId,
    );
  }

  @override
  List<Marker> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'MarkerList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => Marker.init(e))
        .toList(growable: growable);
  }
}

/// A [TrafficEvent] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class TrafficEventList extends GemList<TrafficEvent> {
  factory TrafficEventList() {
    return TrafficEventList._create();
  }

  @internal
  TrafficEventList.init(final int id)
    : super(
        id,
        'TrafficEventList',
        (final dynamic data) => TrafficEvent.init(data),
      ) {
    super.registerAutoReleaseObject(id);
  }

  static TrafficEventList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{'class': 'TrafficEventList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return TrafficEventList.init(decodedVal['result']);
  }

  @override
  List<TrafficEvent> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'TrafficEventList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => TrafficEvent.init(e))
        .toList(growable: growable);
  }
}

/// A [LandmarkCategory] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class LandmarkCategoryList extends GemList<LandmarkCategory> {
  factory LandmarkCategoryList() {
    return LandmarkCategoryList._create();
  }

  @internal
  LandmarkCategoryList.init(final dynamic id)
    : super(
        id,
        'LandmarkCategoryList',
        (final dynamic data) => LandmarkCategory.init(data),
      );

  static LandmarkCategoryList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'LandmarkCategoryList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return LandmarkCategoryList.init(decodedVal['result']);
  }

  void add(final LandmarkCategory category) => objectMethod(
    _pointerId,
    'LandmarkCategoryList',
    'push_back',
    args: category.pointerId,
  );

  @override
  List<LandmarkCategory> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'LandmarkCategoryList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => LandmarkCategory.init(e))
        .toList(growable: growable);
  }
}

/// A [ContentStoreItem] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class ContentStoreItemList extends GemList<ContentStoreItem> {
  factory ContentStoreItemList({final dynamic id = 0, final int mapId = 0}) {
    if (id == 0 && mapId == 0) {
      return ContentStoreItemList._create();
    } else {
      return ContentStoreItemList.init(id);
    }
  }

  @internal
  ContentStoreItemList.init(final dynamic id)
    : super(
        id,
        'ContentStoreItemList',
        (final dynamic data) => ContentStoreItem.init(data),
      );

  static ContentStoreItemList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'ContentStoreItemList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return ContentStoreItemList.init(decodedVal['result']);
  }

  @override
  List<ContentStoreItem> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'ContentStoreItemList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => ContentStoreItem.init(e))
        .toList(growable: growable);
  }
}

/// A [SignpostItem] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class SignpostItemList extends GemList<SignpostItem> {
  factory SignpostItemList() {
    return SignpostItemList._create();
  }

  @internal
  SignpostItemList.init(final int id)
    : super(
        id,
        'SignpostItemList',
        (final dynamic data) => SignpostItem.init(data),
      ) {
    super.registerAutoReleaseObject(id);
  }
  static SignpostItemList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'SignpostItemList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return SignpostItemList.init(decodedVal['result']);
  }

  @override
  List<SignpostItem> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'SignpostItemList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => SignpostItem.init(e))
        .toList(growable: growable);
  }
}

/// A [Img] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class ImageList extends GemList<Img> {
  factory ImageList() {
    return ImageList._create();
  }

  factory ImageList.fromList(final List<Img> images) {
    final ImageList imageList = ImageList();
    images.forEach(imageList.add);
    return imageList;
  }

  @internal
  ImageList.init(final dynamic id)
    : super(id, 'ImageList', (final dynamic data) => Img.init(data));

  static ImageList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'ImageList'}),
    );
    final Map<String, dynamic> decodedVal = jsonDecode(resultString);
    return ImageList.init(decodedVal['result']);
  }

  void add(final Img img) {
    objectMethod(_pointerId, 'ImageList', 'push_back', args: img.pointerId);
  }

  @override
  List<Img> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      _pointerId,
      'LandmarkList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => Img.init(e))
        .toList(growable: growable);
  }
}

/// A [LocationForecast] list.
///
/// Should not be used directly by SDK consumers.
///
/// @nodoc
class LocationForecastList {
  factory LocationForecastList() {
    return LocationForecastList._create();
  }

  factory LocationForecastList._create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'LocationForecastList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return LocationForecastList.init(decodedVal['result']);
  }

  @internal
  LocationForecastList.init(final int id) : _id = id;
  final dynamic _id;
  dynamic get id => _id;

  List<LocationForecast> get json {
    final OperationResult result = objectMethod(
      _id,
      'LocationForecastList',
      'getJson',
    );
    final List<dynamic> listJson =
        result['result'] as List<dynamic>? ?? const <dynamic>[];
    final List<LocationForecast> retList = listJson
        .map(
          (final dynamic categoryJson) =>
              LocationForecast.fromJson(categoryJson),
        )
        .toList();
    return retList;
  }

  void dispose() {
    GemKitPlatform.instance.callDeleteObject(
      jsonEncode(<String, dynamic>{'class': 'LocationForecastList', 'id': _id}),
    );
  }
}

/// A list of [EVCarModel] objects.
///
/// @nodoc
class EVCarModelList extends GemList<EVCarModel> {
  @internal
  EVCarModelList.init(final int id)
    : super(
        id,
        'EVCarModelList',
        (final dynamic data) => EVCarModel.init(data),
      ) {
    super.registerAutoReleaseObject(id);
  }

  @override
  List<EVCarModel> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      pointerId,
      'EVCarModelList',
      'toList',
    );

    return (result['result'] as List<dynamic>? ?? const <dynamic>[])
        .map((final dynamic e) => EVCarModel.init(e))
        .toList(growable: growable);
  }
}
