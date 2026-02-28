import 'dart:async';

import 'package:flutter/material.dart';

import '../features/legal/data/legal_repository.dart';
import '../features/legal/domain/legal_topic.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/bottom_nav_bar.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, this.onNavigateBack});

  final Function(int)? onNavigateBack;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  final LegalRepository _legalRepository = LegalRepository();
  final TextEditingController _searchController = TextEditingController();

  int _currentIndex = 3;
  String _selectedCategory = 'Барлығы';
  List<String> _categories = <String>['Барлығы'];
  List<LegalTopic> _topics = <LegalTopic>[];

  bool _isLoading = true;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTopics();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadTopics(showLoader: false);
    });
  }

  Future<void> _loadTopics({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final feed = await _legalRepository.getTopics(
        category: _selectedCategory,
        query: _searchController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _categories =
            feed.categories.isEmpty ? <String>['Барлығы'] : feed.categories;
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = _categories.first;
        }
        _topics = feed.items;
        _errorMessage = null;
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
          if (index != 3 && widget.onNavigateBack != null) {
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
                  onPressed: _loadTopics, child: const Text('Қайта жүктеу')),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text('Заң кітапханасы', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text('Заң ақпаратын іздеңіз және құқықтарыңызды біліңіз',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText:
                      'Заң тақырыптарын, құқықтарды немесе рәсімдерді іздеу...',
                  hintStyle: AppTextStyles.caption,
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _loadTopics(showLoader: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.textPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${_topics.length} заң тақырыбы көрсетілуде',
                  style: AppTextStyles.caption),
            ),
          ),
          const SizedBox(height: 16),
          if (_topics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('Сұраныс бойынша материал табылмады',
                    style: AppTextStyles.caption),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLegalCard(topic),
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLegalCard(LegalTopic topic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconForCategory(topic.category),
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.title,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(topic.category,
                    style: AppTextStyles.caption.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(topic.description,
                    style: AppTextStyles.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Полиция':
        return Icons.policy_outlined;
      case 'Медициналық':
        return Icons.local_hospital_outlined;
      case 'Конституциялық құқықтар':
        return Icons.gavel_outlined;
      case 'Жеке қауіпсіздік':
        return Icons.security_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }
}
