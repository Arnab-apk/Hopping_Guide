// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// GTFS-RT service alert associated with public transport stop data.
///
/// Alerts are provided deduplicated in [PTStopInfo.alerts]. The same
/// [PTAlertInfo] instance is shared between [PTStopInfo.alerts] and every
/// [PTTrip.alerts] / [PTStop.alerts] list which references it. The order of
/// the alerts is not meaningful. Alerts differing only in [severityLevel]
/// or in the [causeDetails] / [effectDetails] texts are distinct entries.
///
/// **WARNING:** The translations ([urls], [headerTexts], [descriptionTexts],
/// [causeDetails], [effectDetails]) are passed through verbatim from the
/// GTFS-RT feed. The language tags may be inaccurate — some feeds tag the
/// same untranslated text under multiple languages — so treat them as hints
/// and fall back to the first entry when no exact match exists
/// (see [selectTranslation]).
///
/// ## Also see:
///
/// - [PTStopInfo.alerts] — All alerts for a stop info.
/// - [PTTrip.alerts] — The alerts applicable to a specific trip.
/// - [PTStop.alerts] — The alerts scoped to a specific stop.
/// - [PTAlert] - Alert of a public transport route segment. Do not confuse
/// with this class which provides alerts for public transport data
/// associated with stops.
///
/// {@category Maps & 3D Scenes}
class PTAlertInfo {
  /// Create a [PTAlertInfo].
  ///
  /// API users do not typically create instances of this class directly.
  /// Get instances from [PTStopInfo.alerts], [PTTrip.alerts] or
  /// [PTStop.alerts].
  ///
  /// ## Parameters
  ///
  /// - [cause]: (PTAlertCause) The cause of the alert.
  /// - [effect]: (PTAlertEffect) The effect of the alert.
  /// - [activePeriods]: (`List<PTAlertActivePeriod>`) Periods when the alert is active.
  /// - [urls]: (`List<PTAlertTranslation>`) URL translations for more information.
  /// - [headerTexts]: (`List<PTAlertTranslation>`) Header text translations.
  /// - [descriptionTexts]: (`List<PTAlertTranslation>`) Description text translations.
  /// - [severityLevel]: (PTAlertSeverityLevel?) The severity of the alert.
  /// - [causeDetails]: (`List<PTAlertTranslation>`) Agency-specific cause wording translations.
  /// - [effectDetails]: (`List<PTAlertTranslation>`) Agency-specific effect wording translations.
  PTAlertInfo({
    required this.cause,
    required this.effect,
    required this.activePeriods,
    required this.urls,
    required this.headerTexts,
    required this.descriptionTexts,
    this.severityLevel,
    this.causeDetails = const <PTAlertTranslation>[],
    this.effectDetails = const <PTAlertTranslation>[],
  });

  factory PTAlertInfo._build(GemParameter param) {
    final Map<String, dynamic> map = <String, dynamic>{};

    final List<GemParameter> alert = (param.value as ParameterList).toList();
    for (final GemParameter el in alert) {
      if (el.key == 'active_periods') {
        map[el.key!] = PTAlertActivePeriod.buildActivePeriods(
          el.value.toList(),
        );
      } else if (el.key == 'url' ||
          el.key == 'header_text' ||
          el.key == 'description_text' ||
          el.key == 'cause_detail' ||
          el.key == 'effect_detail') {
        map[el.key!] = PTAlertTranslation.buildTranslations(el.value.toList());
      } else {
        map[el.key!] = el.value;
      }
    }

    return PTAlertInfo(
      cause: map['cause'] != null
          ? PTAlertCauseExtension.fromId(map['cause'] as int)
          : PTAlertCause.unknownCause,
      effect: map['effect'] != null
          ? PTAlertEffectExtension.fromId(map['effect'] as int)
          : PTAlertEffect.unknownEffect,
      activePeriods:
          map['active_periods'] as List<PTAlertActivePeriod>? ??
          <PTAlertActivePeriod>[],
      urls: map['url'] as List<PTAlertTranslation>? ?? <PTAlertTranslation>[],
      headerTexts:
          map['header_text'] as List<PTAlertTranslation>? ??
          <PTAlertTranslation>[],
      descriptionTexts:
          map['description_text'] as List<PTAlertTranslation>? ??
          <PTAlertTranslation>[],
      severityLevel: map['severity_level'] != null
          ? PTAlertSeverityLevelExtension.fromId(map['severity_level'] as int)
          : null,
      causeDetails:
          map['cause_detail'] as List<PTAlertTranslation>? ??
          <PTAlertTranslation>[],
      effectDetails:
          map['effect_detail'] as List<PTAlertTranslation>? ??
          <PTAlertTranslation>[],
    );
  }

