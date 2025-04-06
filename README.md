# Google Maps Flutter Integration Tool

This tool helps you automatically integrate Google Maps Flutter into your Flutter project. It provides a step-by-step interface to:

1. Select your Flutter project directory
2. Add the Google Maps Flutter package
3. Configure your Google Maps API key
4. Set up platform-specific configurations
5. Add a simple example implementation

## Features

- Easy-to-use step-by-step interface
- Automatic package integration
- Platform-specific configuration (Android & iOS)
- Example implementation with a basic map
- Error handling and validation
- Progress tracking

## Requirements

- Flutter SDK
- Google Maps API key
- A Flutter project to integrate with

## Getting Started

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Run the application using `flutter run -d chrome` (for web)
4. Follow the step-by-step interface to integrate Google Maps into your project

## Steps

1. **Select Project Directory**
   - Choose your Flutter project directory
   - The tool will verify it's a valid Flutter project

2. **Add Package**
   - The tool will automatically add the Google Maps Flutter package to your pubspec.yaml

3. **API Key**
   - Enter your Google Maps API key
   - You can get one from the Google Cloud Console

4. **Configure Platforms**
   - The tool will automatically configure platform-specific settings
   - Android: Updates AndroidManifest.xml
   - iOS: Updates AppDelegate.swift

5. **Add Example**
   - A simple Google Maps example will be added to your project
   - The example includes a basic map implementation

## Notes

- Make sure you have a valid Google Maps API key
- The tool requires write permissions to modify your project files
- Backup your project before using this tool
- The example implementation can be customized after integration

## License

This project is licensed under the MIT License - see the LICENSE file for details.
