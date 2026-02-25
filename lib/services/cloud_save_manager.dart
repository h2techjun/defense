import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/user_state.dart';
import 'save_manager.dart';

/// 클라우드 세이브(백업) 동기화 매니저
/// 실제 Supabase Database와 연동되는 클래스입니다.
class CloudSaveManager {
  static CloudSaveManager? _instance;
  static CloudSaveManager get instance => _instance ??= CloudSaveManager._();
  CloudSaveManager._();

  bool get _isConfigured {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 로컬 데이터를 클라우드로 동기화 (Upload)
  Future<bool> syncToCloud(String userId) async {
    try {
      if (!_isConfigured) {
        debugPrint('☁️ [CloudSave] Supabase가 아직 초기화되지 않았습니다. (.env 확인)');
        return false;
      }
      
      debugPrint('☁️ [CloudSave] Supabase DB 동기화 시작... (User ID: $userId)');

      // 로컬 데이터 수집
      final prefsData = await SaveManager.instance.loadUserState();
      if (prefsData == null) {
        debugPrint('☁️ [CloudSave] 업로드할 로컬 데이터가 없습니다.');
        return false;
      }

      // Supabase 테이블 `user_saves` 에 UPSERT 실행
      final payload = {
        'user_id': userId,
        'save_data': prefsData.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await Supabase.instance.client
          .from('user_saves')
          .upsert(payload);
          
      debugPrint('☁️ [CloudSave] 클라우드 동기화 100% 완료! ${payload['updated_at']}');
      return true;
    } catch (e) {
      debugPrint('☁️ [CloudSave] 클라우드 동기화 실패: $e');
      return false;
    }
  }

  /// 클라우드 데이터를 로컬로 불러오기 (Download)
  Future<bool> syncFromCloud(String userId) async {
    try {
      if (!_isConfigured) {
        debugPrint('☁️ [CloudSave] Supabase가 아직 초기화되지 않았습니다. (.env 확인)');
        return false;
      }

      debugPrint('☁️ [CloudSave] 클라우드 데이터 다운로드 조회 중... (User ID: $userId)');

      // user_id 기준 단건 조회 (RLS 정책에 의해 본인 데이터만 Fetch 가능)
      final response = await Supabase.instance.client
          .from('user_saves')
          .select('user_id, save_data')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('☁️ [CloudSave] 클라우드에 백업된 데이터가 없습니다.');
        return false;
      }

      // 2중 방어 검증
      if (response['user_id'] != userId) {
        debugPrint('🚨 [Security] RLS 위반 의심 우회 트래픽!');
        return false;
      }

      final saveData = response['save_data'] as Map<String, dynamic>;
      
      // 불러온 데이터를 로컬 StateManager에 반영하는 로직
      final parsedState = UserState.fromJson(saveData);
      await SaveManager.instance.saveUserState(parsedState);

      debugPrint('☁️ [CloudSave] 클라우드 데이터 로컬 이식 완료!');
      return true;
    } catch (e) {
      debugPrint('☁️ [CloudSave] 클라우드 데이터 다운로드 실패: $e');
      return false;
    }
  }
}
