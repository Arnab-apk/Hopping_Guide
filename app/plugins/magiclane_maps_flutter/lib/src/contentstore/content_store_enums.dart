// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Enumerates possible states for a [ContentStoreItem] in the context of a download operation.
///
/// {@category Content}
enum ContentStoreItemStatus {
  /// The item has no content available.
  unavailable,

  /// The item has complete content downloaded.
  completed,

  /// The item download is paused.
  paused,

  /// Download is waiting in the downloads queue.
  ///
  /// A download might be queued due to the maximum parallel downloads constraint or an API token rate limit.
  downloadQueued,

  /// Download is waiting for a network connection.
  downloadWaitingNetwork,

  /// Download is waiting for a free network to begin or resume the download.
  downloadWaitingFreeNetwork,

  /// Download is currently running.
  downloadRunning,

  /// Item download is waiting for the update operation to finish.
  ///
  /// Items selected for download during an update operation will enter this state.
  updateWaiting,
}

/// @nodoc
extension ContentStoreItemStatusExtension on ContentStoreItemStatus {
  int get id {
    switch (this) {
      case ContentStoreItemStatus.unavailable:
        return 0;
      case ContentStoreItemStatus.completed:
        return 1;
      case ContentStoreItemStatus.paused:
        return 2;
      case ContentStoreItemStatus.downloadQueued:
        return 3;
      case ContentStoreItemStatus.downloadWaitingNetwork:
        return 4;
      case ContentStoreItemStatus.downloadWaitingFreeNetwork:
        return 5;
      case ContentStoreItemStatus.downloadRunning:
        return 6;
      case ContentStoreItemStatus.updateWaiting:
        return 7;
    }
  }

