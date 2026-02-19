// 해원의 문 - 맵 오브젝트 데이터 모델
// GDD 섹션 7.2 인터랙티브 맵 오브젝트 사양 기반

import '../../common/enums.dart';

/// 맵 오브젝트의 정적 데이터 (JSON에서 로드)
class MapObjectData {
  /// 오브젝트 종류
  final MapObjectType type;

  /// 그리드 좌표 (타일 단위)
  final int gridX;
  final int gridY;

  /// 활성화 비용 (신명). 0 = 무료
  final int cost;

  /// 효과 범위 (타일 단위). 0 = 비범위 효과
  final double effectRadius;

  const MapObjectData({
    required this.type,
    required this.gridX,
    required this.gridY,
    required this.cost,
    this.effectRadius = 0,
  });

  /// JSON → MapObjectData
  factory MapObjectData.fromJson(Map<String, dynamic> json) {
    return MapObjectData(
      type: MapObjectType.values.firstWhere((e) => e.name == json['type']),
      gridX: json['gridX'] as int,
      gridY: json['gridY'] as int,
      cost: json['cost'] as int,
      effectRadius: (json['effectRadius'] as num?)?.toDouble() ?? 0,
    );
  }

  /// MapObjectData → JSON
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'gridX': gridX,
    'gridY': gridY,
    'cost': cost,
    if (effectRadius > 0) 'effectRadius': effectRadius,
  };

  /// 타입별 기본 비용 (JSON에 cost 미지정 시 폴백)
  static int defaultCost(MapObjectType type) {
    switch (type) {
      case MapObjectType.shrine:
        return 50;
      case MapObjectType.oldWell:
        return 30;
      case MapObjectType.torch:
        return 20;
      case MapObjectType.mapSotdae:
        return 40;
      case MapObjectType.tomb:
        return 60;
      case MapObjectType.sacredTree:
        return 0;
    }
  }

  /// 타입별 기본 효과 범위
  static double defaultRadius(MapObjectType type) {
    switch (type) {
      case MapObjectType.shrine:
        return 3.0;
      case MapObjectType.oldWell:
        return 0; // 비범위 (스테이지 전체 효과)
      case MapObjectType.torch:
        return 2.5;
      case MapObjectType.mapSotdae:
        return 3.0;
      case MapObjectType.tomb:
        return 0; // 비범위 (소환 효과)
      case MapObjectType.sacredTree:
        return 0; // 비범위 (글로벌 효과)
    }
  }
}