  /// The cause of the alert.
  final PTAlertCause cause;

  /// The effect of the alert.
  final PTAlertEffect effect;

  /// Periods when the alert is active.
  ///
  /// An empty list means the alert is active for as long as the feed carries
  /// it.
  final List<PTAlertActivePeriod> activePeriods;

  /// URL translations pointing to additional information (may be empty).
  final List<PTAlertTranslation> urls;

  /// Header text translations summarizing the alert (may be empty).
  final List<PTAlertTranslation> headerTexts;

  /// Description text translations detailing the alert (may be empty).
  final List<PTAlertTranslation> descriptionTexts;

  /// The severity of the alert; null when the feed supplies none.
  final PTAlertSeverityLevel? severityLevel;

  /// Agency-specific cause wording translations (may be empty).
  ///
  /// Complements the [cause] classification with the agency's own wording.
  final List<PTAlertTranslation> causeDetails;

  /// Agency-specific effect wording translations (may be empty).
  ///
  /// Complements the [effect] classification with the agency's own wording.
  final List<PTAlertTranslation> effectDetails;

  /// The URL text for [language] (see [selectTranslation]), or null when
  /// [urls] is empty.
  String? urlFor(String language) => selectTranslation(urls, language)?.text;

  /// The header text for [language] (see [selectTranslation]), or null when
  /// [headerTexts] is empty.
  String? headerTextFor(String language) =>
      selectTranslation(headerTexts, language)?.text;

  /// The description text for [language] (see [selectTranslation]), or null
  /// when [descriptionTexts] is empty.
  String? descriptionTextFor(String language) =>
      selectTranslation(descriptionTexts, language)?.text;

  /// The cause detail text for [language] (see [selectTranslation]), or null
  /// when [causeDetails] is empty.
  String? causeDetailFor(String language) =>
      selectTranslation(causeDetails, language)?.text;

  /// The effect detail text for [language] (see [selectTranslation]), or
  /// null when [effectDetails] is empty.
  String? effectDetailFor(String language) =>
      selectTranslation(effectDetails, language)?.text;

  /// Select the best translation from [translations] for [language].
  ///
  /// Picks the first entry whose [PTAlertTranslation.language] equals
  /// [language], otherwise falls back to the first entry. The language tags
  /// come verbatim from the feed and may be inaccurate.
  ///
  /// ## Parameters
  ///
  /// - [translations]: (`List<PTAlertTranslation>`) Translations to select from.
  /// - [language]: (String) Language tag to match, e.g. `en`.
  ///
  /// ## Returns
  ///
  /// - (PTAlertTranslation?) The selected translation, or null when [translations] is empty.
  static PTAlertTranslation? selectTranslation(
    List<PTAlertTranslation> translations,
    String language,
  ) {
    if (translations.isEmpty) {
      return null;
    }

    for (final PTAlertTranslation translation in translations) {
      if (translation.language == language) {
        return translation;
      }
    }

    return translations.first;
  }

  /// Builds a list of [PTAlertInfo] from a list of [GemParameter].
  ///
  /// API users should not call this method directly.
  @internal
  static List<PTAlertInfo> buildAlerts(List<GemParameter> paramList) {
    final List<PTAlertInfo> alerts = <PTAlertInfo>[];

    for (final GemParameter param in paramList) {
      alerts.add(PTAlertInfo._build(param));
    }

    return alerts;
  }

  /// Resolves a list of alert index [GemParameter] against [alerts].
  ///
  /// The indexes reference the alerts list of the same response. Out of
  /// range indexes are skipped.
  ///
  /// API users should not call this method directly.
  @internal
  static List<PTAlertInfo> resolveAlertIndexes(
    List<GemParameter> paramList,
    List<PTAlertInfo> alerts,
  ) {
    final List<PTAlertInfo> resolved = <PTAlertInfo>[];

    for (final GemParameter param in paramList) {
      final dynamic index = param.value;
      if (index is int && index >= 0 && index < alerts.length) {
        resolved.add(alerts[index]);
      }
    }

    return resolved;
  }
}

