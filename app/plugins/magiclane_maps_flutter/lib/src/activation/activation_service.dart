// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/common/task_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Service for activating and managing product licenses for the Magic Lane SDK.
///
/// Used in Magic Lane products. Use **only if you are instructed to do so by
/// Magic Lane support or sales representatives**. The class is experimental
/// and may change without prior notice.
///
/// Provides methods to generate license keys, activate and deactivate products,
/// complete online/offline activation flows, query activation state and list
/// activations present on the device.
///
/// ## Note
///
/// This class is available only for custom builds of the Magic Lane SDK, when
/// [SdkSettings.capabilities] includes [SdkCapability.activation]. You can use
/// the [GateKeeperService] if the activation API is not available instead.
///
/// {@category Activation}
@experimental
abstract class ActivationService {
  /// Generates a new license key for the provided application and product.
  ///
  /// Requests a license key from the remote activation service for the given
  /// [applicationId] and optional [productId]. The operation is asynchronous
  /// and progress/results are delivered via the [onComplete] callback.
  ///
  /// The generated license key is a UUID v4 string that uniquely identifies
  /// the license for activation purposes.
  ///
  /// ## Parameters
  ///
  /// - [applicationId]: The application identifier for which the license key is created.
  /// - [productId]: The product identifier to bind the license to. Defaults to [ProductID.core].
  /// - [onComplete]: Callback invoked when the generation finishes. The callback
  ///   receives a [GemError] describing the result and a human-readable hint:
  ///   - [GemError.success]: Generation succeeded. The `hint` may contain the license key.
  ///   - [GemError.required]: Activation service was unreachable or no internet.
  ///   - [GemError.invalidInput]: Invalid input; check the `hint` for details.
  ///   - [GemError.noMemory]: Allocation failed on the platform.
  ///   - [GemError.networkFailed]: Network request failed to start.
  ///   - [GemError.missingCapability]: The activation API is not available on this platform/SDK build.
  ///
  /// ## Returns
  ///
  /// - [TaskHandler]: A task handle to observe or cancel the operation when the
  ///   request started successfully, otherwise `null` if the request could not be initiated.
  ///
  /// ## Throws
  ///
  /// - May throw an exception if the platform call fails unexpectedly.
  ///
  /// ## Also see:
  ///
  /// - [activate] - Activates a product using the supplied license key.
  /// - [SdkSettings] - Manage app tokens and other settings.
  static TaskHandler? generateLicenseKey({
    required final String applicationId,
    final String productId = ProductID.core,
    required final void Function(GemError error, String hint) onComplete,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete(GemErrorExtension.fromCode(err), hint);
    });

    final OperationResult resultString = staticMethod(
      'ActivationService',
      'generateLicenseKey',
      args: <String, dynamic>{
        'applicationId': applicationId,
        'productId': productId,
        'listener': progListener.id,
      },
    );

