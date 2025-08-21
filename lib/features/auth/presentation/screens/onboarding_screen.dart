import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/design_system/widgets/ceylon_button.dart';
import 'package:ceylon/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data class for onboarding page content
class OnboardingPageData {
  final String title;
  final String description;
  final String? imagePath;
  final IconData imageIcon;
  final Color imageColor;

  OnboardingPageData({
    required this.title,
    required this.description,
    this.imagePath,
    required this.imageIcon,
    required this.imageColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> pages = [
    OnboardingPageData(
      title: 'Discover Sri Lanka',
      description:
          'Explore attractions, cuisine, and culture in one app. Find hidden gems and must-visit places.',
      imagePath: 'assets/images/onboarding/discover.svg',
      imageColor: Colors.blueAccent,
      imageIcon: Icons.travel_explore,
    ),
    OnboardingPageData(
      title: 'Plan Your Trip',
      description:
          'Create personalized itineraries, bookmark favorite places, and navigate with ease.',
      imagePath: 'assets/images/onboarding/plan.svg',
      imageColor: Colors.orangeAccent,
      imageIcon: Icons.map,
    ),
    OnboardingPageData(
      title: 'Travel Smart',
      description:
          'Stay informed with weather alerts, cultural tips, and smart recommendations tailored to you.',
      imagePath: 'assets/images/onboarding/smart.svg',
      imageColor: Colors.greenAccent,
      imageIcon: Icons.lightbulb,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button at the top with cleaner styling
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(CeylonTokens.spacing16),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          CeylonTokens.radiusMedium,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: CeylonTokens.spacing16,
                        vertical: CeylonTokens.spacing8,
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    // Add a subtle animation when changing pages
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 350),
                      opacity: _currentPage == index ? 1.0 : 0.8,
                      child: _buildOnboardingPage(page, colorScheme),
                    );
                  },
                ),
              ),

              // Bottom navigation
              Padding(
                padding: const EdgeInsets.all(CeylonTokens.spacing24),
                child: Column(
                  children: [
                    // Page indicators with a more refined look
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CeylonTokens.spacing12,
                        vertical: CeylonTokens.spacing8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(
                          CeylonTokens.radiusMedium,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (index) => _buildPageIndicator(index, colorScheme),
                        ),
                      ),
                    ),

                    const SizedBox(height: CeylonTokens.spacing24),

                    // Next/Get Started button with enhanced appearance
                    CeylonButton.primary(
                          onPressed: _nextPage,
                          label: _currentPage == pages.length - 1
                              ? "Get Started"
                              : "Continue",
                          isFullWidth: true,
                          trailingIcon: _currentPage == pages.length - 1
                              ? Icons.login
                              : Icons.arrow_forward,
                          backgroundColor: pages[_currentPage].imageColor,
                        )
                        .animate()
                        .fadeIn()
                        .scale(
                          delay: 200.ms,
                          duration: 300.ms,
                          curve: Curves.easeOutQuad,
                        )
                        .then(delay: 300.ms)
                        .shimmer(duration: 1500.ms, delay: 800.ms),

                    // Add a subtle "swipe" hint text
                    if (_currentPage < pages.length - 1) ...[
                      const SizedBox(height: CeylonTokens.spacing16),
                      Text(
                        "Swipe to explore",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ).animate(delay: 1000.ms).fadeIn(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(
    OnboardingPageData page,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CeylonTokens.spacing24,
        vertical: CeylonTokens.spacing16,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image or icon placeholder with a fancier container
          Container(
                width: 280,
                height: 280,
                margin: const EdgeInsets.only(bottom: CeylonTokens.spacing32),
                decoration: BoxDecoration(
                  color: page.imageColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(CeylonTokens.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: page.imageColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    padding: const EdgeInsets.all(CeylonTokens.spacing16),
                    child: page.imagePath != null
                        ? SvgPicture.asset(page.imagePath!, fit: BoxFit.contain)
                        : Icon(
                            page.imageIcon,
                            size: 100,
                            color: page.imageColor,
                          ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                curve: Curves.easeOutQuad,
                duration: 600.ms,
              )
              .then()
              .shimmer(duration: 2000.ms, delay: 800.ms, angle: 0.2),

          // Title with a more distinctive style
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CeylonTokens.spacing16,
                  vertical: CeylonTokens.spacing8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      page.imageColor.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    CeylonTokens.radiusMedium,
                  ),
                ),
                child: Text(
                  page.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              .animate(delay: 200.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: CeylonTokens.spacing16),

          // Description
          Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CeylonTokens.spacing16,
                ),
                child: Text(
                  page.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              .animate(delay: 300.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index, ColorScheme colorScheme) {
    final bool isActive = _currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? pages[index].imageColor
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: pages[index].imageColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
