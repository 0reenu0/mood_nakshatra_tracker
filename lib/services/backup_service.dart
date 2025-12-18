import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/hive_init.dart';
import '../models/mood_entry.dart';

// Conditional import for web
import 'backup_service_stub.dart'
    if (dart.library.html) 'backup_service_web.dart' as web;

class BackupService {
  /// Exports all mood entries to JSON and returns as Uint8List
  static Future<Uint8List> exportMoodEntries() async {
    final entries = HiveInit.moodBox.values.toList();
    
    // Convert to JSON array
    final jsonList = entries.map((entry) => entry.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    
    // Convert to Uint8List
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  /// Downloads the backup file on web
  static Future<void> downloadBackupFile(Uint8List data) async {
    if (kIsWeb) {
      final dateStr = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'mood_nakshatra_backup_$dateStr.json';
      await web.downloadFileWeb(data, fileName);
    } else {
      throw UnsupportedError('Download is only supported on web');
    }
  }

  /// Imports mood entries from JSON data
  static Future<int> importMoodEntries(Uint8List data) async {
    try {
      // Decode JSON
      final jsonString = utf8.decode(data);
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      
      // Clear current mood box
      await HiveInit.moodBox.clear();
      
      // Import entries
      int importedCount = 0;
      for (final json in jsonList) {
        try {
          final entry = MoodEntry.fromJson(json as Map<String, dynamic>);
          // Use id as key to maintain consistency
          await HiveInit.moodBox.put(entry.id.toString(), entry);
          importedCount++;
        } catch (e) {
          // Skip invalid entries
          debugPrint('Error importing entry: $e');
        }
      }
      
      return importedCount;
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }
}

