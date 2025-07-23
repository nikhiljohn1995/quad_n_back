import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

enum StimulusType { grid, sound, number, pattern }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _selectedN = 2;
  String _selectedMode = 'Quad';
  bool hasStarted = false;
  int countdown = 10;
  bool showCountdown = false;

  int? _activeBoxIndex;
  String? _activeLetter;
  int? _activeNumber;
  Color? _activePattern;

  int currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  List<Map<StimulusType, dynamic>> sequence = [];
  Map<StimulusType, Set<(int, int)>> matchSets = {};
  Map<StimulusType, Set<int>> userMatches = {
    StimulusType.grid: {},
    StimulusType.sound: {},
    StimulusType.number: {},
    StimulusType.pattern: {},
  };

  Map<StimulusType, Color?> buttonColors = {
    StimulusType.grid: null,
    StimulusType.sound: null,
    StimulusType.number: null,
    StimulusType.pattern: null,
  };

  final List<Color> patternColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.brown,
    Colors.black,
    Colors.white,
    Colors.pink,
  ];

  final Map<String, List<StimulusType>> modes = {
    'Single': [StimulusType.grid],
    'Dual': [StimulusType.grid, StimulusType.sound],
    'Triple': [StimulusType.grid, StimulusType.sound, StimulusType.number],
    'Quad': [StimulusType.grid, StimulusType.sound, StimulusType.number, StimulusType.pattern],
  };

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      showCountdown = true;
      countdown = 10;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => countdown--);
      if (countdown == 0) {
        timer.cancel();
        setState(() => showCountdown = false);
        _startGame();
      }
    });
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
            return List.from(patternColors)..shuffle(_random);
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
      userMatches = {
        StimulusType.grid: {},
        StimulusType.sound: {},
        StimulusType.number: {},
        StimulusType.pattern: {},
      };
    });

    _showNext();
  }

  void _registerUserInput(StimulusType type) {
    if (currentIndex < _selectedN) return;

    final currVal = sequence[currentIndex][type];
    final prevVal = sequence[currentIndex - _selectedN][type];
    final isCorrect = currVal == prevVal;

    setState(() {
      userMatches[type]?.add(currentIndex);
      buttonColors[type] = isCorrect ? Colors.green : Colors.red;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => buttonColors[type] = null);
    });
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
      _activePattern = stim[StimulusType.pattern];
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
      _activePattern = null;
    });

    await Future.delayed(const Duration(milliseconds: 200));
    currentIndex++;
    _showNext();
  }

  void _showResults() {
    Map<String, dynamic> gameResultSummary = {};
    List<Widget> resultWidgets = [];

    for (var type in modes[_selectedMode]!) {
      final userIndices = userMatches[type] ?? {};
      int correct = 0;
      int incorrect = 0;

      for (var index in userIndices) {
        if (index >= _selectedN &&
            sequence[index][type] == sequence[index - _selectedN][type]) {
          correct++;
        } else {
          incorrect++;
        }
      }

      final total = correct + incorrect;
      final accuracy = total == 0 ? 0 : ((correct / total) * 100).round();

      resultWidgets.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type.name.toUpperCase(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text('Correct Matches: $correct'),
          Text('Incorrect Matches: $incorrect'),
          Text('Accuracy: $accuracy%'),
          const SizedBox(height: 12),
        ],
      ));

      gameResultSummary[type.name] = {
        'correct': correct,
        'incorrect': incorrect,
        'accuracy': accuracy,
        'userInput': userIndices.toList(),
      };
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Your Performance', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: resultWidgets,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Color? _gridColor(int i) {
    return i == _activeBoxIndex ? _activePattern : Colors.grey[850];
  }

  Color _textColorForBackground(Color? bg) {
    if (bg == Colors.white) return Colors.black;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKey: (event) {
        if (event.runtimeType == RawKeyDownEvent) {
          final label = event.logicalKey.keyLabel.toUpperCase();
          if (label == 'A') _registerUserInput(StimulusType.grid);
          if (label == 'L') _registerUserInput(StimulusType.sound);
          if (label == 'Z') _registerUserInput(StimulusType.number);
          if (label == 'M') _registerUserInput(StimulusType.pattern);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1C),
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Quad N-Back Retro'),
          centerTitle: true,
        ),
        body: showCountdown
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Controls:', style: TextStyle(fontSize: 20, color: Colors.white)),
                    const SizedBox(height: 12),
                    const Text('A = Grid | L = Sound | Z = Number | M = Color',
                        style: TextStyle(fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 24),
                    Text('$countdown', style: const TextStyle(fontSize: 64, color: Colors.tealAccent)),
                  ],
                ),
              )
            : hasStarted
                ? Column(
                    children: [
                      Expanded(
                        child: Padding(
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
                                final bg = _gridColor(i);
                                return Container(
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: _activeBoxIndex == i && _activeNumber != null
                                      ? Center(
                                          child: Text(
                                            '$_activeNumber',
                                            style: TextStyle(
                                              fontSize: 42,
                                              fontWeight: FontWeight.bold,
                                              color: _textColorForBackground(bg),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _matchButton('A = Grid', StimulusType.grid),
                            _matchButton('L = Sound', StimulusType.sound),
                            _matchButton('Z = Number', StimulusType.number),
                            _matchButton('M = Color', StimulusType.pattern),
                          ],
                        ),
                      )
                    ],
                  )
                : _buildSetupScreen(),
      ),
    );
  }

  Widget _matchButton(String label, StimulusType type) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColors[type] ?? Colors.teal[900],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: Colors.white,
      ),
      onPressed: () => _registerUserInput(type),
      child: Text(label, style: const TextStyle(fontFamily: 'Courier')),
    );
  }

  Widget _buildSetupScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select N:', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          DropdownButton<int>(
            dropdownColor: Colors.black,
            value: _selectedN,
            items: List.generate(9, (i) => i + 1)
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text('$e-back', style: const TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedN = v!),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startCountdown,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('Start Game'),
          )
        ],
      ),
    );
  }
}
