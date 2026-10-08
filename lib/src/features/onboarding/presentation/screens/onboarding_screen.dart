import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/core/routing/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'KargomNerede\'ye Hoş Geldiniz',
      description: 'Tüm kargolarınızı tek uygulamadan takip edin. Türkiye\'deki ve yurtdışındaki onlarca kargo firmasını destekliyoruz.',
      icon: Icons.local_shipping_outlined,
      color: const Color(0xFF00B4D8),
    ),
    OnboardingPage(
      title: 'Otomatik Taşıyıcı Algılama',
      description: 'Sadece takip numarasını girin, hangi kargo firmasına ait olduğunu otomatik algılayalım. Manuel seçim de mümkün.',
      icon: Icons.auto_awesome_outlined,
      color: const Color(0xFF00ACC1),
    ),
    OnboardingPage(
      title: 'Anlık Bildirimler',
      description: 'Kargonuz dağıtıma çıktığında, teslim edildiğinde veya bir sorun olduğunda anında bildirim alın.',
      icon: Icons.notifications_active_outlined,
      color: const Color(0xFFFF9800),
    ),
    OnboardingPage(
      title: 'Detaylı Geçmiş ve Tahmin',
      description: 'Kargonuzun her adımını görüntüleyin. Tahmini teslim tarihini öğrenin. Geçmiş hareketleri zaman çizelgesi olarak inceleyin.',
      icon: Icons.timeline_outlined,
      color: const Color(0xFF4CAF50),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      await _pageController.nextPage(
        duration: AppConstants.pageTransitionDuration,
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingCompleted, true);
    // Invalidate onboarding provider so router sees updated value
    ref.invalidate(onboardingCompletedProvider);
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _skipOnboarding() async {
    await _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button at top right
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Atla'),
                ),
              ),
            ),
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPageWidget(page: page, isLast: index == _pages.length - 1);
                },
              ),
            ),
            // Bottom section with indicators and buttons
            _buildBottomSection(context, isLastPage),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: AppConstants.animationDuration,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? _pages[_currentPage].color
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Action buttons
          Row(
            children: [
              // Skip button (visible on non-last pages)
              if (!isLastPage) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skipOnboarding,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      ),
                      foregroundColor: Colors.white.withValues(alpha: 0.9),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Atla'),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              // Primary action button (İleri / Başla)
              Expanded(
                flex: isLastPage ? 2 : 1,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D1B2A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shadowColor: Colors.white.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  child: Text(
                    isLastPage ? 'Başla' : 'İleri',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  }

class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final bool isLast;

  const _OnboardingPageWidget({
    required this.page,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with gradient background
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  page.color.withValues(alpha: 0.15),
                  page.color.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: page.color.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(page.icon, size: 64, color: page.color),
          )
              .animate()
              .scale(duration: 700.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 500.ms),
          const SizedBox(height: 56),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ).paddingSymmetric(horizontal: 16).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.7,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ).paddingSymmetric(horizontal: 24).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}