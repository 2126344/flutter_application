import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Store or update user profile with username
  Future<void> storeUserProfile(String username) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No user logged in');
    }

    final userId = user.id;

    try {
      final existingProfile = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        // Update username if profile already exists
        await supabase.from('profiles').update({
          'username': username,
        }).eq('id', userId);
      } else {
        // Insert new profile if it doesn't exist
        await supabase.from('profiles').insert({
          'id': userId,
          'username': username,
        });
      }
    } catch (e) {
      throw Exception('Failed to store user profile: $e');
    }
  }

  /// Update daily treatment streak for the given userId
  Future<void> updateStreak(String userId) async {
    final today = DateTime.now();
    final data = await supabase
        .from('streaks')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data != null) {
      final lastDate = DateTime.parse(data['last_treatment_date']);
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        // Continue streak
        await supabase.from('streaks').update({
          'last_treatment_date': today.toIso8601String(),
          'streak_count': data['streak_count'] + 1,
        }).eq('user_id', userId);
      } else if (difference > 1) {
        // Streak reset
        await supabase.from('streaks').update({
          'last_treatment_date': today.toIso8601String(),
          'streak_count': 1,
        }).eq('user_id', userId);
      }
      // If difference == 0, no change (already updated today)
    } else {
      // Insert new streak record if none exists
      await supabase.from('streaks').insert({
        'user_id': userId,
        'last_treatment_date': today.toIso8601String(),
        'streak_count': 1,
      });
    }
  }
}
