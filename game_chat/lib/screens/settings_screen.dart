import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/sound_manager.dart';
import '../widgets/animated_background.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SoundManager soundManager;

  @override
  void initState() {
    super.initState();
    soundManager = SoundManager();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        soundManager.playButtonClick();
                        Get.back();
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Settings List
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Audio Settings Section
                      _buildSectionHeader('Audio Settings', Icons.volume_up),
                      
                      // Sound Effects Toggle
                      _buildToggleSetting(
                        title: 'Sound Effects',
                        subtitle: 'Game sounds and button clicks',
                        icon: soundManager.soundEnabled ? Icons.music_note : Icons.music_off,
                        value: soundManager.soundEnabled,
                        onChanged: (value) {
                          setState(() {
                            soundManager.soundEnabled = value;
                          });
                          if (value) {
                            soundManager.playButtonClick();
                          }
                        },
                      ),

                      // Background Music Toggle
                      _buildToggleSetting(
                        title: 'Background Music',
                        subtitle: 'Ambient music during gameplay',
                        icon: soundManager.musicEnabled ? Icons.library_music : Icons.music_off,
                        value: soundManager.musicEnabled,
                        onChanged: (value) {
                          setState(() {
                            soundManager.musicEnabled = value;
                          });
                          soundManager.playButtonClick();
                        },
                      ),

                      // Sound Volume Slider
                      if (soundManager.soundEnabled)
                        _buildSliderSetting(
                          title: 'Sound Effects Volume',
                          icon: Icons.volume_up,
                          value: soundManager.soundVolume,
                          onChanged: (value) {
                            setState(() {
                              soundManager.soundVolume = value;
                            });
                          },
                          onChangeEnd: (value) {
                            soundManager.playButtonClick();
                          },
                        ),

                      // Music Volume Slider
                      if (soundManager.musicEnabled)
                        _buildSliderSetting(
                          title: 'Background Music Volume',
                          icon: Icons.library_music,
                          value: soundManager.musicVolume,
                          onChanged: (value) {
                            setState(() {
                              soundManager.musicVolume = value;
                            });
                          },
                        ),

                      const SizedBox(height: 30),

                      // Test Sounds Section
                      // _buildSectionHeader('Test Sounds', Icons.play_circle),

                      // _buildTestButton(
                      //   title: 'Word Found',
                      //   icon: Icons.check_circle,
                      //   color: Colors.green,
                      //   onTap: () => soundManager.playWordFound(),
                      // ),

                      // _buildTestButton(
                      //   title: 'Level Complete',
                      //   icon: Icons.celebration,
                      //   color: Colors.orange,
                      //   onTap: () => soundManager.playLevelComplete(),
                      // ),

                      // _buildTestButton(
                      //   title: 'Stars Earned (3)',
                      //   icon: Icons.star,
                      //   color: Colors.yellow,
                      //   onTap: () => soundManager.playStarEarned(),
                      // ),

                      // _buildTestButton(
                      //   title: 'Invalid Selection',
                      //   icon: Icons.close,
                      //   color: Colors.red,
                      //   onTap: () => soundManager.playInvalidSelection(),
                      // ),

                      // const SizedBox(height: 30),

                      // Reset Section
                      _buildSectionHeader('Reset', Icons.refresh),

                      _buildActionButton(
                        title: 'Reset Audio Settings',
                        subtitle: 'Restore default audio settings',
                        icon: Icons.restore,
                        color: Colors.blue,
                        onTap: () {
                          _showResetDialog();
                        },
                      ),

                      const SizedBox(height: 30),

                      // Share Section
                      _buildSectionHeader('Spread the Word', Icons.share),
                      _buildActionButton(
                        title: 'Share Application',
                        subtitle: 'Invite your friends to play!',
                        icon: Icons.share_outlined,
                        color: Colors.green,
                        onTap: () {
                          soundManager.playButtonClick();
                          Share.share('Check out Word Search: Evolution! The ultimate word search experience. #WordSearch #Gaming');
                        },
                      ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.blue,
              overlayColor: Colors.blue.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
              min: 0.0,
              max: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Icon(Icons.play_arrow, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog() {
    soundManager.playButtonClick();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        title: const Text(
          'Reset Audio Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will restore all audio settings to their default values. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              soundManager.playButtonClick();
              Get.back();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              soundManager.playButtonClick();
              setState(() {
                soundManager.soundEnabled = true;
                soundManager.musicEnabled = true;
                soundManager.soundVolume = 0.7;
                soundManager.musicVolume = 0.3;
              });
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}