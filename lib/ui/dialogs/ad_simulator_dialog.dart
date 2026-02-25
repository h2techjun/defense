import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AdSimulatorDialog extends StatefulWidget {
  final VoidCallback onRewardEarned;

  const AdSimulatorDialog({super.key, required this.onRewardEarned});

  @override
  State<AdSimulatorDialog> createState() => _AdSimulatorDialogState();
}

class _AdSimulatorDialogState extends State<AdSimulatorDialog> {
  int _timeLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canClose = _timeLeft == 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withAlpha(230),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sinmyeongGold),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library, size: 48, color: AppColors.lavender),
            const SizedBox(height: 16),
            const Text(
              '광고 시청 중... (Simulation)',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              canClose ? '보상 지급 완료!' : '$_timeLeft초 뒤 연속된 보상이 지급됩니다.',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!canClose)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기 (보상 없음)', style: TextStyle(color: Colors.grey)),
                  ),
                if (canClose)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.sinmyeongGold),
                    onPressed: () {
                      widget.onRewardEarned();
                      Navigator.of(context).pop();
                    },
                    child: const Text('보상 받기', style: TextStyle(color: AppColors.bgDeepPlum, fontWeight: FontWeight.bold)),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
