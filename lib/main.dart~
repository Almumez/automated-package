import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/google_maps_integration/bloc/google_maps_integration_bloc.dart';
import 'features/google_maps_integration/screens/google_maps_integration_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Integration Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => GoogleMapsIntegrationBloc(),
        child: const GoogleMapsIntegrationScreen(),
      ),
    );
  }
}

