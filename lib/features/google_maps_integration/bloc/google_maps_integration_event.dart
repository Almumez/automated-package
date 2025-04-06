import 'package:equatable/equatable.dart';

abstract class GoogleMapsIntegrationEvent extends Equatable {
  const GoogleMapsIntegrationEvent();

  @override
  List<Object?> get props => [];
}

class SelectProjectDirectory extends GoogleMapsIntegrationEvent {
  final String directoryPath;

  const SelectProjectDirectory(this.directoryPath);

  @override
  List<Object?> get props => [directoryPath];
}

class AddGoogleMapsPackage extends GoogleMapsIntegrationEvent {}

class SetApiKey extends GoogleMapsIntegrationEvent {
  final String apiKey;

  const SetApiKey(this.apiKey);

  @override
  List<Object?> get props => [apiKey];
}

class ConfigurePlatforms extends GoogleMapsIntegrationEvent {}

class AddMapExample extends GoogleMapsIntegrationEvent {} 