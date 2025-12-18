import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/hive_init.dart';

/// Initial navigation index based on profile existence
int getInitialNavigationIndex() {
  final profile = HiveInit.profileBox.get('profile');
  // If no profile exists, start with Profile tab (index 2)
  // Otherwise start with Log Mood tab (index 0)
  return profile == null ? 2 : 0;
}

/// Provider that exposes a function to switch to Log Mood
final navigationActionsProvider = Provider<NavigationActions>((ref) {
  return NavigationActions(ref);
});

class NavigationActions {
  final Ref ref;
  
  NavigationActions(this.ref);
  
  void switchToLogMood() {
    // This will be handled by the widget's setState
  }
}

