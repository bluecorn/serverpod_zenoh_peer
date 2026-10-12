import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_web/ui/core/theme.dart';
import 'package:sensor_web/ui/page/page_screen.dart';

void main() => runApp(
  ProviderScope(
    retry: (retryCount, error) => null,
    child: MaterialApp(
      title: 'Sensor page',
      theme: themeOf(Brightness.light),
      darkTheme: themeOf(Brightness.dark),
      home: const PageScreen(),
    ),
  ),
);
