import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/bottom_nav_bar.dart';

class LegalScreen extends StatefulWidget {
  final Function(int)? onNavigateBack;

  const LegalScreen({Key? key, this.onNavigateBack}) : super(key: key);

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  int _currentIndex = 3;
  String selectedCategory = 'Барлығы';

  final List<String> categories = [
    'Барлығы',
    'Полиция',
    'Конституциялық құқықтар',
    'Медициналық',
    'Жеке қауіпсіздік'
  ];

  final List<Map<String, dynamic>> legalTopics = [
    {
      'icon': Icons.shield_outlined,
      'title': 'Төтенше жағдайларда азаматтардың құқықтары',
      'category': 'Конституциялық құқықтар',
      'description': 'ҚР Конституциясы 15-бап'
    },
    {
      'icon': Icons.local_hospital_outlined,
      'title': 'Төтенше медициналық көмек',
      'category': 'Медициналық',
      'description': 'Денсаулық сақтау туралы заң 88-бап'
    },
    {
      'icon': Icons.warning_amber_outlined,
      'title': 'Қауіпті жағдайларда мемлекеттік қорғау',
      'category': 'Жеке қауіпсіздік',
      'description': 'ҚР Азаматтық кодексі 9-тарау'
    },
    {
      'icon': Icons.phone_in_talk_outlined,
      'title': 'Төтенше қызметтерге хабарлау міндеті',
      'category': 'Жеке қауіпсіздік',
      'description': 'ҚР ӘҚК 339-бап'
    },
    {
      'icon': Icons.location_on_outlined,
      'title': 'Жеке деректерді қорғау және орын ақпараты',
      'category': 'Конституциялық құқықтар',
      'description': 'Жеке деректер туралы заң 6-бап'
    },
    {
      'icon': Icons.security_outlined,
      'title': 'Отбасылық зорлық-зомбылықтан қорғау',
      'category': 'Жеке қауіпсіздік',
      'description': 'Отбасылық зорлық-зомбылық туралы заң'
    },
    {
      'icon': Icons.policy_outlined,
      'title': 'Полициямен өзара іс-қимыл',
      'category': 'Полиция',
      'description': 'Полиция қызметі туралы заң 5-бап'
    },
    {
      'icon': Icons.healing_outlined,
      'title': 'Медициналық құпияны сақтау',
      'category': 'Медициналық',
      'description': 'Денсаулық сақтау туралы заң 91-бап'
    },
    {
      'icon': Icons.gavel_outlined,
      'title': 'Азаматтық сот ісін жүргізу құқықтары',
      'category': 'Конституциялық құқықтар',
      'description': 'ҚР Конституциясы 13-бап'
    },
    {
      'icon': Icons.report_problem_outlined,
      'title': 'Табиғи апаттар кезіндегі іс-қимылдар',
      'category': 'Жеке қауіпсіздік',
      'description': 'Төтенше жағдайлар туралы заң'
    },
  ];

  List<Map<String, dynamic>> get filteredTopics {
    if (selectedCategory == 'Барлығы') {
      return legalTopics;
    }
    return legalTopics
        .where((topic) => topic['category'] == selectedCategory)
        .toList();
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('Төтенше жағдайлар қауіпсіздігі',
                style: AppTextStyles.caption),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText:
                        'Заң тақырыптарын, құқықтарды немесе рәсімдерді іздеу...',
                    hintStyle: AppTextStyles.caption,
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
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
                children: categories.map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
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
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
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
                child: Text(
                  '${filteredTopics.length} заң тақырыбы көрсетілуде',
                  style: AppTextStyles.caption,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: filteredTopics.length,
              itemBuilder: (context, index) {
                final topic = filteredTopics[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLegalCard(
                    icon: topic['icon'],
                    title: topic['title'],
                    category: topic['category'],
                    description: topic['description'],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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

  Widget _buildLegalCard({
    required IconData icon,
    required String title,
    required String category,
    required String description,
  }) {
    return InkWell(
      onTap: () {
        // Navigate to detail screen
      },
      child: Container(
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(category,
                      style: AppTextStyles.caption.copyWith(fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: AppTextStyles.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
