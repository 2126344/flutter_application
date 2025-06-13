import 'package:flutter/material.dart';
import 'bottomnav.dart';

class MainScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final String userId;
  final String userEmail;
  final PreferredSizeWidget? appBar;

  const MainScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.userId,
    required this.userEmail,
    this.appBar, required String title,
    // removed 'required String title,' since it's not used here
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 236, 248, 255),
      appBar: appBar,
      body: SafeArea(child: child),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: currentIndex,
        userId: userId,
        userEmail: userEmail, selectedIndex: currentIndex, onTap: (int) {  },
        // removed selectedIndex and onTap because CustomBottomNav doesn't require them now
      ),
    );
  }
}
