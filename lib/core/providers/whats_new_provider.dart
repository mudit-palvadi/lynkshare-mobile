import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../release_notes.dart';

const whatsNewSeenBuildKey = 'whats_new_seen_build';

class WhatsNewCheck {
  const WhatsNewCheck({
    required this.buildNumber,
    required this.shouldShow,
    required this.notes,
  });

  final int buildNumber;
  final bool shouldShow;
  final ReleaseNotes? notes;
}

class WhatsNewNotifier extends AsyncNotifier<WhatsNewCheck> {
  @override
  Future<WhatsNewCheck> build() async {
    final info = await PackageInfo.fromPlatform();
    final buildNumber = int.tryParse(info.buildNumber) ?? 0;
    final prefs = ref.read(sharedPreferencesProvider);
    final seen = prefs.getInt(whatsNewSeenBuildKey);

    // First install: remember the current build without interrupting.
    if (seen == null) {
      await prefs.setInt(whatsNewSeenBuildKey, buildNumber);
      return WhatsNewCheck(
        buildNumber: buildNumber,
        shouldShow: false,
        notes: null,
      );
    }

    return WhatsNewCheck(
      buildNumber: buildNumber,
      shouldShow: buildNumber > seen,
      notes: releaseNotesForBuild(buildNumber),
    );
  }

  Future<void> markSeen(int buildNumber) async {
    await ref
        .read(sharedPreferencesProvider)
        .setInt(whatsNewSeenBuildKey, buildNumber);
  }
}

final whatsNewProvider =
    AsyncNotifierProvider<WhatsNewNotifier, WhatsNewCheck>(
      WhatsNewNotifier.new,
    );
