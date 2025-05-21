import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  // Color Palette
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF4D8DEE);
  final Color darkColor = const Color(0xFF2D3748);
  final Color lightColor = const Color(0xFFF7FAFC);
  final Color successColor = const Color(0xFF48BB78);
  final Color warningColor = const Color(0xFFED8936);
  final Color dangerColor = const Color(0xFFF56565);

  // Timer State
  Duration _duration = Duration.zero;
  Duration _remainingTime = Duration.zero;
  bool _isRunning = false;
  late Timer _timer;
  
  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingSound = false;

  // Controllers
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() => _isPlayingSound = false);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  // Timer Control Methods
  void _startTimer() {
    if (_remainingTime.inSeconds <= 0) return;

    setState(() {
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
          } else {
            _timer.cancel();
            _isRunning = false;
            _playAlarmSound();
          }
        });
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
      _timer.cancel();
      _stopAlarmSound();
    });
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _timer.cancel();
      _remainingTime = _duration;
      _stopAlarmSound();
    });
  }

  void _deleteTimer() {
    setState(() {
      _isRunning = false;
      _timer.cancel();
      _duration = Duration.zero;
      _remainingTime = Duration.zero;
      _hourController.clear();
      _minuteController.clear();
      _secondController.clear();
      _stopAlarmSound();
    });
  }

  // Audio Methods
  Future<void> _playAlarmSound() async {
    try {
      setState(() => _isPlayingSound = true);
      await _audioPlayer.setAsset('assets/audio/timer_sound.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing sound: $e')),
        );
      }
      setState(() => _isPlayingSound = false);
    }
  }

  Future<void> _stopAlarmSound() async {
    await _audioPlayer.stop();
    if (mounted) {
      setState(() => _isPlayingSound = false);
    }
  }

  // Helper Methods
  void _setTime() {
    final hours = int.tryParse(_hourController.text) ?? 0;
    final minutes = int.tryParse(_minuteController.text) ?? 0;
    final seconds = int.tryParse(_secondController.text) ?? 0;

    setState(() {
      _duration = Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
      );
      _remainingTime = _duration;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // UI Components
  Widget _buildTimerDisplay() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: darkColor.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor, width: 8),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Center(
        child: Text(
          _formatDuration(_remainingTime),
          style: GoogleFonts.poppins(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: lightColor,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback? onPressed, {bool isLarge = false}) {
    return SizedBox(
      width: isLarge ? 200 : 120,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          shadowColor: color.withOpacity(0.4),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildControlButtons() {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: [
        if (_isRunning && !_isPlayingSound)
          _buildActionButton('PAUSE', Icons.pause, warningColor, _pauseTimer),
        
        if (!_isRunning && _remainingTime.inSeconds > 0 && !_isPlayingSound)
          _buildActionButton('RESUME', Icons.play_arrow, successColor, _startTimer),
        
        if (!_isRunning && !_isPlayingSound && _remainingTime == _duration)
          _buildActionButton('START', Icons.play_arrow, successColor, 
            _duration.inSeconds > 0 ? _startTimer : null),
        
        if (_isPlayingSound)
          _buildActionButton('STOP ALARM', Icons.alarm_off, dangerColor, _stopAlarmSound,
            isLarge: true),
        
        if (!_isPlayingSound)
          _buildActionButton('RESET', Icons.refresh, secondaryColor, _resetTimer),
      ],
    );
  }

  Widget _buildTimeInput(String label, TextEditingController controller) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 24),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          filled: true,
          fillColor: darkColor.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (_) => _setTime(),
      ),
    );
  }

  Widget _buildTimeInputSection() {
    return Column(
      children: [
        Text(
          'SET TIMER',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeInput('HH', _hourController),
            Text(':', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24)),
            _buildTimeInput('MM', _minuteController),
            Text(':', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24)),
            _buildTimeInput('SS', _secondController),
          ],
        ),
      ],
    );
  }

  Widget _buildAlarmAlert() {
    return Column(
      children: [
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dangerColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dangerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.alarm, color: lightColor),
              const SizedBox(width: 10),
              Text(
                'TIME\'S UP!',
                style: GoogleFonts.poppins(
                  color: lightColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkColor,
      appBar: AppBar(
        title: Text('FOCUS TIMER', style: GoogleFonts.poppins(letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: lightColor),
            onPressed: () {}, // Add settings functionality
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildTimerDisplay(),
              const SizedBox(height: 40),
              _buildControlButtons(),
              if (!_isRunning && !_isPlayingSound) _buildTimeInputSection(),
              if (_isPlayingSound) _buildAlarmAlert(),
            ],
          ),
        ),
      ),
    );
  }
}