// Gateway of Regrets: Soul Defense (해원문)
// 한국 설화 기반 타워 디펜스 RPG
// Flutter + Flame Engine

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'common/debug_log.dart';

import 'ui/theme/app_colors.dart';
import 'data/game_data_loader.dart';

import 'game_screen.dart';
import 'l10n/app_strings.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'services/crazygames.dart';

Future<void> main() async {
  dlog('🚀 [main] Flutter app starting...');
  WidgetsFlutterBinding.ensureInitialized();

  // CrazyGames SDK: 로딩 시작 알림 → 초기화
  if (kIsWeb) {
    CrazyGamesService.loadingStart();
    await CrazyGamesService.init();
  }

  // Zone mismatch 경고는 무해 (ensureInitialized: 루트 Zone, runApp: guarded Zone)

  // 에러 핸들러 — 빨간 에러 화면 방지, 로그만 출력
  // Sentry 초기화 시 SentryFlutter.init이 이 핸들러를 재등록해 자동 전송함
  FlutterError.onError = (FlutterErrorDetails details) {
    dlog('');
    dlog('🚨🚨🚨 [FLUTTER-ERROR] ${details.exception}');
    dlog('📍 Library: ${details.library}');
    dlog('📍 Context: ${details.context}');
    dlog('📍 Stack: ${details.stack}');
    dlog('🚨🚨🚨');
    dlog('');
  };

  // 에러 위젯을 투명 SizedBox로 교체 (빨간 화면 대신)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    dlog('🔴 [ErrorWidget] ${details.exception}');
    return const SizedBox.shrink();
  };

  // 환경 변수 로드 (네이티브에서만 .env 파일 사용)
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    // ignore: avoid_catches_without_on_clauses — FileNotFoundError는 Error 타입
    } catch (e) {
      dlog('⚠️ [main] .env 파일 로드 실패 (무시): $e');
    }
  }

  // Supabase 초기화 (네이티브: .env, 웹: --dart-define)
  try {
    final supabaseUrl = kIsWeb
        ? const String.fromEnvironment('SUPABASE_URL')
        : (dotenv.env['SUPABASE_URL'] ?? '');
    final supabaseAnonKey = kIsWeb
        ? const String.fromEnvironment('SUPABASE_ANON_KEY')
        : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty && supabaseUrl != 'YOUR_SUPABASE_URL_HERE') {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      dlog('✅ [main] Supabase 초기화 완료 (${kIsWeb ? "Web" : "Native"})');
    } else {
      dlog('⚠️ [main] Supabase 키 미설정 — 클라우드 세이브 비활성');
    }
  // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    dlog('⚠️ [main] Supabase 초기화 실패: $e');
  }

  // 가로 모드 고정
  try {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } on Exception catch (e) {
    dlog('⚠️ [main] SystemChrome 설정 실패: $e');
  }

  // 웹: 자동 전체화면 (첫 터치 시 전체화면 전환)
  if (kIsWeb) {
    _setupWebFullscreen();
  }

  // JSON 데이터 로드 (실패 시 하드코딩 폴백)
  try {
    await GameDataLoader.initFromJson();
    dlog('✅ [main] GameDataLoader 초기화 완료');
  // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    dlog('⚠️ [main] GameDataLoader 초기화 실패, 폴백 사용: $e');
  }

  // 다국어 초기화
  try {
    await AppStrings.init(GameLanguage.ko);
    dlog('✅ [main] AppStrings 초기화 완료');
  // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    dlog('⚠️ [main] AppStrings 초기화 실패: $e');
  }

  // Sentry DSN 읽기 (.env or --dart-define) — 비어있으면 Sentry 비활성
  final sentryDsn = kIsWeb
      ? const String.fromEnvironment('SENTRY_DSN')
      : (dotenv.env['SENTRY_DSN'] ?? '');

  dlog('🎮 [main] runApp() 시작 (Sentry: ${sentryDsn.isNotEmpty ? "ON" : "OFF"})');

  Future<void> appRunner() async {
    runApp(
      const ProviderScope(
        child: GatewayOfRegretsApp(),
      ),
    );
  }

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = sentryDsn
          ..tracesSampleRate = 0.2
          ..release = 'gateway_of_regrets@1.0.0+8'
          ..environment = kIsWeb ? 'web' : 'mobile';
      },
      appRunner: appRunner,
    );
  } else {
    runZonedGuarded(appRunner, (error, stack) {
      dlog('');
      dlog('💥💥💥 [ZONE-ERROR] $error');
      dlog('📍 Stack: $stack');
      dlog('💥💥💥');
      dlog('');
    });
  }
}

/// 앱 루트
class GatewayOfRegretsApp extends StatelessWidget {
  const GatewayOfRegretsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gateway of Regrets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        colorSchemeSeed: AppColors.cherryBlossom,
      ),
      home: const GameScreen(),
    );
  }
}

/// 웹: 첫 터치 시 전체화면 전환 (브라우저 보안 정책상 사용자 제스처 필요)
void _setupWebFullscreen() {
  // Flutter web에서는 dart:html 대신 web package를 사용
  // 앱 시작 시 바로 전체화면은 브라우저가 차단하므로,
  // GameScreen에서 첫 터치 이벤트에 전체화면 요청을 연동
  dlog('🌐 [main] 웹 전체화면 모드 준비됨 — 첫 터치 시 전환');
}
