// Gateway of Regrets: Soul Defense (해원문)
// 한국 설화 기반 타워 디펜스 RPG
// Flutter + Flame Engine

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/theme/app_colors.dart';
import 'data/game_data_loader.dart';

import 'game_screen.dart';
import 'l10n/app_strings.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  debugPrint('🚀 [main] Flutter app starting...');
  WidgetsFlutterBinding.ensureInitialized();

  // 에러 핸들러 — 빨간 에러 화면 방지, 로그만 출력
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('');
    debugPrint('🚨🚨🚨 [FLUTTER-ERROR] ${details.exception}');
    debugPrint('📍 Library: ${details.library}');
    debugPrint('📍 Context: ${details.context}');
    debugPrint('📍 Stack: ${details.stack}');
    debugPrint('🚨🚨🚨');
    debugPrint('');
  };

  // 에러 위젯을 투명 SizedBox로 교체 (빨간 화면 대신)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('🔴 [ErrorWidget] ${details.exception}');
    return const SizedBox.shrink();
  };

  // 환경 변수 로드 (웹에서는 스킵)
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } on Exception catch (e) {
      debugPrint('⚠️ [main] .env 파일 로드 실패: $e');
    }
  } else {
    debugPrint('🌐 [main] 웹 환경 — .env 로드 스킵');
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
        debugPrint('✅ [main] Supabase 초기화 완료');
      }
    } catch (e) {
      debugPrint('⚠️ [main] Supabase 초기화 실패: $e');
    }
  } else {
    debugPrint('🌐 [main] 웹 환경 — Supabase 초기화 스킵');
  }

  // 가로 모드 고정
  try {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } on Exception catch (e) {
    debugPrint('⚠️ [main] SystemChrome 설정 실패: $e');
  }

  // JSON 데이터 로드 (실패 시 하드코딩 폴백)
  try {
    await GameDataLoader.initFromJson();
    debugPrint('✅ [main] GameDataLoader 초기화 완료');
  } catch (e) {
    debugPrint('⚠️ [main] GameDataLoader 초기화 실패, 폴백 사용: $e');
  }

  // 다국어 초기화
  try {
    await AppStrings.init(GameLanguage.ko);
    debugPrint('✅ [main] AppStrings 초기화 완료');
  } catch (e) {
    debugPrint('⚠️ [main] AppStrings 초기화 실패: $e');
  }

  debugPrint('🎮 [main] runApp() 시작');
  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: GatewayOfRegretsApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('');
    debugPrint('💥💥💥 [ZONE-ERROR] $error');
    debugPrint('📍 Stack: $stack');
    debugPrint('💥💥💥');
    debugPrint('');
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
