import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'google_maps_integration_event.dart';
import 'google_maps_integration_state.dart';
import 'package:equatable/equatable.dart';

class GoogleMapsIntegrationBloc
    extends Bloc<GoogleMapsIntegrationEvent, GoogleMapsIntegrationState> {
  GoogleMapsIntegrationBloc() : super(const GoogleMapsIntegrationState()) {
    on<SelectProjectDirectory>(_onSelectProjectDirectory);
    on<AddGoogleMapsPackage>(_onAddGoogleMapsPackage);
    on<SetApiKey>(_onSetApiKey);
    on<ConfigurePlatforms>(_onConfigurePlatforms);
    on<AddMapExample>(_onAddMapExample);
    on<RequestPermissions>(_onRequestPermissions);
  }

  // التحقق من صلاحيات التخزين الكاملة في أندرويد 11+
  Future<bool> _requestManageExternalStoragePermission() async {
    try {
      // Check if permission is already granted
      final status = await Permission.manageExternalStorage.status;
      if (status == PermissionStatus.granted) {
        return true;
      }

      // Request permission
      final result = await Permission.manageExternalStorage.request();
      return result == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting MANAGE_EXTERNAL_STORAGE: $e');
      return false;
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (kIsWeb) {
      return true; // Web doesn't need file permissions
    }

    // For Android 11+ (API level 30+), request for MANAGE_EXTERNAL_STORAGE
    if (Platform.isAndroid) {
      // Request MANAGE_EXTERNAL_STORAGE permission for Android 11+
      bool hasManageStoragePerm = await _requestManageExternalStoragePermission();
      if (!hasManageStoragePerm) {
        // Try again if failed
        await Future.delayed(const Duration(seconds: 1));
        hasManageStoragePerm = await _requestManageExternalStoragePermission();
      }

      // Request regular storage permission
      bool hasStoragePerm = false;
      final storageStatus = await Permission.storage.status;
      
      if (storageStatus != PermissionStatus.granted) {
        final status = await Permission.storage.request();
        hasStoragePerm = status == PermissionStatus.granted;
      } else {
        hasStoragePerm = true;
      }
      
      return hasStoragePerm || hasManageStoragePerm; // Either permission is sufficient
    }
    
    return true;
  }

  Future<void> _onRequestPermissions(
    RequestPermissions event,
    Emitter<GoogleMapsIntegrationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final hasPermissions = await _checkAndRequestPermissions();
      if (!hasPermissions) {
        emit(state.copyWith(
          error: 'Required permissions were not granted. Please grant storage permissions to access project files',
          isLoading: false,
        ));
        return;
      }
      
      emit(state.copyWith(
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Error requesting permissions: ${e.toString()}',
        isLoading: false,
      ));
    }
  }

  Future<void> _onSelectProjectDirectory(
    SelectProjectDirectory event,
    Emitter<GoogleMapsIntegrationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      // Request permissions first
      if (!kIsWeb && Platform.isAndroid) {
        final hasPermissions = await _checkAndRequestPermissions();
        if (!hasPermissions) {
          emit(state.copyWith(
            error: 'Storage permissions are required to access the project files',
            isLoading: false,
          ));
          return;
        }
      }
      
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
      // Skip permission check for this operation
      // Instead, just try to modify the file directly
      
      final pubspecFile = File(path.join(state.projectDirectory!, 'pubspec.yaml'));
      if (!await pubspecFile.exists()) {
        throw Exception('pubspec.yaml file not found.');
      }
      
      // Try directly adding the package without checking permissions
      try {
        String pubspecContent = await pubspecFile.readAsString();
        
        // Check if package already exists
        if (pubspecContent.contains('google_maps_flutter:')) {
          // Package already exists, consider it as success
          emit(state.copyWith(
            isPackageAdded: true,
            isLoading: false,
          ));
          return;
        }
        
        // Simpler append to end of dependencies section
        if (pubspecContent.contains('dependencies:')) {
          final dependenciesLineIndex = pubspecContent.indexOf('dependencies:');
          int insertPosition = dependenciesLineIndex;
          
          // Find where to insert the package (right after dependencies: or at the end of the list)
          bool foundEnd = false;
          final lines = pubspecContent.split('\n');
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].contains('dependencies:')) {
              // First look for the next section after dependencies
              for (int j = i + 1; j < lines.length; j++) {
                if (lines[j].trim().isEmpty) continue;
                if (!lines[j].startsWith('  ')) {
                  // Found next section
                  insertPosition = pubspecContent.indexOf(lines[j]);
                  foundEnd = true;
                  break;
                }
              }
              if (foundEnd) break;
              
              // If we didn't find the end, insert at the end of the file
              insertPosition = pubspecContent.length;
              break;
            }
          }
          
          // Insert the package
          final beforeInsert = pubspecContent.substring(0, insertPosition);
          final afterInsert = insertPosition < pubspecContent.length 
              ? pubspecContent.substring(insertPosition)
              : '';
          
          final newContent = beforeInsert + 
                            '\n  google_maps_flutter: ^2.5.3\n' + 
                            afterInsert;
                            
          // Write the new content
          await pubspecFile.writeAsString(newContent);
          
          // Mark success
          emit(state.copyWith(
            isPackageAdded: true,
            isLoading: false,
          ));
          return;
        } else {
          throw Exception('Cannot find dependencies section in pubspec.yaml');
        }
      } catch (fileError) {
        print('Error manipulating pubspec.yaml: $fileError');
        
        // Simpler approach - just append at the end of file
        try {
          final content = await pubspecFile.readAsString();
          final newContent = content + '\n\n# Added by Google Maps Integration Tool\ndependencies:\n  google_maps_flutter: ^2.5.3\n';
          await pubspecFile.writeAsString(newContent);
          
          emit(state.copyWith(
            isPackageAdded: true,
            isLoading: false,
          ));
          return;
        } catch (e) {
          throw Exception('Failed to modify pubspec.yaml: $e');
        }
      }
    } catch (e) {
      print('Error adding Google Maps package: $e');
      emit(state.copyWith(
        error: 'Error adding package: ${e.toString()}',
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
          // The replaceFirst method here might not work well if manifest already has attributes
          // Let's check first if the manifest has xmlns:android declaration
          if (!manifestContent.contains('xmlns:android=')) {
            manifestContent = manifestContent.replaceFirst(
              '<manifest',
              '<manifest xmlns:android="http://schemas.android.com/apk/res/android"',
            );
          }
          
          // Now add the internet permission if it doesn't exist
          if (!manifestContent.contains('<uses-permission android:name="android.permission.INTERNET"')) {
            final insertPoint = manifestContent.indexOf('<application');
            if (insertPoint > 0) {
              manifestContent = manifestContent.substring(0, insertPoint) +
                  '    <uses-permission android:name="android.permission.INTERNET" />\n' +
                  manifestContent.substring(insertPoint);
            }
          }
          
          await androidManifestFile.writeAsString(manifestContent);
        }

        // Check if meta-data already exists
        if (!manifestContent.contains('com.google.android.geo.API_KEY')) {
          final appEnd = manifestContent.lastIndexOf('</application>');
          if (appEnd > 0) {
            manifestContent = manifestContent.substring(0, appEnd) +
                '        <meta-data\n' +
                '            android:name="com.google.android.geo.API_KEY"\n' +
                '            android:value="${state.apiKey}" />\n' +
                '    ' + manifestContent.substring(appEnd);
            await androidManifestFile.writeAsString(manifestContent);
          }
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
          // Add the import if it doesn't exist
          if (!appDelegateContent.contains('import GoogleMaps')) {
            appDelegateContent = appDelegateContent.replaceFirst(
              'import UIKit',
              'import UIKit\nimport GoogleMaps',
            );
          }
          
          // Add the API key initialization
          // Find didFinishLaunchingWithOptions
          final didFinishLaunchingMethod = appDelegateContent.indexOf('didFinishLaunchingWithOptions');
          if (didFinishLaunchingMethod >= 0) {
            // Find the first occurrence of GeneratedPluginRegistrant.register
            final registerPluginsLine = appDelegateContent.indexOf('GeneratedPluginRegistrant.register', didFinishLaunchingMethod);
            if (registerPluginsLine >= 0) {
              // Insert before register plugins
              appDelegateContent = appDelegateContent.substring(0, registerPluginsLine) +
                  '    GMSServices.provideAPIKey("${state.apiKey}")\n    ' +
                  appDelegateContent.substring(registerPluginsLine);
            }
          }
          await iosAppDelegateFile.writeAsString(appDelegateContent);
        }
      }
      
      // Configure iOS Info.plist to add location permissions
      final iosInfoPlistFile = File(path.join(
        state.projectDirectory!,
        'ios',
        'Runner',
        'Info.plist',
      ));
      
      if (await iosInfoPlistFile.exists()) {
        var infoPlistContent = await iosInfoPlistFile.readAsString();
        bool modified = false;
        
        // Add location usage descriptions if they don't exist
        if (!infoPlistContent.contains('NSLocationWhenInUseUsageDescription')) {
          final insertPoint = infoPlistContent.lastIndexOf('</dict>');
          if (insertPoint > 0) {
            infoPlistContent = infoPlistContent.substring(0, insertPoint) +
                '\t<key>NSLocationWhenInUseUsageDescription</key>\n' +
                '\t<string>This app needs access to location when open to show your position on the map.</string>\n' +
                '\t<key>NSLocationAlwaysUsageDescription</key>\n' +
                '\t<string>This app needs access to location when in the background.</string>\n' +
                '\t<key>io.flutter.embedded_views_preview</key>\n' +
                '\t<true/>\n' +
                infoPlistContent.substring(insertPoint);
            modified = true;
          }
        }
        
        if (modified) {
          await iosInfoPlistFile.writeAsString(infoPlistContent);
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

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
      home: BlocProvider(
        create: (context) => MapBloc(),
        child: const MapScreen(),
      ),
    );
  }
}

