import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'stalls_screen.dart';
import 'my_orders_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  static const Color primaryOrange = Color(0xFFE69A2D);
  static const Color darkNavy = Color(0xFF17324D);
  static const Color background = Color(0xFFF7F8FA);

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = const [
      HomeContent(),
      StallsScreen(),
      MyOrdersScreen(),
    ];
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void onBottomNavigationTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),

        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: selectedIndex,

            onTap: onBottomNavigationTapped,

            type: BottomNavigationBarType.fixed,

            backgroundColor: Colors.white,

            elevation: 0,

            selectedItemColor: primaryOrange,

            unselectedItemColor: const Color(0xFF8A8F98),

            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),

            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),

            items: const [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home_outlined,
                ),
                activeIcon: Icon(
                  Icons.home_rounded,
                ),
                label: 'Home',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.storefront_outlined,
                ),
                activeIcon: Icon(
                  Icons.storefront_rounded,
                ),
                label: 'Stalls',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.receipt_long_outlined,
                ),
                activeIcon: Icon(
                  Icons.receipt_long_rounded,
                ),
                label: 'My Orders',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// HOME CONTENT
// ==================================================================

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  static const Color primaryOrange = Color(0xFFE69A2D);
  static const Color darkNavy = Color(0xFF17324D);
  static const Color background = Color(0xFFF7F8FA);

  // ================================================================
  // GET STUDENT NAME
  // ================================================================

  String getStudentName() {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.displayName != null &&
        user!.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }

    if (user?.email != null &&
        user!.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }

    return 'Student';
  }

  // ================================================================
  // OPEN STALLS
  // ================================================================

  void openStalls(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StallsScreen(),
      ),
    );
  }

  // ================================================================
  // OPEN ORDERS
  // ================================================================

  void openOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyOrdersScreen(),
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final studentName = getStudentName();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          30,
        ),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // ==================================================
                // TOP HEADER
                // ==================================================

                Row(
                  children: [

                    // LOGO
                    Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(15),

                        boxShadow: [
                          BoxShadow(
                            color:
                                primaryOrange.withOpacity(0.18),
                            blurRadius: 12,
                            offset:
                                const Offset(0, 5),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(15),

                        child: Image.asset(
                          'assets/images/campus_bite_logo.png',
                          fit: BoxFit.cover,

                          errorBuilder:
                              (context, error, stackTrace) {
                            return Container(
                              color: primaryOrange,
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 13),

                    // BRAND NAME
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            'CampusBite',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w800,
                              color: darkNavy,
                            ),
                          ),

                          SizedBox(height: 2),

                          Text(
                            'Campus Food Ordering',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  Color(0xFF858B94),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // PROFILE
                    PopupMenuButton<String>(
                      tooltip: 'Profile',

                      onSelected: (value) async {
                        if (value == 'orders') {
                          openOrders(context);
                        }

                        if (value == 'logout') {
                          await logoutUser(context);
                        }
                      },

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),

                      itemBuilder: (context) => const [

                        PopupMenuItem(
                          value: 'orders',

                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: darkNavy,
                              ),

                              SizedBox(width: 10),

                              Text('My Orders'),
                            ],
                          ),
                        ),

                        PopupMenuItem(
                          value: 'logout',

                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.red,
                              ),

                              SizedBox(width: 10),

                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],

                      child: Container(
                        width: 48,
                        height: 48,

                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,

                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset:
                                  const Offset(0, 4),
                            ),
                          ],
                        ),

                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: darkNavy,
                          size: 23,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ==================================================
                // GREETING
                // ==================================================

                Text(
                  'Hello, $studentName 👋',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'What would you like to eat today?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF707780),
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // SEARCH
                // ==================================================

                GestureDetector(
                  onTap: () {
                    openStalls(context);
                  },

                  child: Container(
                    height: 55,

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(16),

                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(0.035),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: const Row(
                      children: [

                        SizedBox(width: 17),

                        Icon(
                          Icons.search_rounded,
                          color: Color(0xFF7B828B),
                        ),

                        SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            'Search food or campus stalls',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9298A0),
                            ),
                          ),
                        ),

                        Icon(
                          Icons.tune_rounded,
                          color: primaryOrange,
                          size: 20,
                        ),

                        SizedBox(width: 17),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // EXPLORE STALLS HERO CARD
                // ==================================================

                GestureDetector(
                  onTap: () {
                    openStalls(context);
                  },

                  child: Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          primaryOrange,
                          Color(0xFFF0B34F),
                        ],

                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

                      borderRadius:
                          BorderRadius.circular(24),

                      boxShadow: [
                        BoxShadow(
                          color:
                              primaryOrange.withOpacity(0.24),
                          blurRadius: 20,
                          offset:
                              const Offset(0, 9),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [

                        Container(
                          width: 68,
                          height: 68,

                          decoration: BoxDecoration(
                            color:
                                Colors.white.withOpacity(0.20),
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),

                        const SizedBox(width: 17),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Text(
                                'Explore Campus Stalls',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),

                              SizedBox(height: 5),

                              Text(
                                'Choose any stall and order your favourite food.',
                                style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),

                              SizedBox(height: 10),

                              Text(
                                'BROWSE STALLS  →',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // SECTION TITLE
                // ==================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [

                    const Text(
                      'Campus Food',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: darkNavy,
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        openStalls(context);
                      },

                      style: TextButton.styleFrom(
                        foregroundColor:
                            primaryOrange,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                      ),

                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ==================================================
                // STALL PREVIEW CARDS
                // ==================================================

                LayoutBuilder(
                  builder: (context, constraints) {

                    final bool isWide =
                        constraints.maxWidth >= 650;

                    if (isWide) {
                      return Row(
                        children: [

                          Expanded(
                            child: _stallPreviewCard(
                              context,
                              icon:
                                  Icons.restaurant_rounded,
                              title:
                                  'Food Stalls',
                              subtitle:
                                  'Fresh & tasty',
                              color:
                                  primaryOrange,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: _stallPreviewCard(
                              context,
                              icon:
                                  Icons.local_cafe_rounded,
                              title:
                                  'Cafe & Snacks',
                              subtitle:
                                  'Quick bites',
                              color:
                                  darkNavy,
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [

                        Expanded(
                          child: _stallPreviewCard(
                            context,
                            icon:
                                Icons.restaurant_rounded,
                            title:
                                'Food Stalls',
                            subtitle:
                                'Fresh & tasty',
                            color:
                                primaryOrange,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _stallPreviewCard(
                            context,
                            icon:
                                Icons.local_cafe_rounded,
                            title:
                                'Cafe & Snacks',
                            subtitle:
                                'Quick bites',
                            color:
                                darkNavy,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),

                // ==================================================
                // QUICK ACCESS
                // ==================================================

                const Text(
                  'Quick Access',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [

                    Expanded(
                      child: _quickCard(
                        icon:
                            Icons.receipt_long_rounded,
                        title:
                            'My Orders',
                        subtitle:
                            'Track orders',
                        color:
                            primaryOrange,
                        onTap: () {
                          openOrders(context);
                        },
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: _quickCard(
                        icon:
                            Icons.storefront_rounded,
                        title:
                            'Order Food',
                        subtitle:
                            'Choose a stall',
                        color:
                            darkNavy,
                        onTap: () {
                          openStalls(context);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ==================================================
                // HOW IT WORKS
                // ==================================================

                const Text(
                  'How CampusBite Works',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),

                const SizedBox(height: 14),

                _stepCard(
                  number: '1',
                  icon:
                      Icons.storefront_rounded,
                  title:
                      'Choose a Stall',
                  description:
                      'Browse all food stalls available on campus.',
                ),

                const SizedBox(height: 10),

                _stepCard(
                  number: '2',
                  icon:
                      Icons.restaurant_menu_rounded,
                  title:
                      'Select Your Food',
                  description:
                      'Open a stall and choose the food you want.',
                ),

                const SizedBox(height: 10),

                _stepCard(
                  number: '3',
                  icon:
                      Icons.shopping_cart_rounded,
                  title:
                      'Place Your Order',
                  description:
                      'Add items to your cart and place the order.',
                ),

                const SizedBox(height: 10),

                _stepCard(
                  number: '4',
                  icon:
                      Icons.notifications_active_rounded,
                  title:
                      'Collect When Ready',
                  description:
                      'Get notified when your food is ready and collect it from the stall.',
                ),

                const SizedBox(height: 25),

                // ==================================================
                // FOOTER INFO
                // ==================================================

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(18),

                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),

                  child: const Row(
                    children: [

                      Icon(
                        Icons.access_time_rounded,
                        color: primaryOrange,
                        size: 23,
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Skip the queue by ordering before the rush.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            fontWeight:
                                FontWeight.w600,
                            color: darkNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // STALL PREVIEW CARD
  // ==============================================================

  Widget _stallPreviewCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        openStalls(context);
      },

      child: Container(
        padding: const EdgeInsets.all(17),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color: Colors.grey.shade200,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.035),
              blurRadius: 10,
              offset:
                  const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [

            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                color:
                    color.withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(14),
              ),

              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                      color: darkNavy,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color:
                          Color(0xFF858B94),
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // QUICK CARD
  // ==============================================================

  Widget _quickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Container(
              width: 46,
              height: 46,

              decoration: BoxDecoration(
                color:
                    color.withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(13),
              ),

              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
                color: darkNavy,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color:
                    Color(0xFF858B94),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // STEP CARD
  // ==============================================================

  Widget _stepCard({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [

          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color:
                  primaryOrange.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(13),
            ),

            child: Stack(
              alignment:
                  Alignment.center,

              children: [

                Icon(
                  icon,
                  color: primaryOrange,
                  size: 23,
                ),

                Positioned(
                  right: 1,
                  top: 0,

                  child: Container(
                    width: 17,
                    height: 17,

                    decoration:
                        const BoxDecoration(
                      color: darkNavy,
                      shape: BoxShape.circle,
                    ),

                    child: Center(
                      child: Text(
                        number,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                    color: darkNavy,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color:
                        Color(0xFF737981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// LOGOUT
// ==================================================================

Future<void> logoutUser(BuildContext context) async {
  await FirebaseAuth.instance.signOut();

  if (!context.mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => const LoginScreen(),
    ),
    (route) => false,
  );
}