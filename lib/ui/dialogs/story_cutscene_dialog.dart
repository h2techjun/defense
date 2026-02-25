import 'package:flutter/material.dart';
import '../../data/models/story_data.dart';
import '../../audio/sound_manager.dart';
import '../theme/app_colors.dart';

class StoryCutsceneDialog extends StatefulWidget {
  final List<StoryScene> scenes;
  final VoidCallback onFinish;

  const StoryCutsceneDialog({
    super.key,
    required this.scenes,
    required this.onFinish,
  });

  @override
  State<StoryCutsceneDialog> createState() => _StoryCutsceneDialogState();
}

class _StoryCutsceneDialogState extends State<StoryCutsceneDialog>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isTyping = true;
  String _displayedText = '';
  int _charIndex = 0;

  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _startTyping();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _startTyping() {
    setState(() {
      _isTyping = true;
      _displayedText = '';
      _charIndex = 0;
    });
    _typeNextChar();
  }

  void _typeNextChar() {
    if (!mounted) return;
    final currentScene = widget.scenes[_currentIndex];
    if (_charIndex < currentScene.text.length) {
      setState(() {
        _displayedText += currentScene.text[_charIndex];
        _charIndex++;
      });
      
      if (_displayedText.isNotEmpty && _displayedText[_displayedText.length - 1] != ' ') {
        SoundManager.instance.playSfx(SfxType.storyTyping);
      }
      
      Future.delayed(const Duration(milliseconds: 30), _typeNextChar);
    } else {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _skipOrNext() {
    if (_isTyping) {
      // 스킵하여 텍스트 전체 즉시 표시
      setState(() {
        _displayedText = widget.scenes[_currentIndex].text;
        _isTyping = false;
        _charIndex = widget.scenes[_currentIndex].text.length;
      });
    } else {
      // 다음 씬으로 넘어가기
      if (_currentIndex < widget.scenes.length - 1) {
        setState(() {
          _currentIndex++;
          _animCtrl.forward(from: 0.0);
        });
        _startTyping();
      } else {
        // 끝
        widget.onFinish();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scenes[_currentIndex];
    
    // 캐릭터 초상화 에셋 파싱 로직 (만약 제공되지 않았다면 기본 플레이스홀더 렌더링)
    // 실제 스프라이트 경로를 정확히 맞추기 위해, 임시로 Container나 CircleAvatar로 매핑 가능
    Widget buildPortrait(bool isCurrentSide) {
      if (!isCurrentSide || scene.portraitAsset == null) {
        return const SizedBox(width: 100); 
      }
      return FadeTransition(
        opacity: _animCtrl,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(scene.side == SpeakerSide.left ? -0.2 : 0.2, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic)),
          child: Image.asset(
            scene.portraitAsset!,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.person,
              size: 80,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _skipOrNext, // 화면 아무 곳이나 터치하면 다음/스킵
        child: Stack(
          children: [
            // 전체 배경 약간 어둡게
            Container(color: Colors.black.withOpacity(0.6)),
            
            // 다이얼로그 박스 (하단 배치)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 화자 초상화 (좌/우 배치)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          buildPortrait(scene.side == SpeakerSide.left),
                          buildPortrait(scene.side == SpeakerSide.right),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 텍스트 박스
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMid.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cherryBlossom.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cherryBlossom.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 화자 이름
                            Text(
                              scene.speakerName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: scene.nameColor ?? AppColors.cherryBlossom,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 대화 내용
                            Text(
                              _displayedText,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                            
                            // 텍스트 출력 완료시 화살표/안내 아이콘
                            if (!_isTyping)
                              const Align(
                                alignment: Alignment.bottomRight,
                                child: Icon(Icons.arrow_drop_down, color: AppColors.cherryBlossom),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 스킵 옵션
            Positioned(
              top: 40,
              right: 20,
              child: TextButton.icon(
                onPressed: widget.onFinish,
                icon: const Icon(Icons.skip_next, color: Colors.white70),
                label: const Text('건너뛰기', style: TextStyle(color: Colors.white70)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
