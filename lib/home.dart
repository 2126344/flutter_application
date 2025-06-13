import 'dart:math';
import 'package:flutter/material.dart';
import 'bottomnav.dart';

class MainScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final String userId;
  final String userEmail;

  const MainScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.userId,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: child),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: currentIndex,
          userId: userId,
          userEmail: userEmail, selectedIndex: currentIndex, onTap: (int ) {  },
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String? userEmail;
  final String? userId;

  const HomePage({super.key, this.userEmail, this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late String email;
  late String userId;

  final List<String> quotes = [
    "Believe you can and you're halfway there.",
    "Every day is a second chance.",
    "Push yourself, because no one else is going to do it for you.",
    "Your limitation—it's only your imagination.",
    "Dream it. Wish it. Do it.",
  ];

  late String currentQuote;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    email = widget.userEmail ?? args?['email'] ?? 'User';
    userId = widget.userId ?? args?['userId'] ?? '';

    currentQuote = quotes[Random().nextInt(quotes.length)];
  }

  void _navigateToMood(String mood) {
    Navigator.pushNamed(
      context,
      '/moodtracker',
      arguments: {'mood': mood, 'email': email, 'userId': userId},
    );
  }

  void _navigateToTreatment() {
    Navigator.pushNamed(
      context,
      '/treatment',
      arguments: {'email': email, 'userId': userId},
    );
  }

  Widget _buildMoodButton(String moodLabel, String emoji) {
    return GestureDetector(
      onTap: () => _navigateToMood(moodLabel),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: _selectedIndex,
      userId: userId,
      userEmail: email,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage('assets/images/profile.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hi $email!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Recommended for You',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _navigateToTreatment,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/run.jpg',
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Center(
                  child: Text(
                    'How do you feel?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMoodButton('Stressed', '😟'),
                      _buildMoodButton('Anxious', '😰'),
                      _buildMoodButton('Neutral', '😐'),
                      _buildMoodButton('Happy', '😊'),
                      _buildMoodButton('Depressed', '😔'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(2, 4)),
                    ],
                  ),
                  child: Text(
                    currentQuote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
