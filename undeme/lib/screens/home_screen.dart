import 'package:flutter/material.dart';

import '../features/sos/presentation/sos_controller.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import 'legal_screen.dart';
import 'profile_screen.dart';
import 'services_screen.dart';
import '../features/ai/presentation/ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final SosController _sosController = SosController();

  @override
  void initState() {
    super.initState();
    _sosController.init();
  }

  @override
  void dispose() {
    _sosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 1) {
      return ServicesScreen(
        onNavigateBack: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      );
    }

    if (_currentIndex == 2) {
      return AiChatScreen(
        onNavigateBack: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      );
    }

    if (_currentIndex == 3) {
      return LegalScreen(
        onNavigateBack: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      );
    }

    if (_currentIndex == 4) {
      return ProfileScreen(
        onNavigateBack: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      );
    }

    return AnimatedBuilder(
      animation: _sosController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Undeme',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text('Төтенше SOS', style: AppTextStyles.caption),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text('Төтенше SOS', style: AppTextStyles.title),
                const SizedBox(height: 8),
                Text(
                  'Қате басуды болдырмау үшін батырманы ұзақ басыңыз',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_sosController.hasPendingQueue)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Желі қалпына келгенде кезектегі SOS автоматты жіберіледі',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onLongPress: _sosController.phase == SosPhase.countdown
                        ? null
                        : () async {
                            await _sosController.startCountdown();
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        color: _buttonColor(_sosController.phase),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _buttonColor(_sosController.phase)
                                .withValues(alpha: 0.35),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🚨', style: TextStyle(fontSize: 42)),
                          const SizedBox(height: 10),
                          const Text(
                            'SOS',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _sosController.phase == SosPhase.countdown
                                ? '${_sosController.countdown}'
                                : 'Ұзақ басыңыз',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _sosController.statusMessage,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (_sosController.phase == SosPhase.countdown)
                  OutlinedButton(
                    onPressed: _sosController.cancelCountdown,
                    child: const Text('Жіберуді тоқтату'),
                  ),
                if (_sosController.phase == SosPhase.error)
                  ElevatedButton(
                    onPressed: () async {
                      await _sosController.triggerSos();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: const Text('Қайта жіберу'),
                  ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Flow: long-press → 4 сек countdown → GPS → контактілерге жіберу. Интернет болмаса, кезекке түседі.',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }

  Color _buttonColor(SosPhase phase) {
    switch (phase) {
      case SosPhase.countdown:
        return Colors.orange;
      case SosPhase.sending:
        return Colors.deepOrange;
      case SosPhase.success:
        return Colors.green;
      case SosPhase.queuedOffline:
        return Colors.blueGrey;
      case SosPhase.error:
        return Colors.red.shade700;
      case SosPhase.idle:
        return AppColors.primary;
    }
  }
}
