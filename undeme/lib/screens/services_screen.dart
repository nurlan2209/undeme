import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            const Icon(CupertinoIcons.shield_fill, color: AppColors.systemRed, size: 28),
            const SizedBox(width: 8),
            Text('Undeme', style: AppTextStyles.title.copyWith(fontSize: 22)),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Қызметтер', style: AppTextStyles.largeTitle),
          ),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Text('ТӨТЕНШЕ НӨМІРЛЕР', style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _services.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 0.5,
                indent: 60,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                return _buildEmergencyButton(_services[index], index);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
            child: Text(
              _note.isEmpty
                  ? 'Төтенше жағдай кезінде 112 нөміріне қоңырау шалыңыз.'
                  : _note,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(EmergencyService service, int index) {
    return InkWell(
      onTap: () => _makePhoneCall(service.number),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(service.emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                service.label,
                style: AppTextStyles.body,
              ),
            ),
            Text(
              service.number,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.phone, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
