import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class Alarm {
  final TimeOfDay time;
  final List<String> days;
  final String voice;
  bool isActive;
  int? notificationId;

  Alarm({
    required this.time,
    required this.days,
    required this.voice,
    this.isActive = true,
    this.notificationId,
  });

  String get formattedTime => "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
}

class AlarmSettingsPage extends StatefulWidget {
  const AlarmSettingsPage({super.key});

  @override
  State<AlarmSettingsPage> createState() => _AlarmSettingsPageState();
}

class _AlarmSettingsPageState extends State<AlarmSettingsPage> {
  // Color Scheme
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF4D8DEE);
  final Color darkColor = const Color(0xFF2D3748);
  final Color lightColor = const Color(0xFFF7FAFC);
  final Color dangerColor = const Color(0xFFF56565);

  // Alarm Settings
  static const maxAlarms = 5;
  final List<Alarm> _alarms = [];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _voices = ['David Goggins', 'Dwayne Johnson', 'Jocko Willink'];

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Notifications
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  TimeOfDay? _selectedTime;
  Set<String> _selectedDays = {};
  String? _selectedVoice;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    tz.initializeTimeZones();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await _playAlarmSound();
      },
    );
  }

  Future<void> _playAlarmSound() async {
    try {
      await _audioPlayer.setAsset('assets/audio/alarm_sound.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing sound: $e')),
        );
      }
    }
  }

  Future<void> _stopAlarmSound() async {
    await _audioPlayer.stop();
  }

  Future<void> _scheduleAlarm(Alarm alarm) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Channel for alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    alarm.notificationId = alarm.hashCode;

    await _notificationsPlugin.zonedSchedule(
      alarm.notificationId!,
      'Alarm',
      'Time to wake up!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: alarm.days.isEmpty 
          ? null 
          : DateTimeComponents.time,
    );
  }

  Future<void> _cancelAlarm(Alarm alarm) async {
    if (alarm.notificationId != null) {
      await _notificationsPlugin.cancel(alarm.notificationId!);
      await _stopAlarmSound(); // Added this to stop sound when cancelling
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryColor,
              surface: darkColor,
            ),
            dialogBackgroundColor: darkColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addAlarm() {
    if (_selectedTime == null || _selectedVoice == null || _selectedDays.isEmpty) {
      _showSnackBar('Please set time, days, and voice.');
      return;
    }

    if (_alarms.length >= maxAlarms) {
      _showSnackBar('Maximum of $maxAlarms alarms allowed.');
      return;
    }

    final newAlarm = Alarm(
      time: _selectedTime!,
      days: _selectedDays.toList(),
      voice: _selectedVoice!,
    );

    setState(() {
      _alarms.add(newAlarm);
      if (newAlarm.isActive) {
        _scheduleAlarm(newAlarm);
      }
      _resetSelections();
    });
  }

  void _resetSelections() {
    _selectedTime = null;
    _selectedDays.clear();
    _selectedVoice = null;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: darkColor.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _removeAlarm(int index) async {
    final alarm = _alarms[index];
    await _cancelAlarm(alarm);
    setState(() => _alarms.removeAt(index));
  }

  void _toggleAlarm(int index) async {
    final alarm = _alarms[index];
    setState(() => alarm.isActive = !alarm.isActive);
    
    if (alarm.isActive) {
      await _scheduleAlarm(alarm);
    } else {
      await _cancelAlarm(alarm);
    }
  }

  Widget _buildDayChip(String day) {
    return FilterChip(
      label: Text(day),
      selected: _selectedDays.contains(day),
      onSelected: (selected) => setState(() {
        selected ? _selectedDays.add(day) : _selectedDays.remove(day);
      }),
      selectedColor: primaryColor,
      checkmarkColor: lightColor,
      labelStyle: GoogleFonts.poppins(
        color: _selectedDays.contains(day) ? lightColor : lightColor.withOpacity(0.8),
      ),
      backgroundColor: darkColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkColor,
      appBar: AppBar(
        title: Text('ALARM SETTINGS', style: GoogleFonts.poppins(letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: lightColor),
            onPressed: () {
              // Add settings functionality here
              _stopAlarmSound(); // Added example usage of _stopAlarmSound
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Alarm Form
            Card(
              color: darkColor.withOpacity(0.7),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SET NEW ALARM',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: lightColor.withOpacity(0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Time Selection
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedTime != null 
                                ? 'Selected: ${_selectedTime!.format(context)}'
                                : 'No time selected',
                            style: GoogleFonts.poppins(
                              color: lightColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _pickTime,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: lightColor,
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            'SELECT TIME',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Days Selection
                    Text(
                      'SELECT DAYS:',
                      style: GoogleFonts.poppins(
                        color: lightColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _days.map(_buildDayChip).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Voice Selection
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'ALARM VOICE',
                        labelStyle: GoogleFonts.poppins(
                          color: lightColor.withOpacity(0.8),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: darkColor.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: darkColor,
                      value: _selectedVoice,
                      items: _voices.map((voice) => DropdownMenuItem(
                        value: voice,
                        child: Text(
                          voice,
                          style: GoogleFonts.poppins(color: lightColor),
                        ),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedVoice = value),
                      style: GoogleFonts.poppins(color: lightColor),
                      icon: Icon(Icons.arrow_drop_down, color: lightColor),
                    ),
                    const SizedBox(height: 16),
                    
                    // Add Alarm Button
                    ElevatedButton(
                      onPressed: _addAlarm,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: lightColor,
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        'ADD ALARM',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Alarms List
            Text(
              'YOUR ALARMS',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: lightColor.withOpacity(0.8),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: _alarms.isEmpty
                  ? Center(
                      child: Text(
                        'No alarms set yet',
                        style: GoogleFonts.poppins(color: lightColor.withOpacity(0.6)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _alarms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final alarm = _alarms[index];
                        return Dismissible(
                          key: Key('alarm-$index'),
                          background: Container(
                            decoration: BoxDecoration(
                              color: dangerColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: Icon(Icons.delete, color: dangerColor),
                          ),
                          onDismissed: (_) => _removeAlarm(index),
                          child: Card(
                            color: darkColor.withOpacity(0.7),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                              leading: Transform.scale(
                                scale: 1.2,
                                child: Switch(
                                  value: alarm.isActive,
                                  activeColor: primaryColor,
                                  onChanged: (_) => _toggleAlarm(index),
                                ),
                              ),
                              title: Text(
                                alarm.time.format(context),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: alarm.isActive ? lightColor : lightColor.withOpacity(0.5),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alarm.voice,
                                    style: GoogleFonts.poppins(
                                      color: alarm.isActive 
                                          ? lightColor.withOpacity(0.8) 
                                          : lightColor.withOpacity(0.4),
                                    ),
                                  ),
                                  Text(
                                    alarm.days.join(', '),
                                    style: GoogleFonts.poppins(
                                      color: alarm.isActive 
                                          ? secondaryColor 
                                          : secondaryColor.withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: dangerColor),
                                onPressed: () => _removeAlarm(index),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}