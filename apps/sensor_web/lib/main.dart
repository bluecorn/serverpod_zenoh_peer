import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_web/ui/levels/levels_screen.dart';

void main() => runApp(
  ProviderScope(
    retry: (retryCount, error) => null,
    child: const MaterialApp(title: 'sensor_web', home: LevelsScreen()),
  ),
);