  static ContentStoreItemStatus fromId(final int id) {
    switch (id) {
      case 0:
        return ContentStoreItemStatus.unavailable;
      case 1:
        return ContentStoreItemStatus.completed;
      case 2:
        return ContentStoreItemStatus.paused;
      case 3:
        return ContentStoreItemStatus.downloadQueued;
      case 4:
        return ContentStoreItemStatus.downloadWaitingNetwork;
      case 5:
        return ContentStoreItemStatus.downloadWaitingFreeNetwork;
      case 6:
        return ContentStoreItemStatus.downloadRunning;
      case 7:
        return ContentStoreItemStatus.updateWaiting;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Enumerates the priority levels for content download threads.
///
/// Specifies hints for the download thread scheduling priority.
///
/// ## Also see:
///
/// - [ContentStoreItem.asyncDownload] - Start or resume content downloads with priority hints.
///
/// {@category Content}
enum ContentDownloadThreadPriority {
  /// Default priority, following the OS default value.
  defaultPriority,

  /// Low priority for download threads.
  lowPriority,

  /// High priority for download threads.
  highPriority,
}

/// @nodoc
extension ContentDownloadThreadPriorityExtension
    on ContentDownloadThreadPriority {
  int get id {
    switch (this) {
      case ContentDownloadThreadPriority.defaultPriority:
        return 0;
      case ContentDownloadThreadPriority.lowPriority:
        return 1;
      case ContentDownloadThreadPriority.highPriority:
        return 2;
    }
  }

  static ContentDownloadThreadPriority fromId(final int id) {
    switch (id) {
      case 0:
        return ContentDownloadThreadPriority.defaultPriority;
      case 1:
        return ContentDownloadThreadPriority.lowPriority;
      case 2:
        return ContentDownloadThreadPriority.highPriority;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Enumerates the data save policies for content downloads.
///
/// Specifies where downloaded content data should be stored on the device.
///
/// ## Also see:
///
/// - [ContentStoreItem.asyncDownload] - Start or resume content downloads with save policy.
///
/// {@category Content}
enum DataSavePolicy {
  /// Save new data only on internal storage.
  useInternalOnly,

  /// Save new data only on external storage.
  useExternalOnly,

  /// Save new data on both storages but prefer internal storage.
  useBothPreferInternal,

  /// Save new data on both storages but prefer external storage.
  useBothPreferExternal,

  /// Use the default saving policy.
  useDefault,
}

/// @nodoc
extension DataSavePolicyExtension on DataSavePolicy {
  int get id {
    switch (this) {
      case DataSavePolicy.useInternalOnly:
        return 0;
      case DataSavePolicy.useExternalOnly:
        return 1;
      case DataSavePolicy.useBothPreferInternal:
        return 2;
      case DataSavePolicy.useBothPreferExternal:
        return 3;
      case DataSavePolicy.useDefault:
        return 4;
    }
  }

  static DataSavePolicy fromId(final int id) {
    switch (id) {
      case 0:
        return DataSavePolicy.useInternalOnly;
      case 1:
        return DataSavePolicy.useExternalOnly;
      case 2:
        return DataSavePolicy.useBothPreferInternal;
      case 3:
        return DataSavePolicy.useBothPreferExternal;
      case 4:
        return DataSavePolicy.useDefault;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Enumerates the possible statuses for a content updater operation.
///
/// Also see:
///
/// - [ContentUpdater] - The content updater class that uses these statuses.
///
/// {@category Content}
enum ContentUpdaterStatus {
  /// Not started.
  idle,

  /// Waiting for an internet connection.
  waitConnection,

  /// Waiting for a Wi-Fi internet connection.
  waitWIFIConnection,

  /// Checking for updated items.
  checkForUpdate,

  /// Downloading updated content.
  download,

  /// Update is fully downloaded and ready to apply.
  ///
  /// When entering this state, [ContentUpdater.items] will return the list of target items to update.
  fullyReady,

  /// Update is partially downloaded and ready to apply.
  partiallyReady,

  /// Downloading remaining content after applying the update.
  ///
  /// Finishes downloading the remaining content after applying the update while the status was [partiallyReady].
  downloadRemainingContent,

  /// Downloading pending content.
  ///
  /// If a new item starts downloading during an update, it will complete after the update finishes and the status will be set to this value.
  downloadPendingContent,

  /// Finished with success.
  ///
  /// This state will be returned by convention; the user will also receive [ProgressListener.notifyComplete].
  complete,

  /// Finished with error.
  ///
  /// This state will be returned by convention; the user will also receive [ProgressListener.notifyComplete] with more error details.
  error,
}

/// @nodoc
extension ContentUpdaterStatusExtension on ContentUpdaterStatus {
  int get id {
    switch (this) {
      case ContentUpdaterStatus.idle:
        return 0;
      case ContentUpdaterStatus.waitConnection:
        return 1;
      case ContentUpdaterStatus.waitWIFIConnection:
        return 2;
      case ContentUpdaterStatus.checkForUpdate:
        return 3;
      case ContentUpdaterStatus.download:
        return 4;
      case ContentUpdaterStatus.fullyReady:
        return 5;
      case ContentUpdaterStatus.partiallyReady:
        return 6;
      case ContentUpdaterStatus.downloadRemainingContent:
        return 7;
      case ContentUpdaterStatus.downloadPendingContent:
        return 8;
      case ContentUpdaterStatus.complete:
        return 9;
      case ContentUpdaterStatus.error:
        return 10;
    }
  }

  static ContentUpdaterStatus fromId(final int id) {
    switch (id) {
      case 0:
        return ContentUpdaterStatus.idle;
      case 1:
        return ContentUpdaterStatus.waitConnection;
      case 2:
        return ContentUpdaterStatus.waitWIFIConnection;
      case 3:
        return ContentUpdaterStatus.checkForUpdate;
      case 4:
        return ContentUpdaterStatus.download;
      case 5:
        return ContentUpdaterStatus.fullyReady;
      case 6:
        return ContentUpdaterStatus.partiallyReady;
      case 7:
        return ContentUpdaterStatus.downloadRemainingContent;
      case 8:
        return ContentUpdaterStatus.downloadPendingContent;
      case 9:
        return ContentUpdaterStatus.complete;
      case 10:
        return ContentUpdaterStatus.error;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Downloadable content types managed by the Magic Lane SDK.
///
/// The [ContentType] enum lists kinds of downloadable content that the SDK can
/// manage (map regions, style packages, voice packs, etc.).
///
/// Not all enum values are fully supported yet; consult upstream documentation
/// when in doubt and prefer the values marked as supported by this package.
///
/// {@category Content}
enum ContentType {
  /// Augmented reality car models.
  ///
  /// Not fully supported in the Flutter Maps SDK.
  carModel,

  /// View styles for high-resolution displays (e.g., mobile phones).
  viewStyleHighRes,

  /// Road map content.
  ///
  /// Represent the detailed road map data used for navigation and routing.
  roadMap,

  /// Human voice content.
  ///
  /// A predefined set of high-quality human-recorded voice instructions are
  /// available for navigation.
  humanVoice,

  /// Computer-generated voice content.
  ///
  /// The quality of computer voices may vary depending on the language and
  /// device capabilities. These voices are highly flexible and can be used
  /// for a wide range of applications.
  computerVoice,

  /// View styles for low-resolution displays (e.g., desktop monitors).
  viewStyleLowRes,

  /// Unknown content type.
  unknown,
}

/// @nodoc
extension ContentTypeExtension on ContentType {
  int get id {
    switch (this) {
      case ContentType.carModel:
        return 1;
      case ContentType.viewStyleHighRes:
        return 2;
      case ContentType.roadMap:
        return 3;
      case ContentType.humanVoice:
        return 4;
      case ContentType.computerVoice:
        return 5;
      case ContentType.viewStyleLowRes:
        return 6;
      case ContentType.unknown:
        return 0;
    }
  }

  static ContentType fromId(final int id) {
    switch (id) {
      case 1:
        return ContentType.carModel;
      case 2:
        return ContentType.viewStyleHighRes;
      case 3:
        return ContentType.roadMap;
      case 4:
        return ContentType.humanVoice;
      case 5:
        return ContentType.computerVoice;
      case 6:
        return ContentType.viewStyleLowRes;
      case 0:
        return ContentType.unknown;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
