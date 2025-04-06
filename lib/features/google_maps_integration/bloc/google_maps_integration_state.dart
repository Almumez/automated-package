import 'package:equatable/equatable.dart';

class GoogleMapsIntegrationState extends Equatable {
  final String? projectDirectory;
  final bool isPackageAdded;
  final String? apiKey;
  final bool isPlatformConfigured;
  final bool isExampleAdded;
  final String? error;
  final bool isLoading;

  const GoogleMapsIntegrationState({
    this.projectDirectory,
    this.isPackageAdded = false,
    this.apiKey,
    this.isPlatformConfigured = false,
    this.isExampleAdded = false,
    this.error,
    this.isLoading = false,
  });

  GoogleMapsIntegrationState copyWith({
    String? projectDirectory,
    bool? isPackageAdded,
    String? apiKey,
    bool? isPlatformConfigured,
    bool? isExampleAdded,
    String? error,
    bool? isLoading,
  }) {
    return GoogleMapsIntegrationState(
      projectDirectory: projectDirectory ?? this.projectDirectory,
      isPackageAdded: isPackageAdded ?? this.isPackageAdded,
      apiKey: apiKey ?? this.apiKey,
      isPlatformConfigured: isPlatformConfigured ?? this.isPlatformConfigured,
      isExampleAdded: isExampleAdded ?? this.isExampleAdded,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        projectDirectory,
        isPackageAdded,
        apiKey,
        isPlatformConfigured,
        isExampleAdded,
        error,
        isLoading,
      ];
} 