import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'login_screen.dart';
import 'staff_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CampusBiteApp());
}

class CampusBiteApp extends StatelessWidget {
  const CampusBiteApp({super.key});

  static const Color primaryOrange = Color(0xFFE69A2D);
  static const Color darkNavy = Color(0xFF17324D);
  static const Color background = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusBite',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryOrange,
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: background,

        fontFamily: 'Arial',

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: darkNavy,
          elevation: 0,
          centerTitle: false,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: primaryOrange,
              width: 1.5,
            ),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),

      home: const RoleSelectionScreen(),
    );
  }
}


// ============================================================
// ROLE SELECTION SCREEN
// ============================================================

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const Color primaryOrange = Color(0xFFE69A2D);
  static const Color darkNavy = Color(0xFF17324D);

  void openStudentLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  void openStaffLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StaffLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 30,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1000,
              ),

              child: Column(
                children: [

                  // ==================================================
                  // LOGO
                  // ==================================================

                  Container(
                    width: 145,
                    height: 145,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),

                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withOpacity(0.20),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),

                      child: Image.asset(
                        'assets/images/campus_bite.jpeg',
                        fit: BoxFit.cover,

                        errorBuilder:
                            (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: primaryOrange,
                              borderRadius:
                                  BorderRadius.circular(32),
                            ),

                            child: const Icon(
                              Icons.storefront,
                              color: Colors.white,
                              size: 65,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // APP NAME
                  // ==================================================

                  const Text(
                    'CampusBite',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: darkNavy,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Campus Food Ordering',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Skip the queue. Order from your favourite campus stall.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8A8F98),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ==================================================
                  // SELECT ROLE
                  // ==================================================

                  const Text(
                    'Welcome to CampusBite',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: darkNavy,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Choose how you want to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF737981),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // ROLE CARDS
                  // ==================================================

                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 700) {
                        return Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Expanded(
                              child: RoleCard(
                                title: 'Student',
                                subtitle:
                                    'Order food from any campus stall and track your order.',

                                roleLabel:
                                    'STUDENT PORTAL',

                                roleIcon:
                                    Icons.school_rounded,

                                accentColor:
                                    primaryOrange,

                                features: const [
                                  'Browse all campus stalls',
                                  'Order food in advance',
                                  'Track your order status',
                                ],

                                onPressed: () =>
                                    openStudentLogin(context),
                              ),
                            ),

                            const SizedBox(width: 22),

                            Expanded(
                              child: RoleCard(
                                title: 'Staff',
                                subtitle:
                                    'Manage your stall menu and handle student orders.',

                                roleLabel:
                                    'STAFF PORTAL',

                                roleIcon:
                                    Icons.restaurant_rounded,

                                accentColor:
                                    darkNavy,

                                features: const [
                                  'Manage your stall menu',
                                  'View student orders',
                                  'Update order status',
                                ],

                                onPressed: () =>
                                    openStaffLogin(context),
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [

                          RoleCard(
                            title: 'Student',
                            subtitle:
                                'Order food from any campus stall and track your order.',

                            roleLabel:
                                'STUDENT PORTAL',

                            roleIcon:
                                Icons.school_rounded,

                            accentColor:
                                primaryOrange,

                            features: const [
                              'Browse all campus stalls',
                              'Order food in advance',
                              'Track your order status',
                            ],

                            onPressed: () =>
                                openStudentLogin(context),
                          ),

                          const SizedBox(height: 18),

                          RoleCard(
                            title: 'Staff',
                            subtitle:
                                'Manage your stall menu and handle student orders.',

                            roleLabel:
                                'STAFF PORTAL',

                            roleIcon:
                                Icons.restaurant_rounded,

                            accentColor:
                                darkNavy,

                            features: const [
                              'Manage your stall menu',
                              'View student orders',
                              'Update order status',
                            ],

                            onPressed: () =>
                                openStaffLogin(context),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 35),

                  // ==================================================
                  // FOOTER
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [

                      Icon(
                        Icons.storefront_rounded,
                        size: 17,
                        color: Colors.grey.shade500,
                      ),

                      const SizedBox(width: 7),

                      Text(
                        'Smart food ordering for your campus',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================
// ROLE CARD
// ============================================================

class RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String roleLabel;
  final IconData roleIcon;
  final Color accentColor;
  final List<String> features;
  final VoidCallback onPressed;

  const RoleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.roleLabel,
    required this.roleIcon,
    required this.accentColor,
    required this.features,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: accentColor.withOpacity(0.10),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // ==================================================
          // ROLE ICON + LABEL
          // ==================================================

          Row(
            children: [

              Container(
                width: 62,
                height: 62,

                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(18),
                ),

                child: Icon(
                  roleIcon,
                  size: 32,
                  color: accentColor,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: accentColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17202A),
                      ),
                    ),
                  ],
                ),
              ),
            ],

          ),

          const SizedBox(height: 18),

          // ==================================================
          // DESCRIPTION
          // ==================================================

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 18),

          // ==================================================
          // FEATURES
          // ==================================================

          ...features.map(
            (feature) => Padding(
              padding:
                  const EdgeInsets.only(bottom: 9),

              child: Row(
                children: [

                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: accentColor,
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // LOGIN BUTTON
          // ==================================================

          SizedBox(
            width: double.infinity,
            height: 52,

            child: ElevatedButton(
              onPressed: onPressed,

              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  Text(
                    'CONTINUE AS $title',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}