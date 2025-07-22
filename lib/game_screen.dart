
// FULL GAME SCREEN CODE WITH FIXED STRING ERRORS

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
  String _selectedMode = 'Dual';
  bool hasStarted = false;
  int? _activeBoxIndex;
  String? _activeLetter;
  int? _activeNumber;
  int currentIndex = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  List<Map<StimulusType, dynamic>> sequence = [];
  Map<StimulusType, Set<(int, int)>> matchSets = {};
  Map<StimulusType, Set<int>> userMatches = {
    StimulusType.grid: {},
    StimulusType.sound: {},
    StimulusType.number: {},
  };
  Map<StimulusType, Color?> buttonColors = {
    StimulusType.grid: null,
    StimulusType.sound: null,
    StimulusType.number: null,
  };

  final Map<String, List<StimulusType>> modes = {
    'Single': [StimulusType.grid],
    'Dual': [StimulusType.grid, StimulusType.sound],
    'Triple': [StimulusType.grid, StimulusType.sound, StimulusType.number],
    'Quad': [StimulusType.grid, StimulusType.sound, StimulusType.number]
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
      userMatches = {
        StimulusType.grid: {},
        StimulusType.sound: {},
        StimulusType.number: {},
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
    setState(() {
      buttonColors[type] = null;
    });
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
  // Backup: old debug-style result display for dev verification
  /*
  for (var entry in matchSets.entries) {
    buffer.writeln('${entry.key.name} Matches: ${entry.value}');
  }

  buffer.writeln('\nUser Inputs:');
  for (var entry in userMatches.entries) {
    buffer.writeln('${entry.key.name}: ${entry.value}');
  }

  buffer.writeln('\nFull Sequence:');
  for (var i = 0; i < sequence.length; i++) {
    buffer.writeln('$i: ${sequence[i]}'); // <-- Fixed here
  }

    showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Results', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: SelectableText(
          buffer.toString(),
          style: const TextStyle(color: Colors.white70),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        )
      ],
    ),
  );
  */
// new user friendly result

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

  gameResultSummary['n'] = _selectedN;
  gameResultSummary['mode'] = _selectedMode;
  gameResultSummary['timestamp'] = DateTime.now().toIso8601String();

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
  print('\n=== DEBUG: FULL SEQUENCE ===');
  for (int i = 0; i < sequence.length; i++) {
    print('$i: ${sequence[i]}');
  }

  print('\n=== DEBUG: MATCHING PAIRS ===');
  for (var type in modes[_selectedMode]!) {
    final pairs = matchSets[type] ?? {};
    print('${type.name.toUpperCase()}: $pairs');
  }

  print('Game Result Summary (to save): $gameResultSummary');
}


  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKey: (event) {
        final label = event.logicalKey.keyLabel;
        if (label == 'Arrow Left') {
          _registerUserInput(StimulusType.grid);
        } else if (label == 'Arrow Down') {
          _registerUserInput(StimulusType.sound);
        } else if (label == 'Arrow Right') {
          _registerUserInput(StimulusType.number);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('N-Back Game'),
          centerTitle: true,
        ),
        body: hasStarted
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
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _matchButton('← Grid', StimulusType.grid),
                        _matchButton('↓ Sound', StimulusType.sound),
                        _matchButton('→ Number', StimulusType.number),
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
        backgroundColor: buttonColors[type] ?? Colors.grey[800],
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      onPressed: () => _registerUserInput(type),
      child: Text(label),
    );
  }

    Widget _buildSetupScreen() {
    return Center(
      child: Column(
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
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text('$e-back',
                              style: const TextStyle(color: Colors.white)),
                        ))
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
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child:
                              Text(e, style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMode = v!),
              )
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: _startGame, child: const Text('Start Game')),
        ],
      ),
    );
  }
}
