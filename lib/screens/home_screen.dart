import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sign_to_text_screen.dart';
import 'text_to_sign_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Flutter3DController _welcomeController = Flutter3DController();

  @override
  void initState() {
    super.initState();

    // Listen for when the model is fully loaded
    _welcomeController.onModelLoaded.addListener(() {
      if (_welcomeController.onModelLoaded.value) {
        // Play any initial animation you want (optional)
        _welcomeController.playAnimation(animationName: 'WW_Emote_CleanShield');

        // Adjust the position of the model so it's nice and zoomed in
        _welcomeController.setCameraTarget(0, 1.6, 0);
        _welcomeController.setCameraOrbit(0, 70, 4);
      }
    });
  }

  @override
  void dispose() {
    _welcomeController.onModelLoaded.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep your pastel background
      backgroundColor: const Color(0xFFF5E6C8),
      appBar: AppBar(
        title: const Text(
          'Sign Language Translator',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF8B6F47),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 3D Model Container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Flutter3DViewer(
                    controller: _welcomeController,
                    src: 'assets/models/animations/ww.glb',
                    // Use your existing glb file
                  ),
                ),
              ),
            ),
          ),

          // Side-by-side Buttons (instead of a "navbar")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Text to Sign
                Expanded(
                  child: _buildModeButton(
                    context,
                    'Text to Sign',
                    Icons.text_fields,
                    const Color(0xFF8B6F47),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TextToSignScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Sign to Text
                Expanded(
                  child: _buildModeButton(
                    context,
                    'Sign to Text',
                    Icons.sign_language,
                    const Color(0xFF8B6F47),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignToTextScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Optional Quotation or any footer text (adjust as needed)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Text(
              "'Connection beyond words, expression beyond limits.' - Mathew Raino",
              style: GoogleFonts.marckScript(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                fontSize: 20,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
