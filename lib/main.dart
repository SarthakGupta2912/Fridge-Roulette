import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/chef_brain.dart';
import 'services/detector_service.dart';
import 'services/recipe_generator.dart';
import 'strings.dart';
import 'theme.dart';

/// The app starts here. We also set up safe error handling here.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Developers see the error in the console. The child sees a friendly card.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Something went wrong: $error');
    return true;
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const FriendlyErrorWidget();
  };

  // Starting the plugin is quick. If it fails, the Quick chef still works.
  final ChefBrain chefBrain = ChefBrain();
  await chefBrain.initialize();

  runApp(FridgeRouletteApp(chefBrain: chefBrain));
}

/// The root of the app. It loads the food finder once and reuses it everywhere.
class FridgeRouletteApp extends StatefulWidget {
  const FridgeRouletteApp({super.key, required this.chefBrain});

  final ChefBrain chefBrain;

  @override
  State<FridgeRouletteApp> createState() => _FridgeRouletteAppState();
}

class _FridgeRouletteAppState extends State<FridgeRouletteApp> {
  final DetectorService _detector = DetectorService();
  final RecipeGenerator _generator = RecipeGenerator();
  Timer? _splashTimer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Load in the background. The splash gives it a friendly head start.
    _detector.loadModel();
    _splashTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _detector.dispose();
    unawaited(_generator.release());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _showSplash
            ? const SplashScreen(key: ValueKey<String>('splash'))
            : HomeScreen(
                key: const ValueKey<String>('home'),
                detector: _detector,
                chefBrain: widget.chefBrain,
                generator: _generator,
              ),
      ),
    );
  }
}

/// A safe, non-technical widget shown if a widget fails to build.
class FriendlyErrorWidget extends StatelessWidget {
  const FriendlyErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFF3E0),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('😵', style: TextStyle(fontSize: 56)),
                SizedBox(height: 12),
                Text(
                  AppStrings.errorTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D1B00),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  AppStrings.errorBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: Color(0xFF4A3200)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
