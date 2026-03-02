import 'package:flutter/material.dart';

/// 단일 캐릭터 이미지(1:1 비율)를 보여주는 공용 위젯
/// 스프라이트 시트 크롭 불필요 — 이미지 전체가 한 캐릭터
class HeroSpriteViewer extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final String fallbackText;

  const HeroSpriteViewer({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    this.fallbackText = '?',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            fallbackText,
            style: TextStyle(fontSize: height * 0.5, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
