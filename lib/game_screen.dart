import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int? _activeBoxIndex;
  int? _activeNumber;
  String? _activeLetter;
  bool hasStarted = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGameAfterUserTap() {
    setState(() {
      hasStarted = true;
    });
    _startFlashing();
  }

  void _startFlashing() {
  _flashRandomStimuli(); // start first manually
}

void _flashRandomStimuli() async {
  int newIndex = _random.nextInt(9); // 0–8
  int newNumber = _random.nextInt(9) + 1; // 1–9
  String newLetter = String.fromCharCode(_random.nextInt(26) + 65); // A–Z

  setState(() {
    _activeBoxIndex = newIndex;
    _activeNumber = newNumber;
    _activeLetter = newLetter;
  });

  try {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('sounds/$newLetter.ogg'));
  } catch (e) {
    debugPrint('Error playing sound for $newLetter: $e');
  }

  // Hold visible state
  await Future.delayed(const Duration(milliseconds: 1300));

  setState(() {
    _activeBoxIndex = null;
    _activeNumber = null;
    _activeLetter = null;
  });

  // Optional pause between flashes
  await Future.delayed(const Duration(milliseconds: 200));

  if (hasStarted) {
    _flashRandomStimuli(); // trigger next
  }
}

  Widget _buildGridBox(int index) {
    bool isActive = index == _activeBoxIndex;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.tealAccent : Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 2),
      ),
      child: isActive && _activeNumber != null
          ? Center(
              child: Text(
                '$_activeNumber',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildGameContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          itemCount: 9,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (_, index) => _buildGridBox(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Dual N-Back Game'),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: hasStarted
            ? _buildGameContent()
            : ElevatedButton(
                onPressed: _startGameAfterUserTap,
                child: const Text('Start Game'),
              ),
      ),
    );
  }
}
