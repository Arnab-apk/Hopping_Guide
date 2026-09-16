// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// # Projections
///
/// Provides APIs for map projections and coordinate transformations.
///
/// This library covers the main class and utilities for converting between geographic and projected coordinates.
///
/// ## Main features
/// - [ProjectionService] – Main class for handling map projections and coordinate conversions.
///
/// ## More details
///
/// - See the [Projections documentation](https://developer.magiclane.com/docs/flutter/guides/positioning/projections) for more information.
library;

export 'src/projection/bng_projection.dart';
export 'src/projection/gk_projection.dart';
export 'src/projection/lam_projection.dart';
export 'src/projection/mgrs_projection.dart';
export 'src/projection/projection.dart';
export 'src/projection/projection_service.dart';
export 'src/projection/utm_projection.dart';
export 'src/projection/w3w_projection.dart';
export 'src/projection/wgs84_projection.dart';
