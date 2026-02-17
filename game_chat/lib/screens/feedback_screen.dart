// lib/screens/feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/sound_manager.dart';
import '../widgets/animated_background.dart';
import 'dart:math' as math;

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _starController;
  late List<AnimationController> _cardControllers;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final SoundManager _soundManager = SoundManager();
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  
  // State variables
  int _selectedRating = 0;
  String _selectedFeedbackType = 'General';
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  
  // API Configuration
  static const String apiBaseUrl = 'http://api.aswdc.in/Api/MST_AppVersions';
  static const String apiKey = '1234';
  static const String appName = 'Word Search Evolution'; // Change this to your app name
  static const String versionNo = '1.0'; // Change this to your app version
  static const String platform = 'Android'; // or 'iOS' based on platform
  
  final List<String> _feedbackTypes = [
    'General',
    'Bug Report',
    'Feature Request',
    'Gameplay',
    'UI/UX',
    'Performance',
  ];
  
  final List<IconData> _feedbackIcons = [
    Icons.chat_bubble_outline,
    Icons.bug_report,
    Icons.lightbulb_outline,
    Icons.videogame_asset,
    Icons.design_services,
    Icons.speed,
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _starController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cardControllers = List.generate(5, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 800 + (index * 100)),
        vsync: this,
      );
    });

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
    
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 500 + (i * 150)), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _starController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  // API Methods
  Future<bool> _submitFeedbackToAPI() async {
    try {
      final url = Uri.parse('$apiBaseUrl/PostAppFeedback/AppPostFeedback');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'API_KEY': apiKey,
        },
        body: {
          'AppName': appName,
          'VersionNo': versionNo,
          'Platform': platform,
          'PersonName': _nameController.text.trim(),
          'Mobile': _mobileController.text.trim(),
          'Email': _emailController.text.trim(),
          'Message': _feedbackController.text.trim(),
          'Remarks': 'Rating: $_selectedRating/5, Category: $_selectedFeedbackType',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Check if the API response indicates success
        if (jsonResponse['IsResult'] == 1) {
          return true;
        } else {
          print('API Error: ${jsonResponse['Message']}');
          return false;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Exception during API call: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _hasSubmitted ? _buildThankYouSection() : _buildFeedbackForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                _soundManager.playButtonClick();
                Get.back();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 20),
            const Text(
              'Feedback',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeSection(),
        const SizedBox(height: 30),
        _buildRatingSection(),
        const SizedBox(height: 25),
        _buildFeedbackTypeSection(),
        const SizedBox(height: 25),
        _buildContactInfoSection(),
        const SizedBox(height: 25),
        _buildFeedbackTextSection(),
        const SizedBox(height: 35),
        _buildSubmitButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return _buildAnimatedCard(
      0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.blue.withOpacity(0.3),
              Colors.purple.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white,
                    Colors.blue.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.feedback_outlined,
                color: Color(0xFF1E3A8A),
                size: 35,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'We Value Your Opinion',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your feedback helps us create better gaming experiences. Share your thoughts, report issues, or suggest new features.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return _buildAnimatedCard(
      1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.amber.withOpacity(0.2),
              Colors.black.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.amber.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate Your Experience',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => _buildStar(index + 1)),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _getRatingText(_selectedRating),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.amber.shade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStar(int rating) {
    final isSelected = rating <= _selectedRating;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRating = rating);
        _soundManager.playButtonClick();
        _starController.forward().then((_) => _starController.reverse());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        child: Icon(
          isSelected ? Icons.star : Icons.star_border,
          color: isSelected ? Colors.amber : Colors.white.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return 'Poor - Needs improvement';
      case 2: return 'Fair - Could be better';
      case 3: return 'Good - Satisfactory';
      case 4: return 'Great - Really enjoyed it';
      case 5: return 'Excellent - Love it!';
      default: return 'Tap stars to rate';
    }
  }

  Widget _buildFeedbackTypeSection() {
    return _buildAnimatedCard(
      2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.purple.withOpacity(0.15),
              Colors.black.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.purple.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feedback Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _feedbackTypes.asMap().entries.map((entry) {
                final index = entry.key;
                final type = entry.value;
                final isSelected = type == _selectedFeedbackType;
                
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFeedbackType = type);
                    _soundManager.playButtonClick();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [Colors.purple.withOpacity(0.8), Colors.pink.withOpacity(0.6)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.purple.withOpacity(0.8) 
                            : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _feedbackIcons[index],
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return _buildAnimatedCard(
      3,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.green.withOpacity(0.15),
              Colors.black.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _nameController,
              hint: 'Your full name *',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _mobileController,
              hint: 'Mobile number *',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              hint: 'Email address *',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll use this information to follow up on your feedback if needed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackTextSection() {
    return _buildAnimatedCard(
      4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.orange.withOpacity(0.15),
              Colors.black.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Your Feedback',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 6,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Tell us about your experience, report a bug, suggest a feature, or share any other thoughts...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.6),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: GestureDetector(
        onTap: _isSubmitting ? null : _submitFeedback,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isSubmitting
                  ? [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.3)]
                  : [Colors.blue, Colors.purple],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!_isSubmitting)
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Center(
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sending...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Submit Feedback',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildThankYouSection() {
    return Column(
      children: [
        const SizedBox(height: 50),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.green.withOpacity(0.3),
                Colors.teal.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      Colors.green.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF1E3A8A),
                  size: 50,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Your feedback has been received and is valuable to us. We appreciate you taking the time to help us improve Word Search Evolution.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  _soundManager.playButtonClick();
                  Get.back();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Back to Game',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    // Validate required fields
    if (_feedbackController.text.trim().isEmpty) {
      _showSnackBar('Please enter your feedback before submitting');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your name');
      return;
    }

    if (_mobileController.text.trim().isEmpty) {
      _showSnackBar('Please enter your mobile number');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter your email address');
      return;
    }

    if (_selectedRating == 0) {
      _showSnackBar('Please rate your experience');
      return;
    }

    // Validate email format
    if (!GetUtils.isEmail(_emailController.text.trim())) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    // Validate mobile number (basic validation)
    if (_mobileController.text.trim().length < 10) {
      _showSnackBar('Please enter a valid mobile number');
      return;
    }

    setState(() => _isSubmitting = true);
    _soundManager.playButtonClick();

    try {
      // Submit feedback to ASWDC API
      bool success = await _submitFeedbackToAPI();
      
      if (success) {
        setState(() {
          _isSubmitting = false;
          _hasSubmitted = true;
        });
        _soundManager.playCelebration();
      } else {
        setState(() => _isSubmitting = false);
        _showSnackBar('Failed to submit feedback. Please try again.');
      }

    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Network error. Please check your connection and try again.');
    }
  }

  void _showSnackBar(String message) {
    Get.snackbar(
      'Feedback',
      message,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
    );
  }

  Widget _buildAnimatedCard(int index, {required Widget child}) {
    if (index >= _cardControllers.length) {
      return child;
    }

    return AnimatedBuilder(
      animation: _cardControllers[index],
      builder: (context, _) {
        final animation = CurvedAnimation(
          parent: _cardControllers[index],
          curve: Curves.easeOutBack,
        );
        
        final translationOffset = (1 - animation.value.clamp(0.0, 1.0)) * 30;
        final scaleValue = (0.9 + (0.1 * animation.value.clamp(0.0, 1.0))).clamp(0.0, 1.0);
        final opacityValue = animation.value.clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(0, translationOffset),
          child: Transform.scale(
            scale: scaleValue,
            child: Opacity(
              opacity: opacityValue,
              child: child,
            ),
          ),
        );
      },
    );
  }
}