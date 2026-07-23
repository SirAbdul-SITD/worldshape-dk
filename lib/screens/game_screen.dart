import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/puzzle.dart';
import '../painters/silhouette_painter.dart';
import '../services/palette.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import '../services/audio_manager.dart';

class GameScreen extends StatefulWidget {
  final Puzzle puzzle;
  final AudioManager audio;
  final VoidCallback? onNext;
  const GameScreen({
    super.key,
    required this.puzzle,
    required this.audio,
    this.onNext,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int? selectedIndex;
  bool answered = false;
  int wrongCount = 0;
  bool won = false;

  void _haptic() {
    if (context.read<SettingsService>().haptics) {
      HapticFeedback.selectionClick();
    }
  }

  void _choose(int index) {
    if (answered) return;
    setState(() {
      selectedIndex = index;
    });
    if (index == widget.puzzle.answerIndex) {
      widget.audio.correct();
      _haptic();
      setState(() {
        answered = true;
        won = true;
      });
      final stars = _starRating();
      context.read<ProgressService>().recordWin(widget.puzzle.id, stars);
      widget.audio.win();
      Future.delayed(const Duration(milliseconds: 500), _showWinSheet);
    } else {
      widget.audio.wrong();
      _haptic();
      setState(() {
        wrongCount++;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => selectedIndex = null);
      });
    }
  }

  int _starRating() {
    if (wrongCount == 0) return 3;
    if (wrongCount == 1) return 2;
    return 1;
  }

  void _showWinSheet() {
    final stars = _starRating();
    showModalBottomSheet(
      context: context,
      backgroundColor: Palette.panel,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.puzzle.country,
                style: const TextStyle(
                    color: Palette.ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Correct!',
                style: TextStyle(color: Palette.correct, fontSize: 15)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: i < stars ? Palette.brass : Palette.haze,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.ink,
                      side: const BorderSide(color: Palette.line),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Levels'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.brass,
                      foregroundColor: Palette.void_,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      widget.onNext?.call();
                    },
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      selectedIndex = null;
      answered = false;
      wrongCount = 0;
      won = false;
    });
    widget.audio.tap();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    return Scaffold(
      backgroundColor: Palette.void_,
      appBar: AppBar(
        backgroundColor: Palette.void_,
        elevation: 0,
        foregroundColor: Palette.ink,
        title: Text('Level ${p.id + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Which country is this?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Palette.haze, fontSize: 13, height: 1.4),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Palette.parchment,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Palette.brass.withValues(alpha: 0.4), width: 1.4),
                  ),
                  child: CustomPaint(
                    painter: SilhouettePainter(puzzle: p),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.6,
                  ),
                  itemCount: p.options.length,
                  itemBuilder: (context, i) {
                    final isAnswer = i == p.answerIndex;
                    final isSel = i == selectedIndex;
                    Color bg = Palette.raised;
                    Color fg = Palette.ink;
                    Color border = Palette.line;
                    if (answered && isAnswer) {
                      bg = Palette.correct;
                      fg = Palette.void_;
                      border = Palette.correct;
                    } else if (isSel && !isAnswer) {
                      bg = Palette.wrong;
                      fg = Palette.void_;
                      border = Palette.wrong;
                    }
                    return GestureDetector(
                      onTap: () => _choose(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border, width: 1.4),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          p.options[i],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mistakes: $wrongCount',
                      style: const TextStyle(color: Palette.haze, fontSize: 14)),
                  Text(p.tier.toUpperCase(),
                      style: TextStyle(
                          color: Palette.tierColors[p.tier],
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
