import 'package:client/core/providers/ad_consent_provider.dart';
import 'package:client/core/providers/download_notifier.dart';
import 'package:client/core/providers/download_state.dart';
import 'package:client/core/providers/whats_new_provider.dart';
import 'package:client/features/file_transfer/presentation/providers/upload_notifier.dart';
import 'package:client/features/file_transfer/presentation/providers/upload_state.dart';
import 'package:client/features/home/presentation/pages/home_screen.dart';
import 'package:client/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:client/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_ad_consent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('de.ffuf.in_app_update/methods');
  late List<String> calls;

  setUp(() {
    calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> launch(
    WidgetTester tester, {
    int? seenBuild,
    String buildNumber = '4',
  }) async {
    final values = <String, Object>{
      'has_onboarded': true,
      'has_seen_home_tutorial': true,
      'ads_enabled': false,
      'theme_mode': 'system',
    };
    if (seenBuild != null) {
      values[whatsNewSeenBuildKey] = seenBuild;
    }
    SharedPreferences.setMockInitialValues(values);
    PackageInfo.setMockInitialValues(
      appName: 'Lynk',
      packageName: 'app.xynix.lynk',
      version: '0.1.0',
      buildNumber: buildNumber,
      buildSignature: '',
      installerStore: null,
    );
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adConsentServiceProvider.overrideWithValue(FakeAdConsent()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          downloadProvider.overrideWith(_OfflineDownload.new),
          uploadProvider.overrideWith(_Upload.new),
        ],
        child: const LynkApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('launches directly to Home without a Play update check', (
    tester,
  ) async {
    await launch(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Checking for updates'), findsNothing);
    expect(find.text('Update required'), findsNothing);
    expect(calls, isEmpty);
  });

  testWidgets('first install stores the version without a dialog', (
    tester,
  ) async {
    await launch(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('What’s New'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(whatsNewSeenBuildKey), 4);
  });

  testWidgets('an upgrade shows What’s New once and marks it seen', (
    tester,
  ) async {
    await launch(tester, seenBuild: 3);

    expect(find.text('What’s New in 0.1.0'), findsOneWidget);
    await tester.tap(find.text('Got It'));
    await tester.pumpAndSettle();

    expect(find.text('What’s New in 0.1.0'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(whatsNewSeenBuildKey), 4);
  });

  testWidgets('the same version does not show What’s New again', (
    tester,
  ) async {
    await launch(tester, seenBuild: 4);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.textContaining('What’s New'), findsNothing);
  });
}

class _OfflineDownload extends DownloadNotifier {
  @override
  DownloadState build() => const DownloadState();

  @override
  Future<void> loadTransferPreview(
    String transferId, {
    String? accessToken,
  }) async {
    state = const DownloadState(
      phase: DownloadPhase.failed,
      errorMessage: 'offline',
    );
  }
}

class _Upload extends UploadNotifier {
  @override
  UploadState build() => const UploadState();
}
