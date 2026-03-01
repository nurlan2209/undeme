import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Заң кітапханасы', style: AppTextStyles.largeTitle),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Азаматтық құқықтарыңыз бен міндеттеріңіз жайлы оқыңыз',
                style: AppTextStyles.subtitle),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(10), // Native iOS Search Field
              ),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Тақырыпты немесе заңды іздеу',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.systemGray, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _loadTopics(showLoader: false);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.textPrimary : AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.pureWhite : AppColors.textPrimary,
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text('Сұраныс бойынша материал табылмады',
                      style: AppTextStyles.caption),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg, // White
        borderRadius: BorderRadius.circular(24), // Squircle
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // highly diffused, faint
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconForCategory(topic.category), color: AppColors.systemBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                topic.category.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.systemBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            topic.title,
            style: AppTextStyles.title.copyWith(fontSize: 22, height: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            topic.description,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Полиция':
        return CupertinoIcons.shield_fill;
      case 'Медициналық':
        return CupertinoIcons.bandage_fill;
      case 'Конституциялық құқықтар':
        return CupertinoIcons.book_fill;
      case 'Жеке қауіпсіздік':
        return CupertinoIcons.lock_fill;
      default:
        return CupertinoIcons.news_solid;
    }
  }
}
