import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const TravelSafeApp());
}

class TravelSafeApp extends StatelessWidget {
  const TravelSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelSafe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Ready to connect';
  bool _isLoading = false;
  
  // Backend API URL - Change this to your computer's IP if testing on a real device
  // For emulator/Android: use http://10.0.2.2:8000
  // For iOS simulator: use http://localhost:8000
  // For real device: use http://YOUR_COMPUTER_IP:8000
  static const String baseUrl = 'http://localhost:8000';

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Connecting...';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/test'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _status = '✅ Connected!\n${data['message']}\n${data['data']}';
        });
      } else {
        setState(() {
          _status = '❌ Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Connection failed!\n\nMake sure:\n1. Backend is running\n2. URL is correct\n\nError: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TravelSafe - AI Safety Assistant'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.safety_check,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 30),
              const Text(
                'Welcome to TravelSafe!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testConnection,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi),
                label: Text(_isLoading ? 'Connecting...' : 'Test Backend Connection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Backend URL: $baseUrl',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
