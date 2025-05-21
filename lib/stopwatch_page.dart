import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  // Color Scheme
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF4D8DEE);
  final Color darkColor = const Color(0xFF2D3748);
  final Color lightColor = const Color(0xFFF7FAFC);
  final Color successColor = const Color(0xFF48BB78);
  final Color warningColor = const Color(0xFFED8936);
  final Color dangerColor = const Color(0xFFF56565);

  // Stopwatch State
  bool _isRunning = false;
  late Stopwatch _stopwatch;
  final List<String> _laps = [];

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  void _toggleStopwatch() {
    setState(() {
      _isRunning = !_isRunning;
      _isRunning ? _stopwatch.start() : _stopwatch.stop();
    });
  }

  void _resetStopwatch() {
    setState(() {
      _isRunning = false;
      _stopwatch.reset();
      _laps.clear();
    });
  }

  void _recordLap() {
    setState(() {
      _laps.add(_formatTime(_stopwatch.elapsedMilliseconds));
    });
  }

  String _formatTime(int milliseconds) {
    final Duration duration = Duration(milliseconds: milliseconds);
    return '${duration.inMinutes.toString().padLeft(2, '0')}:'
           '${(duration.inSeconds % 60).toString().padLeft(2, '0')}.'
           '${(duration.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}';
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        shadowColor: color.withOpacity(0.3),
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkColor,
      appBar: AppBar(
        title: Text('STOPWATCH', style: GoogleFonts.poppins(letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Timer Display
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: darkColor.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 8),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Center(
                child: StreamBuilder(
                  stream: Stream.periodic(const Duration(milliseconds: 100)),
                  builder: (context, snapshot) {
                    return Text(
                      _formatTime(_stopwatch.elapsedMilliseconds),
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: lightColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Control Buttons
            Wrap(
              spacing: 15,
              runSpacing: 15,
              alignment: WrapAlignment.center,
              children: [
                _buildActionButton(
                  _isRunning ? 'STOP' : 'START',
                  _isRunning ? Icons.stop : Icons.play_arrow,
                  _isRunning ? dangerColor : successColor,
                  _toggleStopwatch,
                ),
                _buildActionButton(
                  'LAP',
                  Icons.flag,
                  secondaryColor,
                  _isRunning ? _recordLap : null,
                ),
                _buildActionButton(
                  'RESET',
                  Icons.refresh,
                  warningColor,
                  _resetStopwatch,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Laps List
            if (_laps.isNotEmpty) ...[
              Text(
                'LAP TIMES',
                style: GoogleFonts.poppins(
                  color: lightColor.withOpacity(0.8),
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.separated(
                  itemCount: _laps.length,
                  separatorBuilder: (context, index) => Divider(
                    color: darkColor.withOpacity(0.5),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: darkColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Text(
                          'Lap ${index + 1}',
                          style: GoogleFonts.poppins(
                            color: lightColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          _laps[index],
                          style: GoogleFonts.poppins(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}