import 'package:flutter/material.dart';
import 'game_screen.dart'; // Add this on top
void main() {
  runApp(const QuadNBackApp());
}


class QuadNBackApp extends StatelessWidget {
  const QuadNBackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quad N-Back',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: const InputDecorationTheme(
            border: UnderlineInputBorder(),
          ),
        ),
      ),
      //home: const HomeScreen(), Temporarily test the grid
      home: const GameScreen(), 
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _nBackLevel = 1;
  String _nBackMode = 'Single';

  final List<String> _modes = ['Single', 'Dual', 'Triple', 'Quad'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quad N-Back'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Let’s make your brain bulletproof',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 30),

              // N-Back Level and Mode in a Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select N-Back Level:',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  DropdownButton<int>(
                    value: _nBackLevel,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white,
                    underline: Container(
                      height: 1,
                      color: Colors.white24,
                    ),
                    onChanged: (int? newValue) {
                      setState(() {
                        _nBackLevel = newValue!;
                      });
                    },
                    items: List.generate(
                      20,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Mode:',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  DropdownButton<String>(
                    value: _nBackMode,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white,
                    underline: Container(
                      height: 1,
                      color: Colors.white24,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _nBackMode = newValue!;
                      });
                    },
                    items: _modes
                        .map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode),
                            ))
                        .toList(),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  debugPrint(
                      'Start Game: N=$_nBackLevel, Mode=$_nBackMode');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Start Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
