import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App theme mode state provider.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
