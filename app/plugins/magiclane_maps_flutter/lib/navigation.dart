// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// # Navigation
///
/// Provides APIs for turn-by-turn navigation, navigation instructions, and navigation service management.
///
/// This library covers the main interfaces and classes for managing navigation sessions and retrieving navigation instructions.
///
/// # Main features
/// - [NavigationInstruction] – Represents a turn-by-turn navigation instruction.
/// - [NavigationService] – Main class for managing navigation sessions and retrieving navigation events.
///
/// ## More details
///
/// - See the [Routing documentation](https://developer.magiclane.com/docs/flutter/guides/category/routing) and the [Navigation documentation](https://developer.magiclane.com/docs/flutter/guides/category/navigation) for more information.
library;

export 'src/navigation/navigation_instruction.dart';
export 'src/navigation/navigation_instruction_update_info.dart';
export 'src/navigation/navigation_service.dart';
export 'src/navigation/next_speed_limit.dart';
