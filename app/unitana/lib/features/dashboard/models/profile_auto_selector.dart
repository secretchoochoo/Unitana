import '../../../data/city_repository.dart';
import '../../../models/place.dart';

class ProfileLocationSignal {
  final double latitude;
  final double longitude;
  final DateTime sampledAt;
  final double? accuracyMeters;

  const ProfileLocationSignal({
    required this.latitude,
    required this.longitude,
    required this.sampledAt,
    this.accuracyMeters,
  });
}

class ProfileSuggestionResult {
  final String? profileId;
  final String reason;
  final bool hasSuggestion;

  const ProfileSuggestionResult._({
    required this.profileId,
    required this.reason,
    required this.hasSuggestion,
  });

  factory ProfileSuggestionResult.none(String reason) {
    return ProfileSuggestionResult._(
      profileId: null,
      reason: reason,
      hasSuggestion: false,
    );
  }

  factory ProfileSuggestionResult.suggested({
    required String profileId,
    required String reason,
  }) {
    return ProfileSuggestionResult._(
      profileId: profileId,
      reason: reason,
      hasSuggestion: true,
    );
  }
}

class ProfileAutoSelector {
  const ProfileAutoSelector._();

  static Future<ProfileSuggestionResult> evaluate({
    required List<UnitanaProfile> profiles,
    required String activeProfileId,
    required Map<String, int> lastActivatedEpochByProfileId,
    required ProfileLocationSignal? signal,
  }) async {
    if (profiles.isEmpty) {
      return ProfileSuggestionResult.none('No saved profiles available.');
    }
    if (signal == null) {
      return ProfileSuggestionResult.none(
        'Location unavailable; profile suggestions are idle.',
      );
    }

    try {
      await CityRepository.instance.load();
    } catch (_) {
      return ProfileSuggestionResult.none(
        'City index unavailable; profile suggestions are idle.',
      );
    }

    final candidates = <_ProfileCandidateScore>[];
    for (final profile in profiles) {
      final anchor = _bestAnchorForProfile(profile, signal);
      if (anchor == null) continue;
      final recency = lastActivatedEpochByProfileId[profile.id] ?? 0;
      final recencyBonus = _recencyBonus(recency, signal.sampledAt);
      final totalScore = anchor.geoScore + recencyBonus;
      candidates.add(
        _ProfileCandidateScore(
          profileId: profile.id,
          cityName: anchor.cityName,
          distanceKm: anchor.distanceKm,
          geoScore: anchor.geoScore,
          recencyScore: recencyBonus,
          totalScore: totalScore,
        ),
      );
    }

    if (candidates.isEmpty) {
      return ProfileSuggestionResult.none(
        'No profile cities with coordinates were found.',
      );
    }

    candidates.sort((a, b) {
      final byScore = b.totalScore.compareTo(a.totalScore);
      if (byScore != 0) return byScore;
      final byDistance = a.distanceKm.compareTo(b.distanceKm);
      if (byDistance != 0) return byDistance;
      return a.profileId.compareTo(b.profileId);
    });

    final best = candidates.first;
    if (best.geoScore < 12.0) {
      return ProfileSuggestionResult.none(
        'Location signal is too far from saved profile cities.',
      );
    }

    final reason = best.profileId == activeProfileId
        ? 'Current profile best matches location near ${best.cityName} (${best.distanceKm.toStringAsFixed(0)} km).'
        : 'Suggested based on proximity to ${best.cityName} (${best.distanceKm.toStringAsFixed(0)} km) and recent profile activity.';
    return ProfileSuggestionResult.suggested(
      profileId: best.profileId,
      reason: reason,
    );
  }

  static _ProfileAnchorScore? _bestAnchorForProfile(
    UnitanaProfile profile,
    ProfileLocationSignal signal,
  ) {
    _ProfileAnchorScore? best;
    for (final place in profile.places) {
      final city = CityRepository.instance.byPlace(
        place.cityName,
        countryCode: place.countryCode,
      );
      final distanceKm = city?.distanceTo(signal.latitude, signal.longitude);
      if (distanceKm == null || distanceKm.isInfinite) continue;
      final weight = switch (place.type) {
        PlaceType.living => 1.0,
        PlaceType.visiting => 0.9,
        PlaceType.other => 0.8,
      };
      final geoScore = _distanceScore(distanceKm) * weight;
      final next = _ProfileAnchorScore(
        cityName: city?.cityName ?? place.cityName,
        distanceKm: distanceKm,
        geoScore: geoScore,
      );
      if (best == null ||
          next.geoScore > best.geoScore ||
          (next.geoScore == best.geoScore &&
              next.distanceKm < best.distanceKm)) {
        best = next;
      }
    }
    return best;
  }

  static double _distanceScore(double distanceKm) {
    // Confidence bands are intentionally broad for deterministic behavior.
    if (distanceKm <= 35) return 40;
    if (distanceKm <= 150) return 34;
    if (distanceKm <= 400) return 28;
    if (distanceKm <= 900) return 20;
    if (distanceKm <= 1500) return 14;
    if (distanceKm <= 2500) return 9;
    if (distanceKm <= 4000) return 5;
    return 0;
  }

  static double _recencyBonus(int lastActivatedEpochMs, DateTime nowUtc) {
    if (lastActivatedEpochMs <= 0) return 0;
    final last = DateTime.fromMillisecondsSinceEpoch(
      lastActivatedEpochMs,
      isUtc: true,
    );
    final ageHours = nowUtc.difference(last).inHours;
    if (ageHours <= 12) return 8;
    if (ageHours <= 24) return 6;
    if (ageHours <= 72) return 3;
    if (ageHours <= 168) return 1.5;
    return 0;
  }
}

class _ProfileAnchorScore {
  final String cityName;
  final double distanceKm;
  final double geoScore;

  const _ProfileAnchorScore({
    required this.cityName,
    required this.distanceKm,
    required this.geoScore,
  });
}

class _ProfileCandidateScore {
  final String profileId;
  final String cityName;
  final double distanceKm;
  final double geoScore;
  final double recencyScore;
  final double totalScore;

  const _ProfileCandidateScore({
    required this.profileId,
    required this.cityName,
    required this.distanceKm,
    required this.geoScore,
    required this.recencyScore,
    required this.totalScore,
  });
}
