// 해원의 문 - 스테이지 선택 화면 (3챕터 탭 지원)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/enums.dart';
import '../../common/responsive.dart';
import '../../data/game_data_loader.dart';
import '../../data/models/wave_data.dart';
import '../../l10n/app_strings.dart';
import '../../state/user_state.dart';
import '../theme/app_colors.dart';
import '../theme/themed_scaffold.dart';
import '../widgets/touch_button.dart';

/// 챕터 메타데이터
class _ChapterMeta {
  final Chapter chapter;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final int chapterNumber;

  const _ChapterMeta({
    required this.chapter,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.chapterNumber,
  });
}

const _chapters = <_ChapterMeta>[
  _ChapterMeta(
    chapter: Chapter.marketOfHunger,
    title: '굶주린 시장',
    subtitle: 'Market of Hunger',
    gradientColors: [AppColors.lavender, Color(0xFFFFAA44)],
    chapterNumber: 1,
  ),
  _ChapterMeta(
    chapter: Chapter.wailingWoods,
    title: '통곡하는 숲',
    subtitle: 'Wailing Woods',
    gradientColors: [Color(0xFF44CC88), Color(0xFF88DDAA)],
    chapterNumber: 2,
  ),
  _ChapterMeta(
    chapter: Chapter.facelessForest,
    title: '얼굴 없는 숲',
    subtitle: 'Faceless Forest',
    gradientColors: [Color(0xFFFF6666), Color(0xFFDD88FF)],
    chapterNumber: 3,
  ),
  _ChapterMeta(
    chapter: Chapter.shadowPalace,
    title: '왕궁의 그림자',
    subtitle: 'Shadow Palace',
    gradientColors: [Color(0xFF6644AA), Color(0xFF221144)],
    chapterNumber: 4,
  ),
  _ChapterMeta(
    chapter: Chapter.thresholdOfDeath,
    title: '저승의 문턱',
    subtitle: 'Threshold of Death',
    gradientColors: [Color(0xFF111111), Color(0xFF660000)],
    chapterNumber: 5,
  ),
];

