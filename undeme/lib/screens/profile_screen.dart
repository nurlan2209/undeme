import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/domain/emergency_contact.dart';
import '../features/profile/domain/user_profile.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onNavigateBack});

  final Function(int)? onNavigateBack;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final AuthRepository _authRepository = AuthRepository();

  int _currentIndex = 4;
  bool isLoading = true;
  bool isSavingProfile = false;

  UserProfile? userProfile;
  List<EmergencyContact> emergencyContacts = <EmergencyContact>[];

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final profile = await _profileRepository.getProfile();

      setState(() {
        userProfile = profile;
        emergencyContacts = profile.emergencyContacts;
        fullNameController.text = profile.fullName;
        emailController.text = profile.email;
        phoneController.text = profile.phone;
      });
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '// ERROR: $message',
          style: AppTextStyles.logText.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating, // Floating but flat
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Utility-Core low radius
        elevation: 0,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();

    if (fullName.length < 2) {
      _showError('Аты-жөні кемінде 2 символ болуы керек');
      return;
    }

    if (phone.length < 7) {
      _showError('Телефон нөмірін дұрыс енгізіңіз');
      return;
    }

    setState(() {
      isSavingProfile = true;
    });

    try {
      final updated = await _profileRepository.updateProfile(
          fullName: fullName, phone: phone);
      setState(() {
        userProfile = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль сақталды')),
        );
      }
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final previous =
        Map<String, dynamic>.from(userProfile?.settings ?? <String, dynamic>{});
    final next = Map<String, dynamic>.from(previous)..[key] = value;

    setState(() {
      userProfile = UserProfile(
        id: userProfile?.id ?? '',
        fullName: userProfile?.fullName ?? fullNameController.text.trim(),
        email: userProfile?.email ?? emailController.text.trim(),
        phone: userProfile?.phone ?? phoneController.text.trim(),
        emergencyContacts: emergencyContacts,
        settings: next,
      );
    });

    try {
      final updated = await _profileRepository.updateProfile(settings: next);
      setState(() {
        userProfile = updated;
      });
    } catch (error) {
      setState(() {
        userProfile = UserProfile(
          id: userProfile?.id ?? '',
          fullName: userProfile?.fullName ?? fullNameController.text.trim(),
          email: userProfile?.email ?? emailController.text.trim(),
          phone: userProfile?.phone ?? phoneController.text.trim(),
          emergencyContacts: emergencyContacts,
          settings: previous,
        );
      });
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _addOrEditContact({EmergencyContact? source}) async {
    final nameController = TextEditingController(text: source?.name ?? '');
    final phoneController = TextEditingController(text: source?.phone ?? '');
    final relationController =
        TextEditingController(text: source?.relation ?? '');

    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(source == null ? 'Контакт қосу' : 'Контакт өзгерту'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Аты-жөні'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Телефон'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: relationController,
                  decoration: const InputDecoration(labelText: 'Қатынасы'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Бас тарту'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final relation = relationController.text.trim();

                if (name.length < 2 ||
                    phone.length < 7 ||
                    relation.length < 2) {
                  _showError('Контакт мәліметтерін толық енгізіңіз');
                  return;
                }

                Navigator.pop(
                  context,
                  EmergencyContact(
                    id: source?.id ?? '',
                    name: name,
                    phone: phone,
                    relation: relation,
                  ),
                );
              },
              child: const Text('Сақтау'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    relationController.dispose();

    if (result == null) {
      return;
    }

    try {
      if (source == null) {
        final contacts = await _profileRepository.addContact(result);
        setState(() {
          emergencyContacts = contacts;
        });
      } else {
        final contacts = await _profileRepository
            .updateContact(result.copyWith(id: source.id));
        setState(() {
          emergencyContacts = contacts;
        });
      }
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _removeContact(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Контактты жою'),
          content: Text('${contact.name} контактын жоюға сенімдісіз бе?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Жоқ')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Жою')),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final contacts = await _profileRepository.deleteContact(contact.id);
      setState(() {
        emergencyContacts = contacts;
      });
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    final confirmedPassword = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Аккаунтты жою'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Бұл әрекет қайтарылмайды. Растау үшін құпия сөзді енгізіңіз.'),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Құпия сөз'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Бас тарту'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, passwordController.text),
              child: const Text('Жою'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();

    if (confirmedPassword == null || confirmedPassword.isEmpty) {
      return;
    }

    try {
      await _profileRepository.deleteAccount(confirmedPassword);
      await _authRepository.logout();
      if (!mounted) {
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _logout() async {
    await _authRepository.logout();
    if (!mounted) {
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final settings = userProfile?.settings ?? <String, dynamic>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Баптаулар', style: AppTextStyles.title.copyWith(fontSize: 22)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text('ЖЕКЕ АҚПАРАТ', style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.textSecondary)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                   _buildSettingsTextField('Толық аты-жөні', 'John Smith', fullNameController),
                   const Divider(height: 1, indent: 16, color: AppColors.border),
                   _buildSettingsTextField('Email', 'john.smith@email.com', emailController, readOnly: true),
                   const Divider(height: 1, indent: 16, color: AppColors.border),
                   _buildSettingsTextField('Телефон нөмірі', '+1 (555) 123-4567', phoneController, isPhone: true),
                   const Divider(height: 1, indent: 16, color: AppColors.border),
                   GestureDetector(
                     onTap: isSavingProfile ? null : _saveProfile,
                     child: Container(
                       width: double.infinity,
                       padding: const EdgeInsets.symmetric(vertical: 14),
                       alignment: Alignment.center,
                       child: isSavingProfile
                           ? const CupertinoActivityIndicator()
                           : Text('Профильді сақтау', style: AppTextStyles.body.copyWith(color: AppColors.systemBlue, fontWeight: FontWeight.w600)),
                     ),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text('ТӨТЕНШЕ КОНТАКТІЛЕР', style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.textSecondary)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  if (emergencyContacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Ең кемі 1 сенімді контакт қосыңыз.', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    )
                  else
                    ...emergencyContacts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final contact = entry.value;
                      return Column(
                        children: [
                          _buildContactTile(contact),
                          if (index < emergencyContacts.length - 1)
                            const Divider(height: 1, indent: 16, color: AppColors.border),
                        ],
                      );
                    }),
                  if (emergencyContacts.isNotEmpty && emergencyContacts.length < 5)
                    const Divider(height: 1, indent: 16, color: AppColors.border),
                  if (emergencyContacts.length < 5)
                    GestureDetector(
                      onTap: () => _addOrEditContact(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.add_circled_solid, color: AppColors.systemGreen, size: 22),
                            const SizedBox(width: 12),
                            Text('Контакт қосу', style: AppTextStyles.body.copyWith(color: AppColors.systemBlue)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text('SOS кезінде хабарланатын контактілер', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text('SOS БАПТАУЛАРЫ', style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.textSecondary)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildCupertinoSwitchTile(
                    'SOS батырмасының дірілі',
                    settings['sosVibration'] == true,
                    (value) => _updateSetting('sosVibration', value),
                  ),
                  const Divider(height: 1, indent: 16, color: AppColors.border),
                  _buildCupertinoSwitchTile(
                    'Орынды автоматты бөлісу',
                    settings['autoLocation'] != false,
                    (value) => _updateSetting('autoLocation', value),
                  ),
                  const Divider(height: 1, indent: 16, color: AppColors.border),
                  _buildCupertinoSwitchTile(
                    'Төтенше хабарландырулар',
                    settings['emergencyNotif'] != false,
                    (value) => _updateSetting('emergencyNotif', value),
                  ),
                  const Divider(height: 1, indent: 16, color: AppColors.border),
                  _buildCupertinoSwitchTile(
                    'Дыбыстық сигнал',
                    settings['soundAlerts'] == true,
                    (value) => _updateSetting('soundAlerts', value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text('ҚАУІПСІЗДІК', style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.textSecondary)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(10),
              ),
              child: GestureDetector(
                onTap: _deleteAccount,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: Text('Аккаунтты жою', style: AppTextStyles.body.copyWith(color: AppColors.systemRed)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text('Аккаунтты жойғаннан кейін деректерді қалпына келтіру мүмкін емес.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != 4 && widget.onNavigateBack != null) {
            widget.onNavigateBack!(index);
          }
        },
      ),
    );
  }

  Widget _buildSettingsTextField(String label, String hint, TextEditingController controller, {bool readOnly = false, bool isPhone = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.body),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
              style: AppTextStyles.body.copyWith(color: readOnly ? AppColors.textSecondary : AppColors.systemBlue),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: AppTextStyles.body)),
          CupertinoSwitch(
            value: value,
            activeColor: AppColors.systemGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(EmergencyContact contact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _removeContact(contact),
            child: const Icon(CupertinoIcons.minus_circle_fill, color: AppColors.systemRed, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text('${contact.relation} • ${contact.phone}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _addOrEditContact(source: contact),
            child: const Icon(CupertinoIcons.pencil, color: AppColors.systemBlue, size: 20),
          ),
        ],
      ),
    );
  }
}