/// Period when a [PTAlertInfo] is active.
///
/// Both bounds are optional: a null [start] means the alert has been active
/// since forever, a null [end] means the alert is open-ended.
///
/// ## Also see:
///
/// - [PTAlertInfo.activePeriods] — The active periods for a specific alert.
///
/// {@category Maps & 3D Scenes}
class PTAlertActivePeriod {
  /// Create a [PTAlertActivePeriod].
  ///
  /// API users do not typically create instances of this class directly.
  ///
  /// ## Parameters
  ///
  /// - [start]: (DateTime?) UTC start of the period; null = active since forever.
  /// - [end]: (DateTime?) UTC end of the period; null = open-ended.
  PTAlertActivePeriod({this.start, this.end});

  factory PTAlertActivePeriod._build(GemParameter param) {
    final Map<String, dynamic> map = <String, dynamic>{};

    final List<GemParameter> period = (param.value as ParameterList).toList();
    for (final GemParameter el in period) {
      map[el.key!] = el.value;
    }

    return PTAlertActivePeriod(
      start: map['start'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['start'] as int) * 1000,
              isUtc: true,
            )
          : null,
      end: map['end'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['end'] as int) * 1000,
              isUtc: true,
            )
          : null,
    );
  }

  /// UTC start of the period; null means active since forever.
  final DateTime? start;

  /// UTC end of the period; null means open-ended.
  final DateTime? end;

  /// Builds a list of [PTAlertActivePeriod] from a list of [GemParameter].
  ///
  /// API users should not call this method directly.
  @internal
  static List<PTAlertActivePeriod> buildActivePeriods(
    List<GemParameter> paramList,
  ) {
    final List<PTAlertActivePeriod> periods = <PTAlertActivePeriod>[];

    for (final GemParameter param in paramList) {
      periods.add(PTAlertActivePeriod._build(param));
    }

    return periods;
  }
}

/// A single translation of a [PTAlertInfo] text field.
///
/// **WARNING:** The [language] tag comes verbatim from the GTFS-RT feed and
/// may be inaccurate — some feeds tag the same untranslated text under
/// multiple languages. Treat it as a hint and fall back to the first entry
/// of the translation list when no exact match exists
/// (see [PTAlertInfo.selectTranslation]).
///
/// ## Also see:
///
/// - [PTAlertInfo.urls] — The URL translations for a specific alert.
/// - [PTAlertInfo.headerTexts] — The header text translations for a specific alert.
/// - [PTAlertInfo.descriptionTexts] — The description text translations for a specific alert.
/// - [PTAlertInfo.causeDetails] — The cause detail translations for a specific alert.
/// - [PTAlertInfo.effectDetails] — The effect detail translations for a specific alert.
///
/// {@category Maps & 3D Scenes}
class PTAlertTranslation {
  /// Create a [PTAlertTranslation].
  ///
  /// API users do not typically create instances of this class directly.
  ///
  /// ## Parameters
  ///
  /// - [language]: (String) Language tag, verbatim from the feed.
  /// - [text]: (String) Translation text.
  PTAlertTranslation({required this.language, required this.text});

  factory PTAlertTranslation._build(GemParameter param) {
    final Map<String, dynamic> map = <String, dynamic>{};

    final List<GemParameter> translation = (param.value as ParameterList)
        .toList();
    for (final GemParameter el in translation) {
      map[el.key!] = el.value;
    }

    return PTAlertTranslation(
      language: map['language'] as String,
      text: map['text'] as String,
    );
  }

  /// Language tag, verbatim from the feed (may be inaccurate).
  final String language;

  /// Translation text.
  final String text;

  /// Builds a list of [PTAlertTranslation] from a list of [GemParameter].
  ///
  /// API users should not call this method directly.
  @internal
  static List<PTAlertTranslation> buildTranslations(
    List<GemParameter> paramList,
  ) {
    final List<PTAlertTranslation> translations = <PTAlertTranslation>[];

    for (final GemParameter param in paramList) {
      translations.add(PTAlertTranslation._build(param));
    }

    return translations;
  }
}

