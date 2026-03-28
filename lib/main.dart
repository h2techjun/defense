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

Future<void> main() async {
  dlog('🚀 [main] Flutter app starting...');
  WidgetsFlutterBinding.ensureInitialized();

  // Zone mismatch 경고는 무해 (ensureInitialized: 루트 Zone, runApp: guarded Zone)

  // 에러 핸들러 — 빨간 에러 화면 방지, 로그만 출력
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

  // 환경 변수 로드 (웹에서는 스킵)
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    // ignore: avoid_catches_without_on_clauses — FileNotFoundError는 Error 타입
    } catch (e) {
      dlog('⚠️ [main] .env 파일 로드 실패 (무시): $e');
    }
  } else {
    dlog('🌐 [main] 웹 환경 — .env 로드 스킵');
  }

  // Supabase 초기화 (웹에서는 .env 없으므로 스킵)
  if (!kIsWeb) {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty && supabaseUrl != 'YOUR_SUPABASE_URL_HERE') {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );
        dlog('✅ [main] Supabase 초기화 완료');
      }
    // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      dlog('⚠️ [main] Supabase 초기화 실패: $e');
    }
  } else {
    dlog('🌐 [main] 웹 환경 — Supabase 초기화 스킵');
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

  dlog('🎮 [main] runApp() 시작');
  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: GatewayOfRegretsApp(),
      ),
    );
  }, (error, stack) {
    dlog('');
    dlog('💥💥💥 [ZONE-ERROR] $error');
    dlog('📍 Stack: $stack');
    dlog('💥💥💥');
    dlog('');
  });
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
