import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart';
import 'change_password_page.dart';
import 'login.dart';

class InitialCheckPage extends StatefulWidget {
  const InitialCheckPage({super.key});

  @override
  State<InitialCheckPage> createState() => _InitialCheckPageState();
}

class _InitialCheckPageState extends State<InitialCheckPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _handleInitialCheck();
  }

  Future<void> _handleInitialCheck() async {
    try {
      final session = supabase.auth.currentSession;

      if (session != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
        );
        return;
      }

      final uri = await getInitialUri();
      if (uri != null &&
          uri.queryParameters.containsKey('access_token') &&
          uri.queryParameters.containsKey('refresh_token')) {
        final refreshToken = uri.queryParameters['refresh_token']!;

        // Use setSession for Supabase Flutter SDK
        final response = await supabase.auth.setSession(refreshToken);

        final newSession = response.session;

        if (newSession != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
          );
        } else {
          if (mounted) setState(() => isLoading = false);
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error during auth check: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No valid session or link found."),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text("Go to Login"),
                  ),
                ],
              ),
      ),
    );
  }
}