/// Cause of a [PTAlertInfo] (GTFS-RT `Cause` enum).
///
/// Values outside the GTFS-RT enum are mapped to [unknownCause].
///
/// ## Also see:
///
/// - [PTAlertInfo.cause] — The cause for a specific alert.
///
/// {@category Maps & 3D Scenes}
enum PTAlertCause {
  /// Unknown cause.
  unknownCause,

  /// Other cause not represented by any other value.
  otherCause,

  /// Technical problem.
  technicalProblem,

  /// Strike.
  strike,

  /// Demonstration.
  demonstration,

  /// Accident.
  accident,

  /// Holiday.
  holiday,

  /// Weather.
  weather,

  /// Maintenance.
  maintenance,

  /// Construction.
  construction,

  /// Police activity.
  policeActivity,

  /// Medical emergency.
  medicalEmergency,
}

/// @nodoc
extension PTAlertCauseExtension on PTAlertCause {
  /// Returns the GTFS-RT `Cause` value for the [PTAlertCause].
  int get id => index + 1;

  /// Returns the [PTAlertCause] for the GTFS-RT `Cause` [value].
  ///
  /// Out of range values are mapped to [PTAlertCause.unknownCause].
  static PTAlertCause fromId(int value) {
    if (value < 1 || value > PTAlertCause.values.length) {
      return PTAlertCause.unknownCause;
    }
    return PTAlertCause.values[value - 1];
  }
}

/// Effect of a [PTAlertInfo] (GTFS-RT `Effect` enum).
///
/// Values outside the GTFS-RT enum are mapped to [unknownEffect].
///
/// ## Also see:
///
/// - [PTAlertInfo.effect] — The effect for a specific alert.
///
/// {@category Maps & 3D Scenes}
enum PTAlertEffect {
  /// No service.
  ///
  /// Overlaps with [PTTrip.isCancelled] — the trip flag remains the
  /// authoritative cancellation indicator; the alert supplies the
  /// user-facing reason.
  noService,

  /// Reduced service.
  reducedService,

  /// Significant delays.
  significantDelays,

  /// Detour.
  detour,

  /// Additional service.
  additionalService,

  /// Modified service.
  modifiedService,

  /// Other effect not represented by any other value.
  otherEffect,

  /// Unknown effect.
  unknownEffect,

  /// Stop moved.
  stopMoved,

  /// No effect.
  noEffect,

  /// Accessibility issue.
  accessibilityIssue,
}

/// @nodoc
extension PTAlertEffectExtension on PTAlertEffect {
  /// Returns the GTFS-RT `Effect` value for the [PTAlertEffect].
  int get id => index + 1;

  /// Returns the [PTAlertEffect] for the GTFS-RT `Effect` [value].
  ///
  /// Out of range values are mapped to [PTAlertEffect.unknownEffect].
  static PTAlertEffect fromId(int value) {
    if (value < 1 || value > PTAlertEffect.values.length) {
      return PTAlertEffect.unknownEffect;
    }
    return PTAlertEffect.values[value - 1];
  }
}

/// Severity of a [PTAlertInfo] (GTFS-RT `SeverityLevel` enum).
///
/// Values outside the GTFS-RT enum are mapped to [unknown].
///
/// ## Also see:
///
/// - [PTAlertInfo.severityLevel] — The severity for a specific alert.
///
/// {@category Maps & 3D Scenes}
enum PTAlertSeverityLevel {
  /// Unknown severity.
  unknown,

  /// Information.
  info,

  /// Warning.
  warning,

  /// Severe.
  severe,
}

/// @nodoc
extension PTAlertSeverityLevelExtension on PTAlertSeverityLevel {
  /// Returns the GTFS-RT `SeverityLevel` value for the [PTAlertSeverityLevel].
  int get id => index + 1;

  /// Returns the [PTAlertSeverityLevel] for the GTFS-RT `SeverityLevel`
  /// [value].
  ///
  /// Out of range values are mapped to [PTAlertSeverityLevel.unknown].
  static PTAlertSeverityLevel fromId(int value) {
    if (value < 1 || value > PTAlertSeverityLevel.values.length) {
      return PTAlertSeverityLevel.unknown;
    }
    return PTAlertSeverityLevel.values[value - 1];
  }
}
