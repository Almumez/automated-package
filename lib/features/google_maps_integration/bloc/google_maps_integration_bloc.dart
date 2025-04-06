import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'google_maps_integration_event.dart';
import 'google_maps_integration_state.dart';

class GoogleMapsIntegrationBloc
    extends Bloc<GoogleMapsIntegrationEvent, GoogleMapsIntegrationState> {
  GoogleMapsIntegrationBloc() : super(const GoogleMapsIntegrationState()) {
    on<SelectProjectDirectory>(_onSelectProjectDirectory);
    on<AddGoogleMapsPackage>(_onAddGoogleMapsPackage);
    on<SetApiKey>(_onSetApiKey);
    on<ConfigurePlatforms>(_onConfigurePlatforms);
    on<AddMapExample>(_onAddMapExample);
  }

  Future<void> _onSelectProjectDirectory(
    SelectProjectDirectory event,
    Emitter<GoogleMapsIntegrationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final directory = Directory(event.directoryPath);
      if (!await directory.exists()) {
        throw Exception('Directory does not exist');
      }

      final pubspecFile = File(path.join(event.directoryPath, 'pubspec.yaml'));
      if (!await pubspecFile.exists()) {
        throw Exception('Not a valid Flutter project (no pubspec.yaml found)');
      }

      emit(state.copyWith(
        projectDirectory: event.directoryPath,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onAddGoogleMapsPackage(
    AddGoogleMapsPackage event,
    Emitter<GoogleMapsIntegrationState> emit,
  ) async {
    if (state.projectDirectory == null) {
      emit(state.copyWith(error: 'Please select a project directory first'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final pubspecFile = File(path.join(state.projectDirectory!, 'pubspec.yaml'));
      final pubspecContent = await pubspecFile.readAsString();
      final pubspec = loadYaml(pubspecContent);

      if (pubspec['dependencies'] == null) {
        throw Exception('Invalid pubspec.yaml format');
      }

      final dependencies = pubspec['dependencies'] as YamlMap;
      if (!dependencies.containsKey('google_maps_flutter')) {
        dependencies['google_maps_flutter'] = '^2.5.3';
        await pubspecFile.writeAsString(pubspec.toString());
      }

      emit(state.copyWith(
        isPackageAdded: true,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onSetApiKey(
    SetApiKey event,
    Emitter<GoogleMapsIntegrationState> emit,
  ) async {
    emit(state.copyWith(
      apiKey: event.apiKey,
      isLoading: false,
    ));
  }

  Future<void> _onConfigurePlatforms(
    ConfigurePlatforms event,
    Emitter<GoogleMapsIntegrationState> emit,
  ) async {
    if (state.projectDirectory == null || state.apiKey == null) {
      emit(state.copyWith(error: 'Please select a project directory and set API key first'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      // Configure Android
      final androidManifestFile = File(path.join(
        state.projectDirectory!,
        'android',
        'app',
        'src',
        'main',
        'AndroidManifest.xml',
      ));

      if (await androidManifestFile.exists()) {
        var manifestContent = await androidManifestFile.readAsString();
        if (!manifestContent.contains('android.permission.INTERNET')) {
          manifestContent = manifestContent.replaceFirst(
            '<manifest',
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.INTERNET"/>',
          );
          await androidManifestFile.writeAsString(manifestContent);
        }

        if (!manifestContent.contains('android:value="YOUR-API-KEY"')) {
          manifestContent = manifestContent.replaceFirst(
            '</application>',
            '        <meta-data\n            android:name="com.google.android.geo.API_KEY"\n            android:value="${state.apiKey}"/>\n    </application>',
          );
          await androidManifestFile.writeAsString(manifestContent);
        }
      }

      // Configure iOS
      final iosAppDelegateFile = File(path.join(
        state.projectDirectory!,
        'ios',
        'Runner',
        'AppDelegate.swift',
      ));

      if (await iosAppDelegateFile.exists()) {
        var appDelegateContent = await iosAppDelegateFile.readAsString();
        if (!appDelegateContent.contains('GMSServices.provideAPIKey')) {
          appDelegateContent = appDelegateContent.replaceFirst(
            'import UIKit',
            'import UIKit\nimport GoogleMaps',
          );
          appDelegateContent = appDelegateContent.replaceFirst(
            'func application',
            '    GMSServices.provideAPIKey("${state.apiKey}")\n\n    func application',
          );
          await iosAppDelegateFile.writeAsString(appDelegateContent);
        }
      }

      emit(state.copyWith(
        isPlatformConfigured: true,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onAddMapExample(
    AddMapExample event,
    Emitter<GoogleMapsIntegrationState> emit,
  ) async {
    if (state.projectDirectory == null) {
      emit(state.copyWith(error: 'Please select a project directory first'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final mainFile = File(path.join(state.projectDirectory!, 'lib', 'main.dart'));
      if (!await mainFile.exists()) {
        throw Exception('main.dart not found');
      }

      final exampleContent = '''
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};

  final LatLng _center = const LatLng(0, 0);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Example'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
        markers: _markers,
      ),
    );
  }
}
''';

      await mainFile.writeAsString(exampleContent);

      emit(state.copyWith(
        isExampleAdded: true,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }
} 