// Map Events
abstract class MapEvent extends Equatable {
  const MapEvent();
  
  @override
  List<Object> get props => [];
}

class MapCreated extends MapEvent {
  final GoogleMapController controller;
  
  const MapCreated(this.controller);
  
  @override
  List<Object> get props => [controller];
}

class MarkerAdded extends MapEvent {
  final LatLng position;
  
  const MarkerAdded(this.position);
  
  @override
  List<Object> get props => [position];
}

// Map States
class MapState extends Equatable {
  final GoogleMapController? controller;
  final Set<Marker> markers;
  final CameraPosition cameraPosition;
  
  const MapState({
    this.controller,
    this.markers = const {},
    this.cameraPosition = const CameraPosition(
      target: LatLng(0, 0),
      zoom: 11.0,
    ),
  });
  
  MapState copyWith({
    GoogleMapController? controller,
    Set<Marker>? markers,
    CameraPosition? cameraPosition,
  }) {
    return MapState(
      controller: controller ?? this.controller,
      markers: markers ?? this.markers,
      cameraPosition: cameraPosition ?? this.cameraPosition,
    );
  }
  
  @override
  List<Object?> get props => [markers, cameraPosition];
}

// Map Bloc
class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(const MapState()) {
    on<MapCreated>(_onMapCreated);
    on<MarkerAdded>(_onMarkerAdded);
  }
  
  void _onMapCreated(MapCreated event, Emitter<MapState> emit) {
    emit(state.copyWith(controller: event.controller));
  }
  
  void _onMarkerAdded(MarkerAdded event, Emitter<MapState> emit) {
    final newMarker = Marker(
      markerId: MarkerId('marker_\${state.markers.length}'),
      position: event.position,
      infoWindow: InfoWindow(
        title: 'Marker \${state.markers.length + 1}',
        snippet: '\${event.position.latitude}, \${event.position.longitude}',
      ),
    );
    
    final newMarkers = Set<Marker>.from(state.markers)..add(newMarker);
    
    emit(state.copyWith(
      markers: newMarkers,
      cameraPosition: CameraPosition(
        target: event.position,
        zoom: 14.0,
      ),
    ));
    
    state.controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: event.position,
          zoom: 14.0,
        ),
      ),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Example'),
      ),
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          return GoogleMap(
            onMapCreated: (controller) {
              context.read<MapBloc>().add(MapCreated(controller));
            },
            initialCameraPosition: state.cameraPosition,
            markers: state.markers,
            onTap: (position) {
              context.read<MapBloc>().add(MarkerAdded(position));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Default to a location in the middle of the world if no markers exist
          final target = BlocProvider.of<MapBloc>(context).state.markers.isEmpty
              ? const LatLng(0, 0)
              : BlocProvider.of<MapBloc>(context).state.markers.first.position;
              
          BlocProvider.of<MapBloc>(context).state.controller?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: target,
                zoom: 10.0,
              ),
            ),
          );
        },
        child: const Icon(Icons.center_focus_strong),
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