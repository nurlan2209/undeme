import 'package:flutter/material.dart';

import '../features/auth/data/auth_repository.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthRepository _authRepository = AuthRepository();

  bool isLogin = true;
  bool isLoading = false;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  bool _validate() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      _showError('Email және құпия сөз міндетті');
      return false;
    }

    if (!isLogin) {
      if (fullNameController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty) {
        _showError('Барлық өрістерді толтырыңыз');
        return false;
      }

      if (passwordController.text != confirmPasswordController.text) {
        _showError('Құпия сөздер сәйкес келмейді');
        return false;
      }

      if (passwordController.text.length < 8) {
        _showError('Құпия сөз кемінде 8 таңбадан тұруы керек');
        return false;
      }
    }

    return true;
  }

  Future<void> _handleAuth() async {
    if (!_validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isLogin) {
        await _authRepository.login(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      } else {
        await _authRepository.register(
          fullName: fullNameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
          password: passwordController.text,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (error) {
      if (mounted) {
        _showError(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield,
                      size: 64, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Undeme',
                  style: AppTextStyles.title.copyWith(fontSize: 32),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Төтенше жағдайлар қауіпсіздігі',
                    style: AppTextStyles.subtitle),
              ),
              const SizedBox(height: 48),
              Text(isLogin ? 'Кіру' : 'Тіркелу', style: AppTextStyles.title),
              const SizedBox(height: 24),
              if (!isLogin) ...[
                CustomTextField(
                  label: 'Толық аты-жөні',
                  hintText: 'Аты-жөніңізді енгізіңіз',
                  controller: fullNameController,
                ),
                const SizedBox(height: 16),
              ],
              CustomTextField(
                label: 'Email',
                hintText: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
                controller: emailController,
              ),
              const SizedBox(height: 16),
              if (!isLogin) ...[
                CustomTextField(
                  label: 'Телефон нөмірі',
                  hintText: '+7 (___) ___-__-__',
                  keyboardType: TextInputType.phone,
                  controller: phoneController,
                ),
                const SizedBox(height: 16),
              ],
              CustomTextField(
                label: 'Құпия сөз',
                hintText: '••••••••',
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 16),
              if (!isLogin) ...[
                CustomTextField(
                  label: 'Құпия сөзді растау',
                  hintText: '••••••••',
                  obscureText: true,
                  controller: confirmPasswordController,
                ),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 24),
              if (isLoading)
                const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
              else
                CustomButton(
                  text: isLogin ? 'Кіру' : 'Тіркелу',
                  onPressed: _handleAuth,
                ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin
                        ? 'Аккаунт жоқ па? Тіркелу'
                        : 'Аккаунт бар ма? Кіру',
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