/// 스테이지 선택 화면
class StageSelectScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final void Function(LevelData level) onLevelSelected;

  const StageSelectScreen({
    super.key,
    required this.onBack,
    required this.onLevelSelected,
  });

  @override
  ConsumerState<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends ConsumerState<StageSelectScreen> {
  int _selectedChapter = 0;

  @override
  Widget build(BuildContext context) {
    final meta = _chapters[_selectedChapter];
    final levels = GameDataLoader.getLevelsForChapterSafe(meta.chapter);
    final userState = ref.watch(userStateProvider);
    final lang = ref.watch(gameLanguageProvider);
    final chapterKey = 'chapter_${meta.chapterNumber}';



    return ThemedScaffold(
    backgroundColor: AppColors.scaffoldBg,
    backgroundAsset: 'assets/images/bg/bg_stage_select.png',
    body: Column(
            children: [
              // ── 헤더 ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * Responsive.scale(context), vertical: 12 * Responsive.scale(context)),
                child: Row(
                  children: [
                    TouchButton(
                    onTap: widget.onBack,
                    borderRadius: BorderRadius.circular(10),
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x44FFFFFF)),
                    ),
                    padding: EdgeInsets.all(8 * Responsive.scale(context)),
                    child: Icon(Icons.arrow_back,
                        color: AppColors.lavender, size: 22 * Responsive.scale(context)),
                  ),
                    SizedBox(width: 16 * Responsive.scale(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: meta.gradientColors,
                            ).createShader(bounds),
                            child: Text(
                              AppStrings.get(lang, chapterKey),
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 22),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            'Chapter ${meta.chapterNumber}: ${meta.subtitle}',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 12),
                              color: const Color(0xFF8866AA),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 총 별 수 표시
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12 * Responsive.scale(context), vertical: 6 * Responsive.scale(context)),
                      decoration: BoxDecoration(
                        color: const Color(0x22FFD700),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x44FFD700)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('⭐', style: TextStyle(fontSize: Responsive.fontSize(context, 14))),
                          SizedBox(width: 4 * Responsive.scale(context)),
                          Text(
                            '${userState.totalStars} / ${levels.length * 3}',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 14),
                              fontWeight: FontWeight.bold,
                              color: AppColors.sinmyeongGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── 챕터 탭 ──
              SizedBox(
                height: 44 * Responsive.scale(context),
                child: Row(
                  children: List.generate(_chapters.length, (i) {
                    final ch = _chapters[i];
                    final isSelected = i == _selectedChapter;

                    // 챕터 잠금: 이전 챕터 마지막 스테이지 별≥1 필요
                    bool isChapterLocked = false;
                    if (i > 0) {
                      final prevChapter = _chapters[i - 1];
                      final prevLevels = GameDataLoader.getLevelsForChapterSafe(prevChapter.chapter);
                      if (prevLevels.isNotEmpty) {
                        final lastLevel = prevLevels.last;
                        final lastStars = userState.getStars(prevChapter.chapterNumber, lastLevel.levelNumber);
                        isChapterLocked = lastStars <= 0;
                      }
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: isChapterLocked
                            ? null
                            : () => setState(() => _selectedChapter = i),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4 * Responsive.scale(context)),
                          decoration: BoxDecoration(
                            color: isChapterLocked
                                ? const Color(0x08FFFFFF)
                                : isSelected
                                    ? Color.lerp(ch.gradientColors[0], Colors.black, 0.6)
                                    : const Color(0x11FFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isChapterLocked
                                  ? const Color(0x11FFFFFF)
                                  : isSelected
                                      ? ch.gradientColors[0].withValues(alpha: 0.6)
                                      : const Color(0x22FFFFFF),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isChapterLocked) ...[
                                Icon(Icons.lock, size: 12 * Responsive.scale(context), color: const Color(0x44FFFFFF)),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                'Ep.${ch.chapterNumber}',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 13),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isChapterLocked
                                      ? const Color(0x44FFFFFF)
                                      : isSelected
                                          ? ch.gradientColors[0]
                                          : const Color(0xFF776699),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              SizedBox(height: 8 * Responsive.scale(context)),
              const Divider(color: Color(0x22FFFFFF), height: 1),
              SizedBox(height: 8 * Responsive.scale(context)),

              // ── 스테이지 그리드 ──
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12 * Responsive.scale(context)),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 120 * Responsive.scale(context),
                      crossAxisSpacing: 8 * Responsive.scale(context),
                      mainAxisSpacing: 8 * Responsive.scale(context),
                      childAspectRatio: 0.88,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final stars = userState.getStars(meta.chapterNumber, level.levelNumber);
                      // 잠금 판별: 첫 스테이지는 항상 열림, 이후는 이전 스테이지 별≥1 필요
                      bool isLocked = false;
                      if (index > 0) {
                        final prevLevel = levels[index - 1];
                        final prevStars = userState.getStars(meta.chapterNumber, prevLevel.levelNumber);
                        isLocked = prevStars <= 0;
                      }
                      return _StageCard(
                        level: level,
                        stars: stars,
                        isLocked: isLocked,
                        onTap: isLocked ? null : () => widget.onLevelSelected(level),
                      );
                    },
                  ),
                ),
              ),

              // ── 하단 인용구 ──
              Padding(
                padding: EdgeInsets.all(12 * Responsive.scale(context)),
                child: Text(
                  '"해원문을 지키는 자, 원한을 꽃으로 바꾸리라."',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 13),
                    color: Color(0xFF665588),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

/// 스테이지 카드
class _StageCard extends StatelessWidget {
  final LevelData level;
  final int stars;
  final bool isLocked;
  final VoidCallback? onTap;

  const _StageCard({
    required this.level,
    required this.stars,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 보스 스테이지 감지 (10의 배수)
    final isBoss = level.levelNumber % 10 == 0;
    final isCleared = stars > 0;

    // 잠금 상태 — 어둡게 + 탭 불가
    if (isLocked) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F0A1A).withAlpha(180),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x22FFFFFF), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: const Color(0xFF554466), size: Responsive.iconSize(context, 22)),
                SizedBox(height: 2 * Responsive.scale(context)),
                Text(
                  '${level.levelNumber}',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF443355),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isBoss
                ? [const Color(0xFF3D1155).withAlpha(220), const Color(0xFF551133).withAlpha(220)]
                : isCleared
                    ? [const Color(0xFF112233).withAlpha(200), const Color(0xFF1A3344).withAlpha(200)]
                    : [const Color(0xFF1A1133).withAlpha(200), const Color(0xFF221144).withAlpha(200)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBoss
                ? const Color(0xFFFF6644)
                : isCleared
                    ? const Color(0x66FFD700)
                    : const Color(0x44AA66DD),
            width: isBoss ? 1.5 : 1,
          ),
          boxShadow: isBoss
              ? const [
                  BoxShadow(
                    color: Color(0x33FF4400),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : isCleared
                  ? const [
                      BoxShadow(
                        color: Color(0x22FFD700),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 스테이지 번호
            Text(
              '${level.levelNumber}',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, isBoss ? 24 : 20),
                fontWeight: FontWeight.bold,
                color: isBoss
                    ? const Color(0xFFFF8844)
                    : isCleared
                        ? const Color(0xFFFFD700)
                        : AppColors.lavender,
              ),
            ),
            SizedBox(height: 2 * Responsive.scale(context)),

            // 별 표시 (채워진 별 / 빈 별)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final isFilled = i < stars;
                return Text(
                  isFilled ? '★' : '☆',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 14),
                    color: isFilled
                        ? AppColors.sinmyeongGold
                        : const Color(0xFF554466),
                  ),
                );
              }),
            ),
            SizedBox(height: 2 * Responsive.scale(context)),

            // 스테이지 이름
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4 * Responsive.scale(context)),
                child: Text(
                  level.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 11),
                    color: Color(0xFFAA99BB),
                    height: 1.1,
                  ),
                ),
              ),
            ),
            SizedBox(height: 2 * Responsive.scale(context)),

            // 웨이브 수
            Text(
              '🌊 ${level.waves.length}',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 10),
                color: const Color(0xFF8877AA),
              ),
            ),

            // 보스 표시
            if (isBoss)
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('💀 BOSS',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 10),
                      color: Color(0xFFFF6644),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    )),
              ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
