import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final String userId;
  final String userEmail;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.userId,
    required this.userEmail, required int selectedIndex, required Null Function(dynamic int) onTap,
    // required int selectedIndex, 
    // required Null Function(dynamic int) onTap,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  // bool streakToday = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // checkStreakToday();
  }

  // Future<void> checkStreakToday() async {
  //   final data = await supabase
  //       .from('streaks')
  //       .select()
  //       .eq('user_id', widget.userId)
  //       .maybeSingle();

  //   if (data != null && data['last_treatment_date'] != null) {
  //     final lastDate = DateTime.parse(data['last_treatment_date']);
  //     final now = DateTime.now();

  //     final isSameDay = lastDate.year == now.year &&
  //         lastDate.month == now.month &&
  //         lastDate.day == now.day;

  //     setState(() {
  //       streakToday = isSameDay;
  //     });
  //   }
  // }

  void _onTabTapped(int index) {
    if (index == widget.currentIndex) return;

    final args = {
      'userId': widget.userId,
      'userEmail': widget.userEmail,
    };

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home', arguments: args);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/moodtracker', arguments: args);
        break;
      //case 2:
        //Navigator.pushReplacementNamed(context, '/streak', arguments: args);
        //break;
      case 2:
        Navigator.pushReplacementNamed(context, '/treatment', arguments: args);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile', arguments: args);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: _onTabTapped,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.emoji_emotions),
          label: 'Mood',
        ),
        //const BottomNavigationBarItem(
          // icon: Stack(
          //   alignment: Alignment.center,
          //   children: [
          //     if (streakToday)
          //       Container(
          //         width: 30,
          //         height: 30,
          //         decoration: BoxDecoration(
          //           shape: BoxShape.circle,
          //           color: Colors.orange.withOpacity(0.3),
          //         ),
          //       ),
          //     Icon(Icons.whatshot, color: streakToday ? Colors.orange : null),
          //   ],
          // ),
          //icon: Icon(Icons.whatshot),
         // label: 'Streak',
        //),
        const BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Treatment',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
