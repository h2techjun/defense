
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/user_state.dart';
import 'save_manager.dart';
import '../common/debug_log.dart';

/// 동기화 결과 상태
enum CloudSyncResult {
  success,         // 정상 동기화 완료
  noLocalData,     // 로컬 데이터 없음
  noCloudData,     // 클라우드 데이터 없음
  conflict,        // 충돌 발생 (사용자 선택 필요)
  notConfigured,   // Supabase 미설정
  error,           // 네트워크 에러
}

/// 동기화 방향
enum SyncDirection {
  upload,    // 로컬 → 클라우드
  download,  // 클라우드 → 로컬
}

/// 클라우드 세이브(백업) 동기화 매니저
/// Supabase Database와 연동하여 유저 데이터를 관리합니다.
class CloudSaveManager {
  static CloudSaveManager? _instance;
  static CloudSaveManager get instance => _instance ??= CloudSaveManager._();
  CloudSaveManager._();

  /// 마지막 동기화 시간
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// 디바이스 고유 ID (인증 없이 클라우드 세이브 식별용)
  String? _deviceId;

  /// 디바이스 ID 조회/생성 (최초 1회 UUID 생성 후 영구 저장)
  Future<String> getDeviceUserId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('haewon_device_id');
    if (id == null || id.isEmpty) {
      // UUID v4 간이 생성
      final rng = Random.secure();
      id = '${_hex(rng, 8)}-${_hex(rng, 4)}-4${_hex(rng, 3)}-${_hex(rng, 4)}-${_hex(rng, 12)}';
      await prefs.setString('haewon_device_id', id);
      dlog('☁️ [CloudSave] 새 디바이스 ID 생성: $id');
    }
    _deviceId = id;
    return id;
  }

  String _hex(Random rng, int length) {
    const chars = '0123456789abcdef';
    return List.generate(length, (_) => chars[rng.nextInt(16)]).join();
  }

  /// 동기화 중 여부 (중복 호출 방지)
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// 클라우드 세이브 활성화 여부
  bool _cloudSaveEnabled = true;
  bool get cloudSaveEnabled => _cloudSaveEnabled;
  void setCloudSaveEnabled(bool enabled) {
    _cloudSaveEnabled = enabled;
  }

  bool get _isConfigured {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 스마트 동기화: 로컬 vs 클라우드 타임스탬프를 비교하여 최신본을 자동 선택
  /// 
  /// 결과: [CloudSyncResult] — conflict인 경우 UI에서 사용자 선택 요청
  Future<CloudSyncResult> syncSmartly(String userId) async {
    if (!_cloudSaveEnabled) return CloudSyncResult.notConfigured;
    if (!_isConfigured) return CloudSyncResult.notConfigured;
    if (_isSyncing) return CloudSyncResult.success; // 이미 동기화 중

    _isSyncing = true;
    try {
      // 1. 로컬 데이터 및 타임스탬프 조회
      final localState = await SaveManager.instance.loadUserState();
      final localTimestamp = await SaveManager.instance.getLastSaveTimestamp();

      // 2. 클라우드 데이터 조회
      final cloudRow = await _fetchCloudData(userId);

      // Case A: 둘 다 없음 → 할 일 없음
      if (localState == null && cloudRow == null) {
        return CloudSyncResult.noLocalData;
      }

      // Case B: 로컬만 있음 → 업로드
      if (localState != null && cloudRow == null) {
        final uploaded = await syncToCloud(userId);
        return uploaded ? CloudSyncResult.success : CloudSyncResult.error;
      }

      // Case C: 클라우드만 있음 → 다운로드
      if (localState == null && cloudRow != null) {
        final downloaded = await syncFromCloud(userId);
        return downloaded ? CloudSyncResult.success : CloudSyncResult.error;
      }

      // Case D: 둘 다 있음 → 타임스탬프 비교
      final cloudUpdatedAt = DateTime.tryParse(
        cloudRow!['updated_at'] as String? ?? '',
      );

      if (cloudUpdatedAt == null || localTimestamp == null) {
        // 타임스탬프 비교 불가 → 로컬 우선 (더 안전)
        final uploaded = await syncToCloud(userId);
        return uploaded ? CloudSyncResult.success : CloudSyncResult.error;
      }

      final diff = localTimestamp.difference(cloudUpdatedAt);

      if (diff.inSeconds.abs() < 5) {
        // 5초 이내 차이 → 동일로 간주
        _lastSyncTime = DateTime.now();
        return CloudSyncResult.success;
      }

      if (diff.isNegative) {
        // 클라우드가 더 최신 → 다운로드
        final downloaded = await syncFromCloud(userId);
        return downloaded ? CloudSyncResult.success : CloudSyncResult.error;
      } else {
        // 로컬이 더 최신 → 업로드
        final uploaded = await syncToCloud(userId);
        return uploaded ? CloudSyncResult.success : CloudSyncResult.error;
      }
    } catch (e) {
      dlog('☁️ [CloudSave] 스마트 동기화 실패: $e');
      return CloudSyncResult.error;
    } finally {
      _isSyncing = false;
    }
  }

  /// 클라우드 데이터 조회 (내부 헬퍼)
  Future<Map<String, dynamic>?> _fetchCloudData(String userId) async {
    try {
      return await Supabase.instance.client
          .from('user_saves')
          .select('user_id, save_data, updated_at')
          .eq('user_id', userId)
          .maybeSingle();
    } catch (e) {
      dlog('☁️ [CloudSave] 클라우드 데이터 조회 실패: $e');
      return null;
    }
  }

  /// 로컬 데이터를 클라우드로 동기화 (Upload)
  Future<bool> syncToCloud(String userId) async {
    try {
      if (!_isConfigured) {
        dlog('☁️ [CloudSave] Supabase가 아직 초기화되지 않았습니다. (.env 확인)');
        return false;
      }
      
      dlog('☁️ [CloudSave] Supabase DB 동기화 시작... (User ID: $userId)');

      // 로컬 데이터 수집
      final prefsData = await SaveManager.instance.loadUserState();
      if (prefsData == null) {
        dlog('☁️ [CloudSave] 업로드할 로컬 데이터가 없습니다.');
        return false;
      }

      final now = DateTime.now();
      // Supabase 테이블 `user_saves` 에 UPSERT 실행
      final payload = {
        'user_id': userId,
        'save_data': prefsData.toJson(),
        'updated_at': now.toIso8601String(),
      };
      
      await Supabase.instance.client
          .from('user_saves')
          .upsert(payload);
          
      _lastSyncTime = now;
      dlog('☁️ [CloudSave] 클라우드 동기화 100% 완료! ${payload['updated_at']}');
      return true;
    } catch (e) {
      dlog('☁️ [CloudSave] 클라우드 동기화 실패: $e');
      return false;
    }
  }

  /// 클라우드 데이터를 로컬로 불러오기 (Download)
  Future<bool> syncFromCloud(String userId) async {
    try {
      if (!_isConfigured) {
        dlog('☁️ [CloudSave] Supabase가 아직 초기화되지 않았습니다. (.env 확인)');
        return false;
      }

      dlog('☁️ [CloudSave] 클라우드 데이터 다운로드 조회 중... (User ID: $userId)');

      // user_id 기준 단건 조회 (RLS 정책에 의해 본인 데이터만 Fetch 가능)
      final response = await Supabase.instance.client
          .from('user_saves')
          .select('user_id, save_data, updated_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        dlog('☁️ [CloudSave] 클라우드에 백업된 데이터가 없습니다.');
        return false;
      }

      // 2중 방어 검증
      if (response['user_id'] != userId) {
        dlog('🚨 [Security] RLS 위반 의심 우회 트래픽!');
        return false;
      }

      final saveData = response['save_data'] as Map<String, dynamic>;
      
      // 불러온 데이터를 로컬 StateManager에 반영하는 로직
      final parsedState = UserState.fromJson(saveData);
      await SaveManager.instance.saveUserState(parsedState);

      _lastSyncTime = DateTime.now();
      dlog('☁️ [CloudSave] 클라우드 데이터 로컬 이식 완료!');
      return true;
    } catch (e) {
      dlog('☁️ [CloudSave] 클라우드 데이터 다운로드 실패: $e');
      return false;
    }
  }

  /// 스테이지 클리어 시 자동 동기화 (fire-and-forget)
  /// 게임 흐름을 차단하지 않기 위해 결과를 무시합니다.
  /// userId 파라미터는 더 이상 사용하지 않음 — deviceId로 자동 처리
  void autoSyncOnStageClear([String? userId]) {
    if (!_cloudSaveEnabled) return;
    if (!_isConfigured) return;
    // 비동기로 실행 — 게임 루프 차단 방지
    Future.microtask(() async {
      try {
        final id = await getDeviceUserId();
        await syncToCloud(id);
      } catch (e) {
        dlog('☁️ [CloudSave] 자동 동기화 실패 (무시): $e');
      }
    });
  }

  /// 앱 시작 시 클라우드 스마트 동기화 (game_screen initState에서 호출)
  Future<CloudSyncResult> appStartSync() async {
    if (!_cloudSaveEnabled || !_isConfigured) return CloudSyncResult.notConfigured;
    try {
      final id = await getDeviceUserId();
      return await syncSmartly(id);
    } catch (e) {
      dlog('☁️ [CloudSave] 앱 시작 동기화 실패: $e');
      return CloudSyncResult.error;
    }
  }

  /// 마지막 동기화 시간 포맷팅 (UI 표시용)
  String get lastSyncTimeFormatted {
    if (_lastSyncTime == null) return 'No sync record';
    final t = _lastSyncTime!;
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
           '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
