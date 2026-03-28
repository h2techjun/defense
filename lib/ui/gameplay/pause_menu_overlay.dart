// 일시정지 메뉴 오버레이 (game_screen.dart에서 추출)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/sound_manager.dart';
import '../../common/responsive.dart';
import '../../game/defense_game.dart';
import '../../l10n/app_strings.dart';
import '../../services/cloud_save_manager.dart';
import '../../state/game_state.dart';
import '../../ui/theme/app_colors.dart';

class PauseMenuOverlay extends ConsumerWidget {
  final DefenseGame game;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const PauseMenuOverlay({
    super.key,
    required this.game,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.read(gameLanguageProvider);
    final s = Responsive.uiScale(context);

    return Positioned.fill(
      child: Container(
        color: const Color(0xCC000000),
        child: Center(
          child: Container(
            width: 280 * s,
            padding: EdgeInsets.symmetric(
              vertical: 32 * s,
              horizontal: 24 * s,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pause_circle_outline,
                    color: const Color(0xFF8B5CF6), size: 48 * s),
                SizedBox(height: 12 * s),
                Text(AppStrings.get(lang, 'pause_title'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, 22),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    )),
                SizedBox(height: 8 * s),
                // 경과 시간
                Consumer(
                  builder: (_, consumerRef, __) {
                    final gs = consumerRef.watch(gameStateProvider);
                    final totalSecs = gs.elapsedSeconds.toInt();
                    final mins = totalSecs ~/ 60;
                    final secs = totalSecs % 60;
                    return Text(
                      '⏱ ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: Responsive.fontSize(context, 13),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16 * s),
                // SFX / BGM 토글
                StatefulBuilder(
                  builder: (ctx, localSetState) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSoundToggle(
                          context: context,
                          icon: SoundManager.instance.sfxEnabled
                              ? Icons.volume_up
                              : Icons.volume_off,
                          label: 'SFX',
                          active: SoundManager.instance.sfxEnabled,
                          onTap: () {
                            SoundManager.instance.toggleSfx();
                            localSetState(() {});
                          },
                        ),
                        SizedBox(width: 16 * s),
                        _buildSoundToggle(
                          context: context,
                          icon: SoundManager.instance.bgmEnabled
                              ? Icons.music_note
                              : Icons.music_off,
                          label: 'BGM',
                          active: SoundManager.instance.bgmEnabled,
                          onTap: () {
                            SoundManager.instance.toggleBgm();
                            localSetState(() {});
                          },
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20 * s),
                // 클라우드 동기화 버튼
                StatefulBuilder(
                  builder: (ctx, syncSetState) {
                    return _buildMenuButton(
                      context: context,
                      icon: CloudSaveManager.instance.isSyncing
                          ? Icons.sync
                          : Icons.cloud_upload_outlined,
                      label: CloudSaveManager.instance.isSyncing
                          ? AppStrings.get(lang, 'cloud_syncing')
                          : AppStrings.get(lang, 'cloud_save'),
                      color: const Color(0xFF3B82F6),
                      onTap: () async {
                        syncSetState(() {});
                        final result = await CloudSaveManager.instance.appStartSync();
                        syncSetState(() {});
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result == CloudSyncResult.success
                                    ? AppStrings.get(lang, 'cloud_sync_success')
                                    : result == CloudSyncResult.notConfigured
                                        ? AppStrings.get(lang, 'cloud_sync_not_configured')
                                        : AppStrings.get(lang, 'cloud_sync_failed'),
                              ),
                              backgroundColor: result == CloudSyncResult.success
                                  ? Colors.green
                                  : Colors.orange,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
                SizedBox(height: 8 * s),
                // 마지막 동기화 시간
                Text(
                  (() { final sync = CloudSaveManager.instance.lastSyncTimeFormatted; return sync == 'no_sync_record' ? tr(ref, sync) : sync; })(),
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: Responsive.fontSize(context, 10),
                  ),
                ),
                // 계속하기 버튼
                _buildMenuButton(
                  context: context,
                  icon: Icons.play_arrow_rounded,
                  label: AppStrings.get(lang, 'pause_resume'),
                  color: const Color(0xFF10B981),
                  onTap: onResume,
                ),
                SizedBox(height: 12 * s),
                // 재시작 버튼
                _buildMenuButton(
                  context: context,
                  icon: Icons.refresh_rounded,
                  label: AppStrings.get(lang, 'pause_restart_label'),
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    _showConfirmDialog(
                      context: context,
                      ref: ref,
                      title: AppStrings.get(lang, 'pause_restart_title'),
                      message: AppStrings.get(lang, 'pause_restart_msg'),
                      onConfirm: onRestart,
                    );
                  },
                ),
                SizedBox(height: 12 * s),
                // 메뉴로 나가기 버튼
                _buildMenuButton(
                  context: context,
                  icon: Icons.home_rounded,
                  label: AppStrings.get(lang, 'pause_exit_label'),
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    _showConfirmDialog(
                      context: context,
                      ref: ref,
                      title: AppStrings.get(lang, 'pause_exit_title'),
                      message: AppStrings.get(lang, 'pause_exit_msg'),
                      onConfirm: onExit,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final s = Responsive.uiScale(context);
    return SizedBox(
      width: double.infinity,
      height: 48 * s,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 22 * s),
        label: Text(label,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.fontSize(context, 15),
              fontWeight: FontWeight.w600,
            )),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSoundToggle({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final s = Responsive.uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
        decoration: BoxDecoration(
          color: active ? const Color(0x338B5CF6) : const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF8B5CF6) : const Color(0x44FFFFFF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.white : Colors.white38, size: 20 * s),
            SizedBox(width: 6 * s),
            Text(label, style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontSize: Responsive.fontSize(context, 12),
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    final lang = ref.read(gameLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.buttonRadius),
          side: const BorderSide(color: AppColors.borderAccent, width: 1),
        ),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get(lang, 'btn_cancel'), style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.berserkRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppStrings.get(lang, 'btn_confirm'), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
