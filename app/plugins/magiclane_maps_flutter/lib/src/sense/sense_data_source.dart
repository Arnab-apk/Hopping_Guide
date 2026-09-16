// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/camera_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/sense_data_impl.dart';

/// Provides access to sensor and log data from various sources.
///
/// A [DataSource] represents a provider of sensing data — this can be a live sensor feed,
/// a log file (playback), a simulated route, or an external source. It exposes methods
/// to start/stop the source, query available data types, push mock or custom data,
/// and register listeners to receive updates.
///
/// Use the [dataSourceType] property to determine whether the instance supports
/// playback operations and access [playback] when applicable.
///
/// {@category Sensor Data Source}
class DataSource extends GemAutoreleaseObject {
  // ignore: unused_element
  DataSource._() : super(-1);

  DataSource.init(super.id);

  /// Create a new external data source.
  ///
  /// Creates a [DataSource] that obtains data from an external source. The caller
  /// must provide the list of data types that the external source will produce.
  ///
  /// ## Parameters
  ///
  /// - [dataTypes]: The list of data types the external source provides. Must include [DataType.position].
  ///
  /// ## Returns
  ///
  /// - [DataSource?]: The created data source, or null if creation failed.
  static DataSource? createExternalDataSource(final List<DataType> dataTypes) {
    final List<int> intList = dataTypes
        .map((final DataType dataType) => dataType.id)
        .toList();
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'DataSourceContainer',
        'args': <String, Object>{
          'availableDataType': intList,
          'type': 'external',
        },
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);

    final int gemApiError = decodedVal['gemApiError'];

    if (GemErrorExtension.isErrorCode(gemApiError)) {
      return null;
    }

