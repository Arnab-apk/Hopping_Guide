// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// # Content Store
///
/// Provides access to the content store, enabling management, querying, and updating of downloadable content.
/// This library covers the APIs for interacting with the GEM SDK's content store, including listing, updating,
/// and tracking the status of downloadable content items.
///
/// ## Main features
/// - [ContentStore] – Abstract class for accessing and managing the content store (singleton-like API).
/// - [ContentStoreItem] – Represents an individual downloadable content item, with metadata and operations.
/// - [ContentStoreItemStatus] – Enum of possible states for a content item (e.g., unavailable, completed, paused).
/// - [ContentType] – Enum of supported content types (e.g., maps, voices, car models).
/// - [ContentUpdater] – Class for updating content items, with progress and error handling.
/// - [ContentUpdaterStatus] – Enum of possible statuses for content update operations (e.g., idle, downloading, ready).
///
/// ## More details
///
/// - See the [Offline documentation](https://developer.magiclane.com/docs/flutter/guides/category/offline) for more information.
library;

export 'src/contentstore/content_store.dart';
export 'src/contentstore/content_store_enums.dart';
export 'src/contentstore/content_store_item.dart';
export 'src/contentstore/content_updater.dart';
