import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/app_access_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/screens/fino_home_screen.dart';

class AppLockedScreen extends StatefulWidget {
  final String title;
  final String message;
  final String? contactInfo;

  const AppLockedScreen({
    super.key,
    required this.title,
    required this.message,
    this.contactInfo,
  });

  @override
  State<AppLockedScreen> createState() => _AppLockedScreenState();
}

class _AppLockedScreenState extends State<AppLockedScreen> with SingleTickerProviderStateMixin {
  final AppAccessService _accessService = AppAccessService();
  int _tapCount = 0;
  DateTime? _lastTapTime;
  bool _isCheckingStatus = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleSecretTap() {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!).inSeconds > 3) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    if (_tapCount >= 5) {
      _tapCount = 0;
      _showAdminPinModal();
    }
  }

  Future<void> _checkLiveAccess() async {
    setState(() => _isCheckingStatus = true);
    HapticFeedback.lightImpact();

    final status = await _accessService.verifyAppAccess();
    if (!mounted) return;

    setState(() => _isCheckingStatus = false);

    if (status.isAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Access Restored! Welcome to Fino Pay.'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
              opacity: animation,
              child: const FinoHomeScreen(),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access is still restricted. Please try again later.'),
          backgroundColor: Color(0xFF334155),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAdminPinModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminPinBottomSheet(accessService: _accessService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B132B),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0B132B),
                Color(0xFF1C2541),
                Color(0xFF0B132B),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'FINO',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: Colors.white,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SECURE VAULT',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),

                  // Center Lock Card
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing Lock Icon with Secret Tap
                      GestureDetector(
                        onTap: _handleSecretTap,
                        behavior: HitTestBehavior.opaque,
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFEF4444).withValues(alpha: 0.25),
                                  const Color(0xFFEF4444).withValues(alpha: 0.05),
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.lock_rounded,
                                size: 52,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (widget.contactInfo != null && widget.contactInfo!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            widget.contactInfo!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF93C5FD),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Bottom Action Buttons
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Refresh / Re-check Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCheckingStatus ? null : _checkLiveAccess,
                          icon: _isCheckingStatus
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 20),
                          label: Text(_isCheckingStatus ? 'Checking Access...' : 'Check Access Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF334155)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Close App Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => SystemNavigator.pop(),
                          icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white54, size: 18),
                          label: const Text('Exit Application', style: TextStyle(color: Colors.white54)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminPinBottomSheet extends StatefulWidget {
  final AppAccessService accessService;
  const _AdminPinBottomSheet({required this.accessService});

  @override
  State<_AdminPinBottomSheet> createState() => _AdminPinBottomSheetState();
}

class _AdminPinBottomSheetState extends State<_AdminPinBottomSheet> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _enteredPin = '';
  String? _errorMessage;
  bool _isLoading = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeypadTap(String value) {
    if (_enteredPin.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin += value;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    final isSuccess = await widget.accessService.unlockWithMasterPin(_enteredPin);
    setState(() => _isLoading = false);

    if (isSuccess && mounted) {
      HapticFeedback.heavyImpact();
      Navigator.pop(context); // Close bottom sheet
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FinoHomeScreen()),
      );
    } else {
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0.0);
      setState(() {
        _errorMessage = 'Incorrect Master PIN. Please try again.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icon & Title
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF60A5FA), size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'Master Developer Unlock',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your 4-digit PIN to bypass remote lock',
            style: TextStyle(fontSize: 12.5, color: Colors.white60),
          ),
          const SizedBox(height: 24),

          // PIN Indicators with Shake Animation
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final offset = _shakeController.isAnimating
                  ? (6.0 * (1.0 - _shakeController.value) * ((_shakeController.value * 12).floor() % 2 == 0 ? 1 : -1))
                  : 0.0;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? const Color(0xFF60A5FA) : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? const Color(0xFF60A5FA) : Colors.white30,
                      width: 2,
                    ),
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: const Color(0xFF60A5FA).withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],

          const SizedBox(height: 24),

          // Custom Sleek Numeric Keypad
          _buildNumericKeypad(),
        ],
      ),
    );
  }

  Widget _buildNumericKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 72, height: 60);
              }
              if (key == '⌫') {
                return SizedBox(
                  width: 72,
                  height: 60,
                  child: IconButton(
                    onPressed: _isLoading ? null : _onBackspace,
                    icon: const Icon(Icons.backspace_outlined, color: Colors.white70, size: 22),
                  ),
                );
              }
              return SizedBox(
                width: 72,
                height: 60,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading ? null : () => _onKeypadTap(key),
                    child: Center(
                      child: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

