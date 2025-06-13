import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'mainscaffold.dart';

final logger = Logger();

class MoodTrackerPage extends StatefulWidget {
  final String userId;
  final String userEmail;

  const MoodTrackerPage({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage> {
  final Map<String, String> emojiMap = {
    "Stressed": "😟",
    "Anxious": "😰",
    "Neutral": "😐",
    "Happy": "😊",
    "Depressed": "😔",
  };

  String? selectedMood;
  final List<FlSpot> moodData = [];

  @override
  void initState() {
    super.initState();
    fetchMoodData();
  }

  Future<void> _selectMood(String moodLabel) async {
    setState(() {
      selectedMood = moodLabel;
      final double hour = TimeOfDay.now().hour.toDouble();
      final index = emojiMap.keys.toList().indexOf(moodLabel);
      moodData.add(FlSpot(hour, index.toDouble()));
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      logger.w('User not signed in');
      return;
    }

    try {
      await Supabase.instance.client.from('MoodTracker').insert({
        'user_id': user.id,
        'mood_label': moodLabel,
        'mood_index': emojiMap.keys.toList().indexOf(moodLabel),
      });
      logger.i('Mood saved to Supabase');
    } catch (error) {
      logger.e('Error inserting mood: $error');
    }
  }

  Future<void> fetchMoodData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      logger.w('User not signed in');
      return;
    }

    try {
      final List<dynamic> data = await Supabase.instance.client
          .from('MoodTracker')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      setState(() {
        moodData.clear();
        for (final mood in data) {
          final timestamp = DateTime.parse(mood['created_at']);
          final hour = timestamp.hour.toDouble();
          final index = mood['mood_index'] as int;
          moodData.add(FlSpot(hour, index.toDouble()));
        }
      });
    } catch (e) {
      logger.e("Error fetching mood data: $e");
    }
  }

  Widget _buildMoodSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: emojiMap.entries.map((entry) {
        final isSelected = selectedMood == entry.key;
        return ChoiceChip(
          label: Text('${entry.value} ${entry.key}'),
          selected: isSelected,
          labelStyle: TextStyle(
            fontSize: 16,
            color: isSelected ? Colors.white : Colors.black87,
          ),
          selectedColor: Colors.orangeAccent,
          onSelected: (_) => _selectMood(entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildMoodChart() {
    if (moodData.isEmpty) {
      return const Center(child: Text("No mood data yet."));
    }
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 24,
        minY: 0,
        maxY: (emojiMap.length - 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: moodData,
            isCurved: true,
            dotData: FlDotData(show: true),
            barWidth: 3,
            color: Colors.deepPurple,
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                int i = value.toInt();
                if (i < 0 || i >= emojiMap.length) return const SizedBox();
                return Text(emojiMap.values.toList()[i], style: const TextStyle(fontSize: 16));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 6,
              getTitlesWidget: (value, _) => Text('${value.toInt()}:00'),
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1, // Mood page index
      userId: widget.userId,
      userEmail: widget.userEmail,
      title: '',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5D4E3), Color(0xFFD2F3F1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mood Tracker",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF015A73),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "How are you feeling today?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D704A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Select a mood that reflects how you're feeling.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildMoodSelector(),
            const SizedBox(height: 16),
            if (selectedMood != null)
              Align(
                alignment: Alignment.center,
                child: Text(
                  selectedMood!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 30),
            const Text(
              "Mood Trends",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF015A73),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildMoodChart()),
          ],
        ),
      ),
    );
  }
}
