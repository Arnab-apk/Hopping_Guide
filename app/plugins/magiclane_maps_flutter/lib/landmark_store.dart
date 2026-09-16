// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// # Landmark Store
///
/// Provides APIs for browsing, managing, and interacting with landmark data collections and services.
///
/// This library covers the interfaces for accessing, browsing, and listening to changes.
///
/// ## Main features
/// - [LandmarkBrowseSession] – Interface for browsing landmark data sessions.
/// - [LandmarkStore] – Main class for accessing and managing landmark data.
/// - [LandmarkStoreCollection] – Represents a collection of landmark stores.
/// - [LandmarkStoreListener] – Listener interface for landmark store events.
/// - [LandmarkStoreService] – Service interface for managing landmark store operations.
///
/// ## More details
///
/// - See the [Landmark documentation](https://developer.magiclane.com/docs/flutter/guides/core/landmarks) for more information.
library;

export 'src/landmarkstore/landmark_browse_session.dart';
export 'src/landmarkstore/landmark_store.dart';
export 'src/landmarkstore/landmark_store_collection.dart';
export 'src/landmarkstore/landmark_store_enums.dart';
export 'src/landmarkstore/landmark_store_listener.dart';
export 'src/landmarkstore/landmark_store_service.dart';
