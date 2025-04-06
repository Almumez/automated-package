import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../bloc/google_maps_integration_bloc.dart';
import '../bloc/google_maps_integration_event.dart';
import '../bloc/google_maps_integration_state.dart';

class GoogleMapsIntegrationScreen extends StatefulWidget {
  const GoogleMapsIntegrationScreen({super.key});

  @override
  State<GoogleMapsIntegrationScreen> createState() => _GoogleMapsIntegrationScreenState();
}

class _GoogleMapsIntegrationScreenState extends State<GoogleMapsIntegrationScreen> {
  int currentStep = 0;
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    // Request permissions after UI loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsWithDialog();
    });
  }

  // Request permissions with an explanatory dialog
  void _requestPermissionsWithDialog() {
    if (_permissionsRequested || kIsWeb) return;
    
    _permissionsRequested = true;
    
    if (!kIsWeb && Platform.isAndroid) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Permission Request'),
          content: const Text(
            'This app needs storage access permissions to read and modify your Flutter project files. '
            'Please grant the required permissions to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<GoogleMapsIntegrationBloc>().add(RequestPermissions());
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Integration Tool'),
      ),
      body: BlocBuilder<GoogleMapsIntegrationBloc, GoogleMapsIntegrationState>(
        builder: (context, state) {
          // Update the current step based on state
          currentStep = _getActiveStep(state);
          
          return Column(
            children: [
              EasyStepper(
                activeStep: currentStep,
                stepShape: StepShape.rRectangle,
                stepBorderRadius: 15,
                internalPadding: 0,
                showLoadingAnimation: false,
                onStepReached: (index) {
                  setState(() {
                    currentStep = index;
                  });
                },
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
                    enabled: state.projectDirectory != null,
                  ),
                  EasyStep(
                    customStep: CircleAvatar(
                      backgroundColor: state.apiKey != null
                          ? Colors.green
                          : Colors.grey,
                      child: const Icon(Icons.key, color: Colors.white),
                    ),
                    title: 'API Key',
                    enabled: state.isPackageAdded,
                  ),
                  EasyStep(
                    customStep: CircleAvatar(
                      backgroundColor: state.isPlatformConfigured
                          ? Colors.green
                          : Colors.grey,
                      child: const Icon(Icons.settings, color: Colors.white),
                    ),
                    title: 'Configure',
                    enabled: state.apiKey != null,
                  ),
                  EasyStep(
                    customStep: CircleAvatar(
                      backgroundColor: state.isExampleAdded
                          ? Colors.green
                          : Colors.grey,
                      child: const Icon(Icons.map, color: Colors.white),
                    ),
                    title: 'Add Example',
                    enabled: state.isPlatformConfigured,
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
    if (!state.isPackageAdded) return 1;
    if (state.apiKey == null) return 2;
    if (!state.isPlatformConfigured) return 3;
    if (!state.isExampleAdded) return 4;
    return 4;
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

    switch (currentStep) {
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
            if (!kIsWeb && Platform.isAndroid) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Storage Permissions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This app needs storage access to read and modify your project files',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<GoogleMapsIntegrationBloc>().add(
                                RequestPermissions(),
                              );
                        },
                        icon: const Icon(Icons.security),
                        label: const Text('Request Permissions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
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
                    decoration: const InputDecoration(
                      hintText: 'Enter project directory path',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        context.read<GoogleMapsIntegrationBloc>().add(
                              SelectProjectDirectory(value),
                            );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!kIsWeb && Platform.isAndroid)
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<GoogleMapsIntegrationBloc>().add(
                                  RequestPermissions(),
                                );
                          },
                          icon: const Icon(Icons.perm_device_information),
                          label: const Text('Request Permissions'),
                        ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            if (!kIsWeb && Platform.isAndroid) {
                              // Request permissions first
                              context.read<GoogleMapsIntegrationBloc>().add(
                                    RequestPermissions(),
                                  );
                            }
                            
                            final String? directoryPath;
                            if (kIsWeb) {
                              // On web, just use the text field value
                              directoryPath = directoryController.text.isNotEmpty
                                  ? directoryController.text
                                  : null;
                            } else {
                              // On native platforms, use file selector
                              directoryPath = await getDirectoryPath(
                                confirmButtonText: 'Select Directory',
                                initialDirectory: state.projectDirectory,
                              );
                            }
                            
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
                      if (directoryController.text.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (directoryController.text.isNotEmpty) {
                              context.read<GoogleMapsIntegrationBloc>().add(
                                    SelectProjectDirectory(directoryController.text),
                                  );
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Confirm'),
                        ),
                      ],
                      if (state.projectDirectory != null) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.check_circle, color: Colors.green),
                      ]
                    ],
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Add Google Maps Flutter package to your project',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'We will add the google_maps_flutter package to your pubspec.yaml file',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: 500,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The following line will be added to your pubspec.yaml:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'google_maps_flutter: ^2.5.3',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: state.isPackageAdded 
                      ? null 
                      : () {
                          // Show a loading indicator before adding
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Adding package to pubspec.yaml...'),
                                ],
                              ),
                            ),
                          );
                          
                          // Add the package
                          context.read<GoogleMapsIntegrationBloc>().add(
                                AddGoogleMapsPackage(),
                              );
                              
                          // Close the dialog after a delay
                          Future.delayed(const Duration(seconds: 1), () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          });
                        },
                  icon: const Icon(Icons.add_box),
                  label: const Text('Add Package'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isPackageAdded ? Colors.grey : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                if (state.isPackageAdded) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Package added successfully', 
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              ],
            ),
            if (state.error != null && currentStep == 1) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Error adding package',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You can continue by manually adding the package to your pubspec.yaml file and clicking the button below.',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        context.read<GoogleMapsIntegrationBloc>().add(
                              AddGoogleMapsPackage(),
                            );
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
            textAlign: TextAlign.center,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              if (state.apiKey != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text('API key saved', style: TextStyle(color: Colors.green)),
              ]
            ],
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: state.isPlatformConfigured 
                    ? null 
                    : () {
                        context.read<GoogleMapsIntegrationBloc>().add(
                              ConfigurePlatforms(),
                            );
                      },
                icon: const Icon(Icons.settings),
                label: const Text('Configure Platforms'),
              ),
              if (state.isPlatformConfigured) ...[
                const SizedBox(width: 16),
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Platforms configured', style: TextStyle(color: Colors.green)),
              ]
            ],
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: state.isExampleAdded 
                    ? null 
                    : () {
                        context.read<GoogleMapsIntegrationBloc>().add(
                              AddMapExample(),
                            );
                      },
                icon: const Icon(Icons.map),
                label: const Text('Add Example'),
              ),
              if (state.isExampleAdded) ...[
                const SizedBox(width: 16),
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Example added successfully', style: TextStyle(color: Colors.green)),
              ]
            ],
          ),
        ],
      ),
    );
  }
} 