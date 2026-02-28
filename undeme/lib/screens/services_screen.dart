import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/services/data/services_repository.dart';
import '../features/services/domain/emergency_service.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/bottom_nav_bar.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, this.onNavigateBack});

  final Function(int)? onNavigateBack;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ServicesRepository _servicesRepository = ServicesRepository();

  int _currentIndex = 1;
  bool _isLoading = true;
  String? _errorMessage;

  List<EmergencyService> _services = <EmergencyService>[];
  String _note = '';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final feed = await _servicesRepository.getEmergencyServices();
      if (!mounted) {
        return;
      }
      setState(() {
        _services = feed.items;
        _note = feed.note;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child:
                  const Icon(Icons.shield, color: AppColors.primary, size: 24),
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
            child: Text('Төтенше жағдайлар қауіпсіздігі',
                style: AppTextStyles.caption),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != 1 && widget.onNavigateBack != null) {
            widget.onNavigateBack!(index);
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!,
                  style: AppTextStyles.body, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _loadServices, child: const Text('Қайта жүктеу')),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text('Төтенше қызметтер', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text('Төтенше жағдайда төмендегі нөмірлерге қоңырау шалыңыз',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 48),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Text('🚨', style: TextStyle(fontSize: 100)),
                const SizedBox(height: 24),
                Text('Төтенше көмек қажет пе?',
                    style: AppTextStyles.title.copyWith(fontSize: 22)),
                const SizedBox(height: 12),
                Text(
                  'Төмендегі қызметтерге қоңырау шалыңыз',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ..._services.map((service) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildEmergencyButton(service),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _note.isEmpty
                        ? 'Төтенше жағдай кезінде 112 нөміріне қоңырау шалыңыз.'
                        : _note,
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(EmergencyService service) {
    return InkWell(
      onTap: () => _makePhoneCall(service.number),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(service.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.number,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.phone, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }
}
