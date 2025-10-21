import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/emergency_contact_card.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigateBack;

  const ProfileScreen({Key? key, this.onNavigateBack}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 4;
  bool sosVibration = true;
  bool autoLocation = true;
  bool emergencyNotif = true;
  bool soundAlerts = false;
  bool isLoading = true;

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> emergencyContacts = [];

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
    final result = await ApiService.getProfile();

    if (result['success']) {
      setState(() {
        userData = result['data'];
        fullNameController.text = userData?['fullName'] ?? '';
        emailController.text = userData?['email'] ?? '';
        phoneController.text = userData?['phone'] ?? '';
        emergencyContacts = List<Map<String, dynamic>>.from(
            userData?['emergencyContacts'] ?? []);

        final settings = userData?['settings'];
        if (settings != null) {
          sosVibration = settings['sosVibration'] ?? true;
          autoLocation = settings['autoLocation'] ?? true;
          emergencyNotif = settings['emergencyNotif'] ?? true;
          soundAlerts = settings['soundAlerts'] ?? false;
        }

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      _showError(result['message']);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }

  Future<void> _updateSettings(String key, bool value) async {
    setState(() {
      if (key == 'sosVibration') sosVibration = value;
      if (key == 'autoLocation') autoLocation = value;
      if (key == 'emergencyNotif') emergencyNotif = value;
      if (key == 'soundAlerts') soundAlerts = value;
    });

    await ApiService.updateProfile(
      settings: {
        'sosVibration': sosVibration,
        'autoLocation': autoLocation,
        'emergencyNotif': emergencyNotif,
        'soundAlerts': soundAlerts,
      },
    );
  }

  Future<void> _logout() async {
    await ApiService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.shield, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Undeme',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text('Профиль және баптаулар', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text('Ақпаратыңызды және төтенше байланыс контактілерін басқарыңыз',
                style: AppTextStyles.subtitle),
            const SizedBox(height: 32),
            _buildSection(
              icon: Icons.person,
              title: 'Жеке ақпарат',
              child: Column(
                children: [
                  CustomTextField(
                      label: 'Толық аты-жөні',
                      hintText: 'John Smith',
                      controller: fullNameController),
                  const SizedBox(height: 16),
                  CustomTextField(
                      label: 'Email',
                      hintText: 'john.smith@email.com',
                      controller: emailController),
                  const SizedBox(height: 16),
                  CustomTextField(
                      label: 'Телефон нөмірі',
                      hintText: '+1 (555) 123-4567',
                      controller: phoneController),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              icon: Icons.shield,
              title: 'Төтенше байланыс контактілері',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'SOS іске қосылғанда хабарландырылатын 3 сенімді контакт қосыңыз',
                      style: AppTextStyles.caption),
                  const SizedBox(height: 16),
                  ...emergencyContacts
                      .map((contact) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: EmergencyContactCard(
                              name: contact['name'] ?? '',
                              phone: contact['phone'] ?? '',
                              relation: contact['relation'] ?? '',
                              onEdit: () {},
                              onRemove: () {},
                            ),
                          ))
                      .toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              icon: Icons.settings,
              title: 'Қосымша баптаулары',
              child: Column(
                children: [
                  _buildSwitchTile('SOS батырмасының дірілі',
                      'SOS іске қосылғанда дірілдету', sosVibration, (val) {
                    _updateSettings('sosVibration', val);
                  }),
                  _buildSwitchTile(
                      'Орынды автоматты бөлісу',
                      'SOS кезінде орынды автоматты бөлісу',
                      autoLocation, (val) {
                    _updateSettings('autoLocation', val);
                  }),
                  _buildSwitchTile(
                      'Төтенше хабарландырулар',
                      'Жақын маңдағы төтенше жағдайлар туралы хабарландыру',
                      emergencyNotif, (val) {
                    _updateSettings('emergencyNotif', val);
                  }),
                  _buildSwitchTile('Дыбыстық хабарландырулар',
                      'SOS іске қосылғанда дыбыс шығару', soundAlerts, (val) {
                    _updateSettings('soundAlerts', val);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              icon: Icons.lock,
              title: 'Құпиялық және қауіпсіздік',
              child: Column(
                children: [
                  _buildPrivacyItem('🔒',
                      'Сіздің орныңыз тек SOS іске қосылғанда ғана бөлісіледі'),
                  const SizedBox(height: 12),
                  _buildPrivacyItem('📱',
                      'Төтенше байланыс контактілері құрылғыңызда қауіпсіз сақталады'),
                  const SizedBox(height: 12),
                  _buildPrivacyItem('🚫',
                      'Біз сіздің жеке ақпаратыңызды үшінші тараптармен бөліспейміз'),
                  const SizedBox(height: 12),
                  _buildPrivacyItem(
                      '🗑️', 'Деректеріңізді кез келген уақытта жоя аласыз'),
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
      String title, String subtitle, bool value, Function(bool) onChanged) {
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
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ],
    );
  }
}