    if (resultString['gemApiError'] == GemError.missingCapability.code) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete(
        GemError.missingCapability,
        'Activation API is not available. Please check if your SDK build includes the activation capability and contact Magic Lane support for assistance.',
      );
      return null;
    }

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Activates a product using the supplied license key.
  ///
  /// Starts an activation flow for [productId] using [licenseKey] (a UUID v4).
  /// The operation is asynchronous and the [onComplete] callback reports final
  /// status and a hint string with supplemental information.
  ///
  /// ## Parameters
  ///
  /// - [applicationId]: The application identifier owning the activation.
  /// - [licenseKey]: The license key (UUID v4) used to identify the activation.
  ///   Use the key obtained from [generateLicenseKey] or provided by Magic Lane.
  /// - [productId]: The product identifier to activate. Defaults to [ProductID.core].
  /// - [onComplete]: Callback invoked on completion. The callback receives:
  ///   - [GemError.success]: Activation succeeded.
  ///   - [GemError.required]: No internet; try again or complete the activation offline.
  ///     Follow the steps from the manual for manual offline activation.
  ///   - [GemError.invalidInput]: Invalid input; check the `hint` for details.
  ///   - [GemError.io]: IO error when accessing the license file.
  ///   - [GemError.noMemory]: Allocation failed on the platform.
  ///   - [GemError.networkFailed]: Network request failed to start.
  ///   - [GemError.missingCapability]: The activation API is not available on this platform/SDK build.
  ///   - [GemError.connection]: Issue regarding connection between Magic Lane services. Please try again later.
  ///
  /// ## Returns
  ///
  /// - [TaskHandler]: A task handle when the activation request started successfully, otherwise `null`.
  ///
  /// ## Also see:
  ///
  /// - [generateLicenseKey] - Generate a license key for activation.
  /// - [completeActivation] - Complete an activation that required manual steps.
  /// - [getActivationsForProduct] - List activations present on the device.
  /// - [deactivate] - Deactivates a product previously activated with a license key.
  /// - [SdkSettings] - Manage app tokens and other settings.
  static TaskHandler? activate({
    required final String applicationId,
    required final String licenseKey,
    final String productId = ProductID.core,
    required final void Function(GemError error, String hint) onComplete,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete(GemErrorExtension.fromCode(err), hint);
    });

    final OperationResult resultString = staticMethod(
      'ActivationService',
      'activate',
      args: <String, dynamic>{
        'applicationId': applicationId,
        'licenseKey': licenseKey,
        'productId': productId,
        'listener': progListener.id,
      },
    );

    if (resultString['gemApiError'] == GemError.missingCapability.code) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete(
        GemError.missingCapability,
        'Activation API is not available. Please check if your SDK build includes the activation capability and contact Magic Lane support for assistance.',
      );
      return null;
    }

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Deactivates a product previously activated with a license key.
  ///
  /// Initiates a deactivation request for [licenseKey] and [productId]. The
  /// asynchronous [onComplete] callback reports the final result and a `hint`
  /// string explaining errors or next steps.
  ///
  /// Do not confuse deactivation with deletion of an activation record on the device.
  /// Deactivation notifies the activation service that the license is no longer
  /// in use on this device, allowing it to be reactivated elsewhere if the
  /// license terms permit. Deletion simply removes the activation record locally
  /// without notifying the activation service.
  ///
  /// After deactivation, the [ActivationInfo.status] of the corresponding activation
  /// will be updated to reflect the deactivated state.
  ///
  /// ## Parameters
  ///
  /// - [applicationId]: The application identifier owning the activation.
  /// - [licenseKey]: The license key (UUID v4) to deactivate.
  /// - [productId]: The product identifier to deactivate. Defaults to [ProductID.core].
  /// - [onComplete]: Callback invoked on completion. The callback receives:
  ///   - [GemError.success]: Deactivation succeeded.
  ///   - [GemError.required]: No internet; Try again later or complete the deactivation offline.
  ///     Follow the steps from the manual for manual offline deactivation.
  ///   - [GemError.invalidInput]: Invalid input; check the hint for details.
  ///   - [GemError.io]: IO error when accessing license file from disk.
  ///   - [GemError.noMemory]: Allocation failed on the platform.
  ///   - [GemError.networkFailed]: Network request failed to start.
  ///   - [GemError.missingCapability]: The activation API is not available on this platform/SDK build.
  ///
  /// ## Returns
  ///
  /// - [TaskHandler]: A task handle when the deactivation request started successfully, otherwise `null`.
  ///
  /// ## Also see:
  ///
  /// - [activate] - Perform activation.
  /// - [getActivationsForProduct] - Retrieve activation information.
  /// - [deleteActivation] - Deletes an activation record from local storage.
  static TaskHandler? deactivate({
    required final String applicationId,
    required final String licenseKey,
    final String productId = ProductID.core,
    required final void Function(GemError error, String hint) onComplete,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete(GemErrorExtension.fromCode(err), hint);
    });

    final OperationResult resultString = staticMethod(
      'ActivationService',
      'deactivate',
      args: <String, dynamic>{
        'applicationId': applicationId,
        'licenseKey': licenseKey,
        'productId': productId,
        'listener': progListener.id,
      },
    );

    if (resultString['gemApiError'] == GemError.missingCapability.code) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete(
        GemError.missingCapability,
        'Activation API is not available. Please check if your SDK build includes the activation capability and contact Magic Lane support for assistance.',
      );
      return null;
    }

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Completes an activation that required an extra manual step.
  ///
  /// Used when the activation flow required an out-of-band/manual request.
  /// Pass the [activationResponseBlob] obtained from the manual activation
  /// service call to finalize the activation locally.
  ///
  /// ## Parameters
  ///
  /// - [activationResponseBlob]: The response blob returned by the activation
  ///   service as described in the manual activation instructions.
  ///
  /// ## Returns
  ///
  /// - A tuple containing:
  ///   - [GemError]: Result code describing the outcome. Possible [GemError] values:
  ///     - [GemError.success]: Activation completed successfully.
  ///     - [GemError.invalidInput]: Provided blob is invalid; check the returned hint.
  ///     - [GemError.notFound]: No matching activation found on this device.
  ///     - [GemError.io]: IO error while updating local license storage.
  ///     - [GemError.missingCapability]: The activation API is not available on this platform/SDK build.
  ///   - [String]: A hint or additional information from the platform.
  ///
  /// ## Also see:
  ///
  /// - [activate] - Activates a product using the supplied license key.
  /// - [completeOfflineActivation] - Complete an offline activation flow.
  static (GemError, String) completeActivation(
    final String activationResponseBlob,
  ) {
    final OperationResult resultString = staticMethod(
      'ActivationService',
      'completeActivation',
      args: activationResponseBlob,
    );

    if (resultString['gemApiError'] == GemError.missingCapability.code) {
      return (
        GemError.missingCapability,
        'Activation API is not available. Please check if your SDK build includes the activation capability and contact Magic Lane support for assistance.',
      );
    }

    return (
      GemErrorExtension.fromCode(resultString['result']['first']),
      resultString['result']['second'],
    );
  }

  /// Completes an offline activation using the provided offline activation key.
  ///
  /// Finalizes an offline activation flow where the activation service
  /// returned a short `offlineActivationKey`. Use this when following the
  /// offline/manual activation instructions.
  ///
  /// ## Parameters
  ///
  /// - [offlineActivationKey]: The short activation key returned by the
  ///   offline activation service flow.
  ///
  /// ## Returns
  ///
  /// - A tuple containing:
  ///   - [GemError]: Result code describing the outcome. Possible [GemError] values:
  ///     - [GemError.success]: Activation completed successfully.
  ///     - [GemError.invalidInput]: Provided blob is invalid; check the returned hint.
  ///     - [GemError.notFound]: No matching activation found on this device.
  ///     - [GemError.io]: IO error while updating local license storage.
  ///     - [GemError.missingCapability]: The activation API is not available on this platform/SDK build.
  ///   - [String]: A hint or additional information from the platform.
  ///
  /// ## Also see:
  ///
  /// - [activate] - Activates a product using the supplied license key.
  /// - [completeActivation] - Complete an activation that required manual steps.
  static (GemError, String) completeOfflineActivation(
    final String offlineActivationKey,
  ) {
    final OperationResult resultString = staticMethod(
      'ActivationService',
      'completeOfflineActivation',
      args: offlineActivationKey,
    );

    if (resultString['gemApiError'] == GemError.missingCapability.code) {
      return (
        GemError.missingCapability,
        'Activation API is not available. Please check if your SDK build includes the activation capability and contact Magic Lane support for assistance.',
      );
    }

    return (
      GemErrorExtension.fromCode(resultString['result']['first']),
      resultString['result']['second'],
    );
  }

  /// Completes an offline deactivation using the provided deactivation key.
  ///
  /// Finalizes an offline deactivation flow where the deactivation service
  /// returned a short `offlineDeactivationKey`. Use this when following the
  /// offline/manual deactivation instructions.
  ///
  /// ## Parameters
  ///
  /// - [offlineDeactivationKey]: The short deactivation key returned by the
  ///   offline deactivation service flow.
  ///
  /// ## Returns
  ///
  /// - A tuple containing:
  ///   - [GemError]: Result code describing the outcome. Possible [GemError] values:
  ///     - [GemError.success]: Deactivation completed successfully.
  ///     - [GemError.invalidInput]: Provided blob is invalid; check the returned hint.
  ///     - [GemError.notFound]: No matching activation found on this device.
  ///     - [GemError.io]: IO error while updating local license storage.
  ///     - [GemError.missingCapability]: The activation API is not available on this platform/SDK build.
  ///   - [String]: A hint or additional information from the platform.
  ///
  /// ## Also see:
  ///
  /// - [deactivate] - Deactivates a product previously activated with a license key.
  static (GemError, String) completeOfflineDeactivation(
    final String offlineDeactivationKey,
  ) {
    final OperationResult resultString = staticMethod(
      'ActivationService',
      'completeOfflineDeactivation',
      args: offlineDeactivationKey,
    );

    if (resultString['gemApiError'] == GemError.missingCapability.code) {
      return (
        GemError.missingCapability,
        'Activation API is not available. Please check if your SDK build includes the activation capability and contact Magic Lane support for assistance.',
      );
    }

    return (
      GemErrorExtension.fromCode(resultString['result']['first']),
      resultString['result']['second'],
    );
  }

  /// Checks whether the given product is currently active on the device.
  ///
  /// ## Parameters
  ///
  /// - [productId]: The product identifier to query.
  ///
  /// ## Returns
  ///
  /// - `true` if the product is active on this device, otherwise `false`.
  /// If the activation API is not available on this platform/SDK build, this method returns `false`.
  ///
  /// ## Throws
  ///
  /// - May throw an exception for unexpected platform call failures.
  ///
  /// ## Also see:
  ///
  /// - [getActivationsForProduct] - Retrieve activation information.
  static bool isActive(final String productId) {
    final OperationResult resultString = staticMethod(
      'ActivationService',
      'isActive',
      args: productId,
    );

    if (resultString['gemApiError'] == GemError.missingCapability.code) {
      return false;
    }

    return resultString['result'];
  }

  /// Returns the product identifiers found on the device.
  ///
  /// ## Parameters
  ///
  /// - [includeExpired]: When `true`, include product identifiers for expired products as well. Defaults to `false`.
  /// If the activation API is not available on this platform/SDK build, this method returns an empty list.
  ///
  /// ## Returns
  ///
  /// - A list of product identifier strings present on the device.
  ///
  /// ## Also see:
  ///
  /// - [getActivationsForProduct] - Retrieve activation information.
  static List<String> getProductIds({final bool includeExpired = false}) {
    final OperationResult resultString = staticMethod(
      'ActivationService',
      'getProductIds',
      args: includeExpired,
    );

    if (resultString['gemApiError'] == GemError.missingCapability.code) {
      return <String>[];
    }

    return (resultString['result'] as List<dynamic>).cast<String>();
  }

  /// Returns activations found for the specified product.
  ///
  /// Retrieves a list of [ActivationInfo] objects representing activations
  /// for [productId] that are stored on this device.
  ///
  /// ## Parameters
  ///
  /// - [productId]: The product identifier for which to list activations.
  ///
  /// ## Returns
  ///
  /// - A list of [ActivationInfo] instances for the given product.
  /// If the activation API is not available on this platform/SDK build, this method returns an empty list.
  static List<ActivationInfo> getActivationsForProduct(final String productId) {
    final OperationResult resultString = staticMethod(
      'ActivationService',
      'getActivationsForProduct',
      args: productId,
    );

    if (resultString['gemApiError'] == GemError.missingCapability.code) {
      return <ActivationInfo>[];
    }

    return (resultString['result'] as List<dynamic>)
        .map((dynamic e) => ActivationInfo.fromJson(e))
        .toList();
  }

  /// Deletes an activation entry identified by its id.
  ///
  /// Do not confuse deactivation with deletion of an activation record on the device.
  /// Deactivation notifies the activation service that the license is no longer
  /// in use on this device, allowing it to be reactivated elsewhere if the
  /// license terms permit. Deletion simply removes the activation record locally
  /// without notifying the activation service.
  ///
  /// ## Parameters
  ///
  /// - [productId]: The activation id to delete.
  ///
  /// ## Returns
  ///
  /// - [GemError.success]: Deletion succeeded.
  /// - [GemError.notFound]: No activation with the given id was found.
  /// - [GemError.missingCapability]: The activation API is not available on this platform/SDK build.
  static GemError deleteActivation(final String productId) {
    final OperationResult resultString = staticMethod(
      'ActivationService',
      'deleteActivation',
      args: productId,
    );

    if (resultString['gemApiError'] == GemError.missingCapability.code) {
      return GemError.missingCapability;
    }

    return GemErrorExtension.fromCode(resultString['result']);
  }
}

