import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

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
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 64,
                    color: AppColors.primary,
                  ),
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
                child: Text(
                  'Төтенше жағдайлар қауіпсіздігі',
                  style: AppTextStyles.subtitle,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                isLogin ? 'Кіру' : 'Тіркелу',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 24),
              if (!isLogin) ...[
                const CustomTextField(
                  label: 'Толық аты-жөні',
                  hintText: 'Аты-жөніңізді енгізіңіз',
                ),
                const SizedBox(height: 16),
              ],
              const CustomTextField(
                label: 'Email',
                hintText: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              if (!isLogin) ...[
                const CustomTextField(
                  label: 'Телефон нөмірі',
                  hintText: '+7 (___) ___-__-__',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
              ],
              const CustomTextField(
                label: 'Құпия сөз',
                hintText: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (!isLogin) ...[
                const CustomTextField(
                  label: 'Құпия сөзді растау',
                  hintText: '••••••••',
                  obscureText: true,
                ),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 24),
              CustomButton(
                text: isLogin ? 'Кіру' : 'Тіркелу',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
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
