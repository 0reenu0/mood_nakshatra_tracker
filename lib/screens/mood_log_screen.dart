import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../database/hive_init.dart';
import '../models/mood_entry.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key});

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

enum MoodType { angry, sad, happy, productive }

class _MoodLogScreenState extends State<MoodLogScreen> {
  String? _nakshatraName;
  DateTime? _nakshatraStart;
  DateTime? _nakshatraEnd;
  bool _isLoading = false;
  String? _error;

  MoodType? _selectedMood;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentNakshatra();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentNakshatra() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // NOTE: Replace this with your actual Prokerala API access token.
      const accessToken = 'YOUR_PROKERALA_ACCESS_TOKEN';

      final now = DateTime.now().toUtc();
      final datetimeParam = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(now);

      final uri = Uri.parse(
        'https://api.prokerala.com/v2/astrology/panchang'
        '?datetime=$datetimeParam'
        '&latitude=0'
        '&longitude=0'
        '&ayanamsa=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('API error: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      // The exact response shape may vary; this handles common structures:
      // - Either top-level "nakshatra" object
      // - Or nested under "data" -> "nakshatra"
      Map<String, dynamic>? nakshatraJson;

      if (data['nakshatra'] is Map<String, dynamic>) {
        nakshatraJson = data['nakshatra'] as Map<String, dynamic>;
      } else if (data['data'] != null &&
          data['data']['nakshatra'] is Map<String, dynamic>) {
        nakshatraJson = data['data']['nakshatra'] as Map<String, dynamic>;
      }

      if (nakshatraJson == null) {
        throw Exception('Nakshatra data not found in response');
      }

      final name = nakshatraJson['name'] as String?;

      // Some responses use "end_time", some "end"; handle both.
      final endStr = (nakshatraJson['end_time'] ??
              nakshatraJson['end']?['datetime']) as String?;
      final startStr =
          (nakshatraJson['start_time'] ?? nakshatraJson['start']?['datetime'])
              as String?;

      DateTime? start;
      DateTime? end;
      if (startStr != null) {
        start = DateTime.tryParse(startStr);
      }
      if (endStr != null) {
        end = DateTime.tryParse(endStr);
      }

      if (name == null || end == null) {
        throw Exception('Incomplete nakshatra data');
      }

      setState(() {
        _nakshatraName = name;
        _nakshatraStart = start;
        _nakshatraEnd = end;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Nakshatra data';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildTransitPeriodText() {
    if (_nakshatraStart == null && _nakshatraEnd == null) {
      return '';
    }

    final dateFormatter = DateFormat('MMM d, yyyy');

    final start = _nakshatraStart;
    final end = _nakshatraEnd;

    if (start != null && end != null) {
      if (dateFormatter.format(start) == dateFormatter.format(end)) {
        return dateFormatter.format(start);
      }
      return '${dateFormatter.format(start)} – ${dateFormatter.format(end)}';
    }

    if (end != null) {
      // If only end is known, assume transit started roughly one day earlier
      final approxStart = end.subtract(const Duration(days: 1));
      return '${dateFormatter.format(approxStart)} – ${dateFormatter.format(end)}';
    }

    return '';
  }

  void _saveMood() {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select how you feel today')),
      );
      return;
    }

    if (_nakshatraName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nakshatra data not available')),
      );
      return;
    }

    try {
      // Generate a unique ID (using timestamp as ID)
      final id = DateTime.now().millisecondsSinceEpoch;
      
      // Convert MoodType enum to string
      final moodString = _selectedMood!.name;

      final moodEntry = MoodEntry(
        id: id,
        date: DateTime.now(),
        nakshatra: _nakshatraName!,
        mood: moodString,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      // Save to Hive
      HiveInit.moodBox.put(id.toString(), moodEntry);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mood saved successfully')),
      );

      // Clear form
      setState(() {
        _selectedMood = null;
        _notesController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving mood: $e')),
      );
    }
  }

  Widget _buildMoodButton(MoodType mood, String emoji, String label) {
    final isSelected = _selectedMood == mood;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMood = mood;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15 * 255)
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transitText = _buildTransitPeriodText();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Log'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
              ] else if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _fetchCurrentNakshatra,
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Text(
                  _nakshatraName != null
                      ? 'Current Nakshatra: $_nakshatraName'
                      : 'Current Nakshatra: —',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (transitText.isNotEmpty)
                  Text(
                    transitText,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              const Text(
                'How are you feeling today?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildMoodButton(MoodType.angry, '😠', 'Angry'),
                  const SizedBox(width: 12),
                  _buildMoodButton(MoodType.sad, '😢', 'Sad'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMoodButton(MoodType.happy, '😊', 'Happy'),
                  const SizedBox(width: 12),
                  _buildMoodButton(MoodType.productive, '💪', 'Productive'),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Notes (optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _notesController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write anything you want to remember about today...',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMood,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Mood',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

