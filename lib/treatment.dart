import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mainscaffold.dart';

class Treatment {
  final String type;
  int progress;

  Treatment({required this.type, required this.progress});

  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
      type: json['type'] ?? 'Unknown',
      progress: json['progress'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'progress': progress,
      };
}

class TreatmentPage extends StatefulWidget {
  final String userId;
  final String userEmail;

  const TreatmentPage({
    super.key,
    required this.userId,
    required this.userEmail, required recommendedTreatments, required mood, required List treatments, required currentStreak,
  });

  @override
  State<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  final client = Supabase.instance.client;
  List<Treatment> treatments = [];
  bool isLoading = false;

  final emojiMap = {
    'Running': '🏃',
    'Meditation': '🧘',
    'Reading': '📚',
    'Yoga': '🧎',
    'Workout': '🏋',
    'Music': '🎵',
  };

  final genderOptions = ['Male', 'Female'];
  final personalityOptions = ['Introvert', 'Extrovert', 'Feeler', 'Thinker', 'Adventurer'];
  final moodOptions = ['Anxious', 'Depressed', 'Neutral', 'Stressed', 'Happy'];

  String selectedGender = 'Male';
  String selectedPersonality = 'Introvert';
  String selectedMood = 'Happy';

  @override
  void initState() {
    super.initState();
    fetchTreatments();
    fetchLatestTreatmentHistory();
  }

  Future<void> fetchTreatments() async {
    final url = Uri.parse("https://serenemind.onrender.com/treatments/${widget.userId}");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          treatments = data.map((e) => Treatment.fromJson(e)).toList();
        });
      } else {
        _showErrorSnackbar("Error fetching treatments: ${response.statusCode}");
      }
    } catch (error) {
      _showErrorSnackbar("Network error: $error");
    }
  }

  Future<void> fetchAITreatments() async {
    setState(() {
      isLoading = true;
      treatments.clear();
    });

    final url = Uri.parse('https://serenemind.onrender.com/predict');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gender': selectedGender,
          'personality': selectedPersonality,
          'mood': selectedMood,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final recommended = List<String>.from(responseData['recommended_activities'] ?? []);

        if (!mounted) return;
        setState(() {
          treatments = recommended.map((type) => Treatment(type: type, progress: 0)).toList();
        });

        await saveTreatmentHistory(recommended);
      } else {
        _showErrorSnackbar("Error from server: ${response.body}");
      }
    } catch (error) {
      _showErrorSnackbar("Network error: $error");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> saveTreatmentHistory(List<String> recommended) async {
    try {
      await client.from('treatment_history').insert({
        'user_email': widget.userEmail,
        'gender': selectedGender,
        'personality': selectedPersonality,
        'mood': selectedMood,
        'treatments': jsonEncode(recommended.map((e) => {'type': e, 'progress': 0}).toList()),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      _showErrorSnackbar("Error saving history: $error");
    }
  }

  Future<void> fetchLatestTreatmentHistory() async {
    try {
      final response = await client
          .from('treatment_history')
          .select()
          .eq('user_email', widget.userEmail)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['treatments'] != null) {
        final treatmentsJson = jsonDecode(response['treatments']) as List<dynamic>;
        setState(() {
          treatments = treatmentsJson
              .map((e) => Treatment.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      _showErrorSnackbar("Error loading treatments: $e");
    }
  }

  void updateProgress(int index) async {
    final treatment = treatments[index];
    final newProgress = (treatment.progress + 20).clamp(0, 100);
    setState(() {
      treatments[index].progress = newProgress;
    });

    final treatmentJsonList = treatments.map((t) => t.toJson()).toList();

    try {
      await client.from('treatment_history').insert({
        'user_email': widget.userEmail,
        'gender': selectedGender,
        'personality': selectedPersonality,
        'mood': selectedMood,
        'treatments': jsonEncode(treatmentJsonList),
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (newProgress >= 100 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Treatment "${treatment.type}" completed! 🎉')),
        );
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => const StreakPopupDialog(),
          );
        }
      }
    } catch (e) {
      _showErrorSnackbar("Update error: $e");
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String selectedValue, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal),
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Treatment Page',
      currentIndex: 0,
      userId: widget.userId,
      userEmail: widget.userEmail,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildDropdown('Gender', genderOptions, selectedGender, (val) {
              if (val != null) setState(() => selectedGender = val);
            }),
            const SizedBox(height: 8),
            _buildDropdown('Personality', personalityOptions, selectedPersonality, (val) {
              if (val != null) setState(() => selectedPersonality = val);
            }),
            const SizedBox(height: 8),
            _buildDropdown('Mood', moodOptions, selectedMood, (val) {
              if (val != null) setState(() => selectedMood = val);
            }),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isLoading ? null : fetchAITreatments,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Get Treatments'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: treatments.isEmpty
                  ? const Center(child: Text('No treatments available.'))
                  : ListView.builder(
                      itemCount: treatments.length,
                      itemBuilder: (context, index) {
                        final treatment = treatments[index];
                        final emoji = emojiMap[treatment.type] ?? '💊';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: ListTile(
                            leading: Text(emoji, style: const TextStyle(fontSize: 32)),
                            title: Text(treatment.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: LinearProgressIndicator(
                              value: treatment.progress / 100,
                              color: Colors.teal,
                              backgroundColor: Colors.teal.shade100,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add, color: Colors.teal),
                              onPressed: () => updateProgress(index),
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
}

class StreakPopupDialog extends StatefulWidget {
  const StreakPopupDialog({super.key});

  @override
  State<StreakPopupDialog> createState() => _StreakPopupDialogState();
}

class _StreakPopupDialogState extends State<StreakPopupDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _opacityAnim = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _opacityAnim,
            child: const Text('🔥', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 12),
          const Text(
            'You are on a streak, day 1!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
