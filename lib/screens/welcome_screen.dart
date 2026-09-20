import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<WelcomeData> _pages = [
    WelcomeData(
      title: 'Welcome!',
      image: 'assets/images/welcome_drink.png',
      description: 'Discover our delicious milk tea\nand coffee creations.',
    ),
    WelcomeData(
      title: '',
      image: 'assets/images/welcome_customize.png',
      description: 'Personalize sweetness, ice, and\nadd-ons.',
    ),
    WelcomeData(
      title: '',
      image: 'assets/images/welcome_friends.png',
      description:
          'Share your favorites, find new\n'
          'recipes, and meet fellow coffee\n'
          'and milk tea lovers.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _getStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,

                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },

                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),

            _buildBottomNavigation(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(WelcomeData page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),

          if (page.title.isNotEmpty)
            Text(
              page.title,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),

          if (page.title.isNotEmpty) const SizedBox(height: 35),

          Expanded(
            flex: 5,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Image.asset(
                  page.image,
                  key: ValueKey(page.image),
                  width: index == 2 ? 270 : 220,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    if (_currentPage == _pages.length - 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _getStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text(
              'Get started',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          TextButton(
            onPressed: _skip,
            child: const Text(
              'skip',
              style: TextStyle(
                color: Color(0xFFD4D4D4),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? AppColors.orange
                      : const Color(0xFFE0E0E0),
                ),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 4,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'NEXT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeData {
  final String title;
  final String image;
  final String description;

  WelcomeData({
    required this.title,
    required this.image,
    required this.description,
  });
}
