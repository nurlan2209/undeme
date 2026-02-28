import 'package:flutter/material.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/domain/emergency_contact.dart';
import '../features/profile/domain/user_profile.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/emergency_contact_card.dart';
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
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Профиль және баптаулар'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildSection(
              icon: Icons.person,
              title: 'Жеке ақпарат',
              child: Column(
                children: [
                  CustomTextField(
                    label: 'Толық аты-жөні',
                    hintText: 'John Smith',
                    controller: fullNameController,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Email',
                    hintText: 'john.smith@email.com',
                    controller: emailController,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Телефон нөмірі',
                    hintText: '+1 (555) 123-4567',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSavingProfile ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      child: isSavingProfile
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Профильді сақтау'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              icon: Icons.shield,
              title: 'Төтенше контактілер',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOS кезінде хабарланатын контактілер',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 12),
                  if (emergencyContacts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Text(
                          'Контакттар жоқ. Ең кемі 1 сенімді контакт қосыңыз.',
                          style: AppTextStyles.caption),
                    )
                  else
                    ...emergencyContacts.map(
                      (contact) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: EmergencyContactCard(
                          name: contact.name,
                          phone: contact.phone,
                          relation: contact.relation,
                          onEdit: () => _addOrEditContact(source: contact),
                          onRemove: () => _removeContact(contact),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: emergencyContacts.length >= 5
                        ? null
                        : () => _addOrEditContact(),
                    icon: const Icon(Icons.add),
                    label: const Text('Контакт қосу'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              icon: Icons.settings,
              title: 'SOS баптаулары',
              child: Column(
                children: [
                  _buildSwitchTile(
                    'SOS батырмасының дірілі',
                    'Іске қосылғанда қысқа вибрация',
                    settings['sosVibration'] == true,
                    (value) => _updateSetting('sosVibration', value),
                  ),
                  _buildSwitchTile(
                    'Орынды автоматты бөлісу',
                    'SOS кезінде геолокация жіберу',
                    settings['autoLocation'] != false,
                    (value) => _updateSetting('autoLocation', value),
                  ),
                  _buildSwitchTile(
                    'Төтенше хабарландырулар',
                    'Маңызды қауіп ескертпелерін алу',
                    settings['emergencyNotif'] != false,
                    (value) => _updateSetting('emergencyNotif', value),
                  ),
                  _buildSwitchTile(
                    'Дыбыстық сигнал',
                    'SOS іске қосылғанда дыбыс',
                    settings['soundAlerts'] == true,
                    (value) => _updateSetting('soundAlerts', value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              icon: Icons.warning_amber_rounded,
              title: 'Қауіпсіздік',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Аккаунтты жойғаннан кейін деректерді қалпына келтіру мүмкін емес.',
                      style: AppTextStyles.caption),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _deleteAccount,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Аккаунтты жою'),
                  ),
                ],
              ),
            ),
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

  Widget _buildSection(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
