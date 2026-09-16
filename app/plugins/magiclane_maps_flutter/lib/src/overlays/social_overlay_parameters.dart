// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Predefined parameter keys for report category metadata.
///
/// Contains constants for accessing category configuration from
/// [SocialReportsOverlayCategory.parameters]. Keys define category name,
/// ID, parameter value types (integer/double/string), currency, validity
/// duration, and text-to-speech pronunciation.
///
/// ## See also:
///
/// - [SocialReportsOverlayCategory.parameters] - Contains these keys.
/// - [PredefinedReportParameterKeys] - Keys for report submission.
///
/// {@category Overlays}
abstract class PredefinedCategoryParameterKeys {
  /// String
  static const String reportCategName = 'categ_name';

  /// int
  static const String reportCategId = 'categ_id';

  /// String
  static const String reportCategKVTypeInteger = 'integer';

  /// String
  static const String reportCategKVTypeDouble = 'double';

  /// String
  static const String reportCategKVTypeString = 'string';

  /// String
  static const String reportCategCurrency = 'currency';

  /// int ( minutes )
  static const String reportCategValidity = 'validity_mins';

  /// String
  static const String reportCategNameTTS = 'tts';
}

/// Predefined parameter keys for social report data access.
///
/// Contains constants for reading report properties from [OverlayItem.previewData]
/// including owner information, timestamps, scores, directions, permissions, and
/// comments. Use when processing social report overlay items or in [SocialOverlay.updateReport].
///
/// ## See also:
///
/// - [OverlayItem.previewData] - Contains report data keyed by these constants.
/// - [SocialOverlay.updateReport] - Modifies report parameters.
///
/// {@category Overlays}
abstract class PredefinedReportParameterKeys {
  /// String
  static const String reportCategNameTTS = 'tts';

  /// int ( minutes )
  static const String reportCategValidity = 'validity_mins';

  /// string
  static const String reportDescription = 'description';

  /// LargeInteger
  static const String reportOwnerId = 'owner_id';

  /// String
  static const String reportOwnerName = 'owner_name';

  /// bool
  static const String reportOwnReport = 'own_report';

  /// int
  static const String reportScore = 'score';

  /// int timestamp ( seconds )
  static const String reportCreateTimeUTC = 'create_stamp_utc';

  /// int timestamp ( seconds )
  static const String reportUpdateTimeUTC = 'update_stamp_utc';

  /// int timestamp ( seconds )
  static const String reportExpireTimeUTC = 'expire_stamp_utc';

  /// bool
  static const String reportHasSnapshot = 'has_snapshot';

  /// double
  static const String reportDirection = 'direction_';

  /// double
  static const String reportDirection1 = 'direction_1';

  /// double
  static const String reportDirection2 = 'direction_2';

  /// bool
  static const String reportAllowThumb = 'allow_thumb';

  /// bool
  static const String reportAllowUpdate = 'allow_update';

  /// bool
  static const String reportAllowDelete = 'allow_delete';

  /// String
  static const String reportCurrency = 'currency';

  /// List
  static const String reportComment = 'comments';

  /// String
  static const String reportCommentUserIcon = 'user_icon';

  /// String
  static const String reportCommentUserName = 'sender_name';

  /// String
  static const String reportCommentText = 'payload';

  /// int timestamp ( seconds )
  static const String reportCommentTimeUTC = 'stamp';
}
