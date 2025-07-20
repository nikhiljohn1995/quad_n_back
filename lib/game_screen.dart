import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

enum StimulusType { grid, sound, number, pattern }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _selectedN = 2;
  String _selectedMode = 'Dual';
  bool hasStarted = false;
  int? _activeBoxIndex;
  String? _activeLetter;
  int? _activeNumber;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  List<Map<StimulusType, dynamic>> sequence = [];
  Map<StimulusType, Set<(int, int)>> matchSets = {};
  int currentIndex = 0;

  final Map<String, List<StimulusType>> modes = {
    'Single': [StimulusType.grid],
    'Dual': [StimulusType.grid, StimulusType.sound],
    'Triple': [StimulusType.grid, StimulusType.sound, StimulusType.number],
    'Quad': [StimulusType.grid, StimulusType.sound, StimulusType.number] // Add pattern later
  };

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGame() {
    final n = _selectedN;
    final types = modes[_selectedMode]!;
    final length = 20 + (n - 1) * 5;

    final pairsPerType = 5 + (n - 1) * 2;
    matchSets = {};
    sequence = List.generate(length, (_) => {});

    for (var type in types) {
      final allPairs = List.generate(length - n, (i) => (i, i + n));
      allPairs.shuffle(_random);
      final selectedPairs = allPairs.take(pairsPerType).toSet();
      matchSets[type] = selectedPairs;

      List<dynamic> getOptions() {
        switch (type) {
          case StimulusType.grid:
            return List.generate(9, (i) => i)..shuffle(_random);
          case StimulusType.sound:
            return List.generate(26, (i) => String.fromCharCode(65 + i))..shuffle(_random);
          case StimulusType.number:
            return List.generate(9, (i) => i + 1)..shuffle(_random);
          case StimulusType.pattern:
            return List.generate(4, (i) => 'P$i')..shuffle(_random);
        }
      }

      for (int i = 0; i < length - n; i++) {
        final j = i + n;
        if (sequence[i][type] == null) {
          if (selectedPairs.contains((i, j))) {
            final val = getOptions().first;
            sequence[i][type] = val;
            sequence[j][type] = val;
          } else {
            final opts = getOptions();
            final v1 = opts[0];
            final v2 = opts.firstWhere((e) => e != v1);
            sequence[i][type] = v1;
            sequence[j][type] = v2;
          }
        } else if (sequence[j][type] == null) {
          if (selectedPairs.contains((i, j))) {
            sequence[j][type] = sequence[i][type];
          } else {
            final opts = getOptions();
            final v2 = opts.firstWhere((e) => e != sequence[i][type]);
            sequence[j][type] = v2;
          }
        }
      }
    }

    setState(() {
      hasStarted = true;
      currentIndex = 0;
    });
    _showNext();
  }

  void _showNext() async {
    if (currentIndex >= sequence.length) {
      _showResults();
      return;
    }

    final stim = sequence[currentIndex];
    setState(() {
      _activeBoxIndex = stim[StimulusType.grid];
      _activeLetter = stim[StimulusType.sound];
      _activeNumber = stim[StimulusType.number];
    });

    if (_activeLetter != null) {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$_activeLetter.ogg'));
    }

    await Future.delayed(const Duration(milliseconds: 1300));
    setState(() {
      _activeBoxIndex = null;
      _activeLetter = null;
      _activeNumber = null;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    currentIndex++;
    _showNext();
  }

  void _showResults() {
    final buffer = StringBuffer();
    for (var entry in matchSets.entries) {
      buffer.writeln('${entry.key.name} Matches: ${entry.value}');
    }
    buffer.writeln('\nFull Sequence:');
    for (var i = 0; i < sequence.length; i++) {
      buffer.writeln('$i: ${sequence[i]}');
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Results', style: TextStyle(color: Colors.white)),
        content: SelectableText(buffer.toString(), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('N-Back Game'),
        centerTitle: true,
      ),
      body: Center(
        child: hasStarted
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    itemCount: 9,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (_, i) {
                      final active = i == _activeBoxIndex;
                      return Container(
                        decoration: BoxDecoration(
                          color: active ? Colors.tealAccent : Colors.grey[850],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: active && _activeNumber != null
                            ? Center(
                                child: Text(
                                  '$_activeNumber',
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                                ),
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Select N:', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        dropdownColor: Colors.black,
                        value: _selectedN,
                        items: List.generate(15, (i) => i + 1)
                            .map((e) => DropdownMenuItem(value: e, child: Text('$e-back', style: const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedN = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Mode:', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        dropdownColor: Colors.black,
                        value: _selectedMode,
                        items: modes.keys
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedMode = v!),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _startGame, child: const Text('Start Game'))
                ],
              ),
      ),
    );
  }
}