/// Represents details about a product activation stored on the device.
///
/// Contains status, expiry and identifying information for an activation
/// entry. Instances are typically returned by [ActivationService.getActivationsForProduct].
///
/// ## See also:
///
/// - [ActivationService.getActivationsForProduct] - Retrieve activation information.
/// - [ActivationService.isActive] - Check if a product is active on the device.
///
/// {@category Activation}
class ActivationInfo {
  /// Creates a new [ActivationInfo] instance.
  ///
  /// API users should typically not create instances directly, but
  /// obtain them from [ActivationService.getActivationsForProduct].
  ///
  /// ## Parameters
  ///
  /// - [status]: The status of this activation.
  /// - [expiry]: The UTC expiry time of this activation.
  /// - [licenseKey]: The license key that was used to perform the activation.
  /// - [appToken]: The application token that enables usage of related online services.
  /// - [deviceFingerprint]: UUID v4 that uniquely identifies the device.
  /// - [id]: UUID v4 that uniquely identifies this activation record on the device.
  ActivationInfo({
    required this.status,
    required this.expiry,
    required this.licenseKey,
    required this.appToken,
    required this.deviceFingerprint,
    required this.id,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory ActivationInfo.fromJson(final Map<String, dynamic> json) {
    return ActivationInfo(
      status: ActivationStatusExtension.fromId(json['status']),
      expiry: DateTime.fromMillisecondsSinceEpoch(json['expiry'], isUtc: true),
      licenseKey: json['licenseKey'],
      appToken: json['appToken'],
      deviceFingerprint: json['deviceFingerprint'],
      id: json['id'],
    );
  }

  /// The status of this activation.
  ///
  /// Indicates whether the activation is active, expired, pending, etc.
  ActivationStatus status;

  /// The UTC expiry time of this activation.
  DateTime expiry;

  /// The license key that was used to perform the activation.
  String licenseKey;

  /// The application token that enables usage of related online services.
  ///
  /// Needs to be set manually via the [SdkSettings.appAuthorization] property.
  String appToken;

  /// UUID v4 that uniquely identifies the device. Used for deactivation flows.
  String deviceFingerprint;

  /// UUID v4 that uniquely identifies this activation record on the device.
  String id;
}

/// The various states an activation can be in on the device.
///
/// Use [ActivationInfo.status] to obtain the current state of an activation.
///
/// {@category Activation}
enum ActivationStatus {
  /// No activation information is available for this product.
  notAvailable,

  /// The activation is currently active and valid.
  activated,

  /// The activation expired and is no longer valid.
  expired,

  /// The activation was revoked by the issuer.
  revoked,

  /// The activation is pending and awaiting a response from the server.
  pendingActivation,

  /// The activation was deactivated; the license key can be reused.
  deactivated,

  /// The deactivation is pending and awaiting a server response.
  deactivationPending,
}

/// @nodoc
extension ActivationStatusExtension on ActivationStatus {
  static ActivationStatus fromId(final int code) {
    switch (code) {
      case 0:
        return ActivationStatus.notAvailable;
      case 1:
        return ActivationStatus.activated;
      case 2:
        return ActivationStatus.expired;
      case 3:
        return ActivationStatus.revoked;
      case 4:
        return ActivationStatus.pendingActivation;
      case 5:
        return ActivationStatus.deactivated;
      case 6:
        return ActivationStatus.deactivationPending;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case ActivationStatus.notAvailable:
        return 0;
      case ActivationStatus.activated:
        return 1;
      case ActivationStatus.expired:
        return 2;
      case ActivationStatus.revoked:
        return 3;
      case ActivationStatus.pendingActivation:
        return 4;
      case ActivationStatus.deactivated:
        return 5;
      case ActivationStatus.deactivationPending:
        return 6;
    }
  }
}

/// Well-known product identifier constants used by the activation API.
///
/// Use these constants when calling activation methods to specify the
/// product to activate or query.
///
/// {@category Activation}
abstract class ProductID {
  /// Core yearly product identifier.
  static const String core = 'core-yearly';

  /// Trial product identifier.
  static const String trial = 'core-trial';
}

/// Predefined duration identifier constants (ISO 8601 period format).
///
/// These constants represent common license duration values used when
/// requesting or describing product durations.
///
/// {@category Activation}
abstract class DurationID {
  /// One month duration.
  static const String oneMonth = 'P1M';

  /// Six months duration.
  static const String sixMonths = 'P6M';

  /// One year duration.
  static const String oneYear = 'P1Y';

  /// Two years duration.
  static const String twoYears = 'P2Y';

  /// Three years duration.
  static const String threeYears = 'P3Y';

  /// Four years duration.
  static const String fourYears = 'P4Y';

  /// Five years duration.
  static const String fiveYears = 'P5Y';

  /// Lifetime duration.
  static const String lifetime = 'P7Y';
}