    final DataSource retVal = DataSource.init(decodedVal['result']);
    return retVal;
  }

  /// Create a new live data source.
  ///
  /// Creates a [DataSource] backed by live sensors. Use this when you need
  /// real-time sensor updates from the device.
  ///
  /// Requires appropriate permissions to access device sensors.
  ///
  /// ## Returns
  ///
  /// - [DataSource?]: The created live data source, or null if creation failed.
  static DataSource? createLiveDataSource() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'DataSourceContainer',
        'args': <String, String>{'type': 'live'},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);

    final int gemApiError = decodedVal['gemApiError'];

    if (GemErrorExtension.isErrorCode(gemApiError)) {
      return null;
    }

    final DataSource retVal = DataSource.init(decodedVal['result']);
    return retVal;
  }

  /// Create a log-based data source from a log file.
  ///
  /// Opens the specified log file for playback as a DataSource. Supported formats
  /// include GPX and other common trace formats; `.gm` proprietary log files are not supported here.
  ///
  /// ## Parameters
  ///
  /// - [logPath]: Path to the log file to use for playback.
  ///
  /// ## Returns
  ///
  /// - [DataSource?]: The created playback data source, or null if the file could not be opened.
  static DataSource? createLogDataSource(final String logPath) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'DataSourceContainer',
        'args': <String, String>{'type': 'log', 'path': logPath},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);

    final int gemApiError = decodedVal['gemApiError'];

    if (GemErrorExtension.isErrorCode(gemApiError)) {
      return null;
    }

    final DataSource retVal = DataSource.init(decodedVal['result']);
    return retVal;
  }

  /// Create a simulated data source from a [Route].
  ///
  /// The returned [DataSource] will simulate sensor data based on the provided route
  /// and can be used for testing or replay scenarios.
  ///
  /// Usually simulation on a given route is done via the [NavigationService.startSimulation] method.
  ///
  /// ## Parameters
  ///
  /// - [route]: The [Route] to simulate.
  ///
  /// ## Returns
  ///
  /// - [DataSource?]: A simulation data source, or null if creation failed.
  static DataSource? createSimulationDataSource(final Route route) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'DataSourceContainer',
        'args': <String, dynamic>{
          'type': 'simulation',
          'routeId': route.pointerId,
        },
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);

    final int gemApiError = decodedVal['gemApiError'];

    if (GemErrorExtension.isErrorCode(gemApiError)) {
      return null;
    }

    final DataSource retVal = DataSource.init(decodedVal['result']);
    return retVal;
  }

  /// Start the data source.
  ///
  /// Begins producing data (live sampling or playback) depending on the data source type.
  /// Some data sources types are automatically started upon creation and calling this method has no effect.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - Other [GemError] values on failure.
  GemError start() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'start',
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Stop the data source.
  ///
  /// Stops sampling or playback. For some source types this operation may pause
  /// playback or perform a graceful shutdown of live sampling.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - Other [GemError] values on failure.
  GemError stop() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'stop',
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Whether the data source is stopped/paused.
  ///
  /// ## Returns
  ///
  /// - [bool]: True when the source is stopped or paused, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [start] - Starts the data source.
  /// - [stop] - Stops the data source.
  bool get isStopped {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'isStopped',
    );

    return resultString['result'];
  }

  /// The type of this data source.
  ///
  /// Indicates whether the data source provides live data (sensors/external)
  /// or playback/simulated data.
  ///
  /// ## Returns
  ///
  /// - [DataSourceType]: The data source type (for example, [DataSourceType.live] or [DataSourceType.playback]).
  DataSourceType get dataSourceType {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'getDataSourceType',
    );

    return DataSourceTypeExtension.fromId(resultString['result']);
  }

  /// Check whether the data source produces a specific data type.
  ///
  /// ## Parameters
  ///
  /// - [dataType]: The [DataType] to check for availability.
  ///
  /// ## Returns
  ///
  /// - [bool]: True if the data type is available, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [availableDataTypes] - Lists all data types provided by this source.
  bool isDataTypeAvailable(final DataType dataType) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'isDataTypeAvailable',
      args: dataType.id,
    );

    return resultString['result'];
  }

  /// Get a textual description for a data type produced by this source.
  ///
  /// Returns an empty string when the data type is not produced by this data source.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [DataType] for which the description is requested.
  ///
  /// ## Returns
  ///
  /// - [String]: A description of the data type, or an empty string if not available.
  String getDataTypeDescription(final DataType type) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'getDataTypeDescription',
      args: type.id,
    );

    return resultString['result'];
  }

  /// The list of data types this data source provides.
  ///
  /// ## Returns
  ///
  /// - [List<DataType>]: All available data types for this source.
  ///
  /// ## See also:
  ///
  /// - [isDataTypeAvailable] - Check if a specific data type is available.
  List<DataType> get availableDataTypes {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'getAvailableDataTypes',
    );

    final List<int> rawEnumValues = List<int>.from(resultString['result']);
    return rawEnumValues
        .map((final int id) => DataTypeExtension.fromId(id))
        .toList();
  }

  /// Retrieve the latest produced data for a specific data type.
  ///
  /// Returns the most recently produced [SenseData] for [type] or null if no
  /// data is available or an error occurred while retrieving it.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [DataType] to request.
  ///
  /// ## Returns
  ///
  /// - [SenseData?]: The latest data for the requested type, or null when none is available.
  ///
  /// ## See also:
  ///
  /// - [PositionService.position] - Get the latest position data.
  SenseData? getLatestData(final DataType type) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'getLatestData',
      args: type.id,
    );

    if (resultString['gemApiError'] != 0) {
      return null;
    }

    final dynamic result = resultString['result'];
    if (result != null) {
      return senseFromJson(result);
    } else {
      return null;
    }
  }

  /// Update the sensor configuration for a specific data type.
  ///
  /// Only [DataType.position] is currently respected by the implementation;
  /// other types may be ignored.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [DataType] to configure (defaults to [DataType.position]).
  /// - [config]: The [PositionSensorConfiguration] to apply.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success; other [GemError] values indicate failure.
  ///
  /// ## See also:
  ///
  /// - [getConfiguration] - Retrieves the current configuration for a data type.
  GemError setConfiguration({
    final DataType type = DataType.position,
    required final PositionSensorConfiguration config,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'setConfiguration',
      args: <String, Object>{'type': type.id, 'config': config.toJson()},
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Get the current sensor configuration for a data type.
  ///
  /// Modifies the configuration does not affect the data source until
  /// [setConfiguration] is called.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [DataType] for which the configuration will be returned.
  ///
  /// ## Returns
  ///
  /// - [PositionSensorConfiguration]: The current configuration for the requested type.
  ///
  /// ## See also:
  ///
  /// - [setConfiguration] - Updates the configuration for a data type.
  PositionSensorConfiguration getConfiguration(final DataType type) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'getConfiguration',
      args: type.id,
    );

    final dynamic result = resultString['result'];

    final Map<String, String> configMap = <String, String>{};
    for (final dynamic entry in result.entries) {
      final dynamic key = entry.key;
      final dynamic value = entry.value;
      configMap[key] = value as String;
    }
    return PositionSensorConfiguration.fromJson(configMap);
  }

  /// The origin of this data source.
  ///
  /// ## Returns
  ///
  /// - [Origin]: The origin enum describing where the data comes from.
  ///
  /// ## See also:
  ///
  /// - [dataSourceType] - The type of this data source.
  Origin get origin {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'getOrigin',
    );

    return OriginExtension.fromId(resultString['result']);
  }

  /// Access playback controls for playback-capable data sources.
  ///
  /// Playback is only available when [dataSourceType] equals [DataSourceType.playback].
  ///
  /// ## Returns
  ///
  /// - [Playback?]: The playback interface when available, otherwise null.
  Playback? get playback {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'getPlayback',
    );

    if (GemErrorExtension.isErrorCode(resultString['result'])) {
      return null;
    }
    return Playback.init(resultString['result']);
  }

  /// Set mock data for this data source.
  ///
  /// Useful for injecting custom [SenseData] into live data sources for testing
  /// or UI previews. Only data types supported by the source may be accepted.
  ///
  /// Only positions are currently supported for this method.
  /// Use [pushData] to inject other data types.
  ///
  /// ## Parameters
  ///
  /// - [senseData]: The [SenseData] to set as mock data.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - [GemError.notSupported] if mock data is not supported by this source or the provided type is not accepted.
  /// - Other [GemError] values on failure.
  GemError setMockData(final SenseData senseData) {
    if (senseData is! SenseDataImpl) {
      return GemError.invalidInput;
    }

    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'setMockData',
      args: <String, Object>{
        'type': senseData.type.id,
        'data': senseData.toJson(),
      },
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Check whether mock data is enabled for a given data type.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [DataType] to query.
  ///
  /// ## Returns
  ///
  /// - [bool]: True if mock data is active for the specified type, false otherwise.
  bool isMockData(final DataType type) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'isMockData',
      args: type.id,
    );

    return resultString['result'];
  }

  /// Whether this [DataSource] is backed by a real SDK instance.
  ///
  /// ## Returns
  ///
  /// - [bool]: True if the interface is an SDK instance, false otherwise.
  bool get isSDKInstance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'isSDKInstance',
    );

    return resultString['result'];
  }

  /// Push a [SenseData] instance into the data source.
  ///
  /// The data source might process or alter the data before it becomes visible
  /// via [getLatestData] or listener callbacks. Rapid successive calls may be ignored.
  ///
  /// ## Parameters
  ///
  /// - [senseData]: The [SenseData] to push. Must be a [SenseDataImpl] or [CameraImpl].
  ///
  /// ## Returns
  ///
  /// - [bool]: True if the data type is supported and the push was accepted, false otherwise.
  bool pushData(final SenseData senseData) {
    if (senseData is! SenseDataImpl && senseData is! CameraImpl) {
      ApiErrorServiceImpl.apiErrorAsInt = GemError.invalidInput.code;
      return false;
    }
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'pushData',
      args: (senseData as dynamic).toJson(),
    );

    return resultString['result'];
  }

  /// Register a [DataSourceListener] to receive updates for a specific data type.
  ///
  /// The listener's callbacks will be invoked with event-specific arguments. See
  /// [DataSourceListener] for the available callback signatures.
  ///
  /// ## Parameters
  ///
  /// - [listener]: The [DataSourceListener] to register.
  /// - [dataType]: The [DataType] to listen for.
  /// - [parameters]: Optional [ParameterList] with subscription preferences.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when the listener was successfully registered.
  /// - [GemError.invalidInput] if the [dataType] is not available (check [isDataTypeAvailable]).
  /// - Other [GemError] values on failure.
  ///
  /// ## See also:
  ///
  /// - [removeListener] - Unregister a listener for a specific data type.
  /// - [removeListenerAllDataTypes] - Unregister all listeners for a specific listener.
  GemError addListener({
    required final DataSourceListener listener,
    required final DataType dataType,
    final ParameterList? parameters,
  }) {
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'addListener',
      args: <String, dynamic>{
        'listener': listener.id,
        'datatype': dataType.id,
        if (parameters != null) 'preferences': parameters.pointerId,
      },
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Unregister a listener for a specific data type.
  ///
  /// ## Parameters
  ///
  /// - [listener]: The [DataSourceListener] to remove.
  /// - [dataType]: The [DataType] the listener was registered for.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when the listener was successfully unregistered.
  /// - [GemError.invalidInput] if no listener had previously been added for the specified type.
  /// - [GemError.notFound] if the listener could not be found for the specified type.
  ///
  /// ## Also see:
  ///
  /// - [addListener] - Register a listener for a specific data type.
  /// - [removeListenerAllDataTypes] - Unregister all listeners for a specific listener.
  GemError removeListener({
    required final DataSourceListener listener,
    required final DataType dataType,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DataSourceContainer',
      'removeListener',
      args: <String, int>{'listener': listener.id, 'datatype': dataType.id},
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Unregister all listeners associated with a listener object.
  ///
  /// Removes all registered callbacks for the provided [DataSourceListener].
  ///
  /// ## Parameters
  ///
  /// - [listener]: The [DataSourceListener] to unregister for all data types.
  void removeListenerAllDataTypes(final DataSourceListener listener) {
    GemKitPlatform.instance.unregisterEventHandler(listener.id);

    objectMethod(
      pointerId,
      'DataSourceContainer',
      'removeListenerAll',
      args: listener.id,
    );
  }
}
