import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const SitBreakApp());
}

class SitBreakApp extends StatelessWidget {
  const SitBreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sit & Break',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const LanguageScreen(),
    );
  }
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select Your Language\nاختر اللغة',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(55)),
                onPressed: () => _setLanguage(context, 'ar'),
                child: const Text('العربية', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(55)),
                onPressed: () => _setLanguage(context, 'en'),
                child: const Text('English', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setLanguage(BuildContext context, String lang) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double workMinutes = 25;
  double breakMinutes = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timer Settings / الإعدادات')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text('Work Duration: ${workMinutes.toInt()} mins', style: const TextStyle(fontSize: 16)),
            Slider(
              value: workMinutes,
              min: 1,
              max: 60,
              divisions: 59,
              label: '${workMinutes.toInt()} mins',
              onChanged: (val) => setState(() => workMinutes = val),
            ),
            const Divider(),
            Text('Break Duration: ${breakMinutes.toInt()} mins', style: const TextStyle(fontSize: 16)),
            Slider(
              value: breakMinutes,
              min: 1,
              max: 30,
              divisions: 29,
              label: '${breakMinutes.toInt()} mins',
              onChanged: (val) => setState(() => breakMinutes = val),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: Colors.teal,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimerScreen(
                      workTime: workMinutes.toInt() * 60,
                      breakTime: breakMinutes.toInt() * 60,
                    ),
                  ),
                );
              },
              child: const Text(
                'Start App / بدء التطبيق',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimerScreen extends StatefulWidget {
  final int workTime;
  final int breakTime;

  const TimerScreen({
    super.key,
    required this.workTime,
    required this.breakTime,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late int remainingSeconds;
  bool isWorking = true;
  bool isPhoneMoving = false;    
  
  Timer? timer;
  StreamSubscription? accelerometerSubscription;
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.workTime;
    
    // مراقبة حركة الهاتف عبر المستشعرات (حتى لو كنت خارج التطبيق وتستخدم الهاتف)
    accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      double totalMovement = event.x.abs() + event.y.abs() + event.z.abs();
      bool moving = totalMovement > 11.5;
      
      if (moving != isPhoneMoving) {
        setState(() {
          isPhoneMoving = moving;
        });
      }
    });

    _startAutoTimer();
  }

  void _startAutoTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isPhoneMoving) {
        setState(() {
          if (remainingSeconds > 0) {
            remainingSeconds--;
          } else {
            // انتهى الوقت: إصدار صوت تنبيه والتبديل بين العمل والاستراحة
            _playAlarmSound();
            isWorking = !isWorking;
            remainingSeconds = isWorking ? widget.workTime : widget.breakTime;
          }
        });
      }
    });
  }

  void _playAlarmSound() async {
    try {
      await audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    accelerometerSubscription?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text(isWorking ? 'Work Time / وقت العمل' : 'Break Time / وقت الاستراحة'),
        backgroundColor: isWorking ? Colors.teal : Colors.orange,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isPhoneMoving ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isPhoneMoving ? Colors.green : Colors.orange, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      isPhoneMoving 
                          ? '🟢 المؤقت يعمل (الهاتف يتحرك بيدك)' 
                          : '🟡 المؤقت متوقف (الهاتف موضوع بلا حركة)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold, 
                        color: isPhoneMoving ? Colors.green.shade800 : Colors.orange.shade800
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isPhoneMoving ? '✓ يتم احتساب وقت عملك لأنك تستخدم الهاتف' : '✗ توقف العد لعدم وجود حركة للجهاز',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isPhoneMoving ? Colors.green.shade700 : Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'يمكنك الخروج من التطبيق، طالما أن الهاتف يتحرك بيدك سيستمر العد، وسيصدر صوت تنبيه تلقائي عند انتهاء الوقت!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
