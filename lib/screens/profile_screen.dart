import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/hive_init.dart';
import '../models/profile.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSwitchToLogMood;
  
  const ProfileScreen({super.key, this.onSwitchToLogMood});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedBirthdate;
  TimeOfDay? _selectedBirthTime;

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Birthdate',
    );
    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedBirthTime ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Select Birth Time (Optional)',
    );
    if (picked != null) {
      setState(() {
        _selectedBirthTime = picked;
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBirthdate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your birthdate')),
        );
        return;
      }

      // Combine birthdate and birth time if provided
      DateTime birthDateTime = _selectedBirthdate!;
      if (_selectedBirthTime != null) {
        birthDateTime = DateTime(
          _selectedBirthdate!.year,
          _selectedBirthdate!.month,
          _selectedBirthdate!.day,
          _selectedBirthTime!.hour,
          _selectedBirthTime!.minute,
        );
      }

      final profile = Profile(
        username: _usernameController.text.trim(),
        gender: _selectedGender!,
        birthdate: _selectedBirthdate!,
        birthTime: _selectedBirthTime != null ? birthDateTime : null,
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
      );

      // Save to Hive (using key 'profile' to store single profile)
      HiveInit.profileBox.put('profile', profile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );

      // Switch to Log Mood tab
      if (widget.onSwitchToLogMood != null) {
        widget.onSwitchToLogMood!();
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Lunar Mood Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Username field
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Gender dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              items: _genders.map((String gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your gender';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Birthdate picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Birthdate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedBirthdate != null
                      ? DateFormat('yyyy-MM-dd').format(_selectedBirthdate!)
                      : 'Select birthdate',
                  style: TextStyle(
                    color: _selectedBirthdate != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Birth time picker (optional)
            InkWell(
              onTap: () => _selectTime(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Birth Time (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  _selectedBirthTime != null
                      ? _selectedBirthTime!.format(context)
                      : 'Select birth time (optional)',
                  style: TextStyle(
                    color: _selectedBirthTime != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // City field
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your city';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Country field
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your country';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Save & Continue button
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save & Continue',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

