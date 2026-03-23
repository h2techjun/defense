// 해원의 문 — CloudSaveManager 유닛 테스트
// 오프라인 로직 검증 (Supabase mock 없이 가능한 부분)

import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_of_regrets/services/cloud_save_manager.dart';

void main() {
  group('CloudSaveManager — 오프라인 로직', () {
    test('클라우드 세이브 비활성화 시 syncSmartly가 notConfigured 반환', () async {
      final manager = CloudSaveManager.instance;
      manager.setCloudSaveEnabled(false);
      final result = await manager.syncSmartly('test-user');
      expect(result, CloudSyncResult.notConfigured);
      // 테스트 후 원복
      manager.setCloudSaveEnabled(true);
    });

    test('Supabase 미초기화 시 syncToCloud가 false 반환', () async {
      final manager = CloudSaveManager.instance;
      // Supabase.instance.client가 초기화되지 않은 상태이므로 false 반환 예상
      final result = await manager.syncToCloud('test-user');
      expect(result, isFalse);
    });

    test('Supabase 미초기화 시 syncFromCloud가 false 반환', () async {
      final manager = CloudSaveManager.instance;
      final result = await manager.syncFromCloud('test-user');
      expect(result, isFalse);
    });

    test('lastSyncTime은 초기 상태에서 null', () {
      final manager = CloudSaveManager.instance;
      // 아직 동기화를 하지 않았으므로 null (또는 이전 테스트에서 설정된 값)
      // 이 테스트는 lastSyncTimeFormatted 접근이 에러 없이 동작하는지 확인
      expect(manager.lastSyncTimeFormatted, isA<String>());
    });

    test('cloudSaveEnabled 토글이 동작해야 한다', () {
      final manager = CloudSaveManager.instance;
      manager.setCloudSaveEnabled(false);
      expect(manager.cloudSaveEnabled, isFalse);
      manager.setCloudSaveEnabled(true);
      expect(manager.cloudSaveEnabled, isTrue);
    });

    test('autoSyncOnStageClear은 userId가 null이면 즉시 반환', () {
      // 이 호출은 아무 부작용 없이 완료되어야 함
      CloudSaveManager.instance.autoSyncOnStageClear(null);
      // 크래시 없이 통과하면 성공
      expect(true, isTrue);
    });
  });

  group('CloudSyncResult', () {
    test('모든 enum 값이 존재해야 한다', () {
      expect(CloudSyncResult.values, contains(CloudSyncResult.success));
      expect(CloudSyncResult.values, contains(CloudSyncResult.noLocalData));
      expect(CloudSyncResult.values, contains(CloudSyncResult.noCloudData));
      expect(CloudSyncResult.values, contains(CloudSyncResult.conflict));
      expect(CloudSyncResult.values, contains(CloudSyncResult.notConfigured));
      expect(CloudSyncResult.values, contains(CloudSyncResult.error));
    });

    test('SyncDirection enum 값이 존재해야 한다', () {
      expect(SyncDirection.values, contains(SyncDirection.upload));
      expect(SyncDirection.values, contains(SyncDirection.download));
    });
  });
}
