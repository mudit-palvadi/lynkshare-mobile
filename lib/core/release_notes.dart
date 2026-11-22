class ReleaseNoteSection {
  const ReleaseNoteSection({required this.title, required this.items});

  final String title;
  final List<String> items;
}

class ReleaseNotes {
  const ReleaseNotes({
    required this.version,
    required this.sections,
  });

  final String version;
  final List<ReleaseNoteSection> sections;
}

/// Version-specific notes keyed by the Android build number.
///
/// Add a new entry when a build ships. A missing entry still shows a short
/// generic dialog once, so the update is never silent.
const Map<int, ReleaseNotes> releaseNotesByBuild = {
  4: ReleaseNotes(
    version: '0.1.0',
    sections: [
      ReleaseNoteSection(
        title: 'New',
        items: [
          'What’s New now appears once after each update.',
          'Cloud transfer rewards use a rewarded interstitial.',
        ],
      ),
      ReleaseNoteSection(
        title: 'Improved',
        items: [
          'The app opens straight to Home without waiting for an update check.',
          'Pairing no longer reports a false error after it succeeds.',
          'Direct transfers resume the failed file instead of starting over.',
        ],
      ),
      ReleaseNoteSection(
        title: 'Fixed',
        items: [
          'Received direct files now end on a clear completion screen.',
          'Multi-file direct transfers clean up resources correctly.',
        ],
      ),
    ],
  ),
};

ReleaseNotes? releaseNotesForBuild(int buildNumber) {
  final exact = releaseNotesByBuild[buildNumber];
  if (exact != null) return exact;
  // A later build with no entry yet shows the latest maintained notes rather
  // than interrupting the user with an empty dialog.
  return buildNumber > 4 ? releaseNotesByBuild[4] : null;
}
