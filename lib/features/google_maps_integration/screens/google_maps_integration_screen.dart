import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../bloc/google_maps_integration_bloc.dart';
import '../bloc/google_maps_integration_event.dart';
import '../bloc/google_maps_integration_state.dart';

class GoogleMapsIntegrationScreen extends StatelessWidget {
  const GoogleMapsIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Integration Tool'),
      ),
      body: BlocBuilder<GoogleMapsIntegrationBloc, GoogleMapsIntegrationState>(
        builder: (context, state) {
          return Column(
            children: [
              EasyStepper(
                activeStep: _getActiveStep(state),
                stepShape: StepShape.rRectangle,
                stepBorderRadius: 15,
                internalPadding: 0,
                showLoadingAnimation: false,
                steps: [
                  EasyStep(
                    customStep: CircleAvatar(
                      backgroundColor: state.projectDirectory != null
                          ? Colors.green
                          : Colors.grey,
                      child: const Icon(Icons.folder, color: Colors.white),
                    ),
                    title: 'Select Project',
                  ),
                  EasyStep(
                    customStep: CircleAvatar(
                      backgroundColor: state.isPackageAdded
                          ? Colors.green
                          : Colors.grey,
                      child: const Icon(Icons.add_box, color: Colors.white),
                    ),
                    title: 'Add Package',
                  ),
                  EasyStep(
                    customStep: CircleAvatar(
                      backgroundColor: state.apiKey != null
                          ? Colors.green
                          : Colors.grey,
                      child: const Icon(Icons.key, color: Colors.white),
                    ),
                    title: 'API Key',
                  ),
                  EasyStep(
                    customStep: CircleAvatar(
                      backgroundColor: state.isPlatformConfigured
                          ? Colors.green
                          : Colors.grey,
                      child: const Icon(Icons.settings, color: Colors.white),
                    ),
                    title: 'Configure',
                  ),
                  EasyStep(
                    customStep: CircleAvatar(
                      backgroundColor: state.isExampleAdded
                          ? Colors.green
                          : Colors.grey,
                      child: const Icon(Icons.map, color: Colors.white),
                    ),
                    title: 'Add Example',
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildStepContent(context, state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _getActiveStep(GoogleMapsIntegrationState state) {
    if (state.projectDirectory == null) return 0;
    if (state.isPackageAdded) return 1;
    if (state.apiKey != null) return 2;
    if (state.isPlatformConfigured) return 3;
    if (state.isExampleAdded) return 4;
    return 0;
  }

  Widget _buildStepContent(
    BuildContext context,
    GoogleMapsIntegrationState state,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<GoogleMapsIntegrationBloc>().add(
                      SelectProjectDirectory(''),
                    );
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    switch (_getActiveStep(state)) {
      case 0:
        return _buildSelectProjectStep(context, state);
      case 1:
        return _buildAddPackageStep(context, state);
      case 2:
        return _buildApiKeyStep(context, state);
      case 3:
        return _buildConfigurePlatformsStep(context, state);
      case 4:
        return _buildAddExampleStep(context, state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectProjectStep(
    BuildContext context,
    GoogleMapsIntegrationState state,
  ) {
    final directoryController = TextEditingController(text: state.projectDirectory);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select your Flutter project directory',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your Flutter project directory',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  TextField(
                    controller: directoryController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: 'Selected directory path will appear here',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final String? directoryPath = await getDirectoryPath(
                          confirmButtonText: 'Select Directory',
                          initialDirectory: state.projectDirectory,
                        );
                        if (directoryPath != null) {
                          context.read<GoogleMapsIntegrationBloc>().add(
                                SelectProjectDirectory(directoryPath),
                              );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error selecting directory: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Choose Directory'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Note: Make sure the directory contains a valid Flutter project with pubspec.yaml',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPackageStep(
    BuildContext context,
    GoogleMapsIntegrationState state,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Add Google Maps Flutter package to your project',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<GoogleMapsIntegrationBloc>().add(
                    AddGoogleMapsPackage(),
                  );
            },
            icon: const Icon(Icons.add_box),
            label: const Text('Add Package'),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyStep(
    BuildContext context,
    GoogleMapsIntegrationState state,
  ) {
    final apiKeyController = TextEditingController(text: state.apiKey);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Enter your Google Maps API Key',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                hintText: 'Enter your API key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  context.read<GoogleMapsIntegrationBloc>().add(
                        SetApiKey(value),
                      );
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (apiKeyController.text.isNotEmpty) {
                context.read<GoogleMapsIntegrationBloc>().add(
                      SetApiKey(apiKeyController.text),
                    );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save API Key'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurePlatformsStep(
    BuildContext context,
    GoogleMapsIntegrationState state,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Configure platform-specific settings',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<GoogleMapsIntegrationBloc>().add(
                    ConfigurePlatforms(),
                  );
            },
            icon: const Icon(Icons.settings),
            label: const Text('Configure Platforms'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExampleStep(
    BuildContext context,
    GoogleMapsIntegrationState state,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Add a simple Google Maps example to your project',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<GoogleMapsIntegrationBloc>().add(
                    AddMapExample(),
                  );
            },
            icon: const Icon(Icons.map),
            label: const Text('Add Example'),
          ),
        ],
      ),
    );
  }
} 