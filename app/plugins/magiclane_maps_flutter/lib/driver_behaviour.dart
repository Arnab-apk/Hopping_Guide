// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// # Driver Behaviour
///
/// Provides APIs for analyzing and retrieving driver behaviour, driving events, and risk scores from sensor data.
///
/// This library covers the detection and analysis of driving events (such as harsh braking, acceleration, swerving), session statistics, and risk scoring.
///
/// ## Main features
/// - [DriverBehaviour] – Main class for managing driver behaviour analysis sessions.
/// - [DriverBehaviourAnalysis] – Represents a single analysis session, with statistics and event lists.
/// - [MappedDrivingEvent] – Represents a mapped driving event with time, location, and event type.
/// - [DrivingScores] – Provides risk scores for various driving behaviours.
/// - [DrivingEvent] – Enum of supported driving events (e.g., harsh braking, tailgating).
///
/// ## More details
///
/// - See the [Driver Behaviour documentation](https://developer.magiclane.com/docs/flutter/guides/driver-behaviour) for more information.
library;

export 'src/driverbehaviour/driver_behaviour.dart';
export 'src/driverbehaviour/driver_behaviour_analysis.dart';
export 'src/driverbehaviour/driving_scores.dart';
export 'src/driverbehaviour/mapped_driving_event.dart';
