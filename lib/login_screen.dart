import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  static const Color primaryOrange = Color(0xFFE69A2D);
  static const Color darkNavy = Color(0xFF17324D);
  static const Color background = Color(0xFFF7F8FA);
  static const Color textGrey = Color(0xFF6B7280);

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // ---------------------------------------------------------
    // VALIDATION
    // ---------------------------------------------------------

    if (email.isEmpty || password.isEmpty) {
      showMessage("Please enter email and password");
      return;
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email)) {
      showMessage("Please enter a valid email");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // =======================================================
      // FIREBASE LOGIN
      // =======================================================

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user == null) {
        showMessage("Login failed");
        return;
      }

      if (!mounted) return;

      showMessage("Login successful!");

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      // =======================================================
      // GO TO HOME
      // =======================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (route) => false,
      );
    }

    // =========================================================
    // FIREBASE AUTH ERROR
    // =========================================================

    on FirebaseAuthException catch (e) {
      String message = "Login failed";

      if (e.code == "invalid-credential") {
        message = "Invalid email or password";
      } else if (e.code == "user-not-found") {
        message = "No account found with this email";
      } else if (e.code == "wrong-password") {
        message = "Incorrect password";
      } else if (e.code == "invalid-email") {
        message = "Please enter a valid email";
      } else if (e.code == "user-disabled") {
        message = "This account has been disabled";
      } else if (e.code == "too-many-requests") {
        message = "Too many login attempts. Please try again later";
      } else if (e.code == "network-request-failed") {
        message = "Network error. Please check your internet connection";
      } else {
        message = "Firebase error: ${e.message ?? e.code}";
      }

      if (mounted) {
        showMessage(message);
      }
    }

    // =========================================================
    // OTHER ERROR
    // =========================================================

    catch (e) {
      if (mounted) {
        showMessage(
          "Something went wrong. Please try again.",
        );
      }
    }

    // =========================================================
    // STOP LOADING
    // =========================================================

    finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // FORGOT PASSWORD
  // =========================================================

  Future<void> forgotPassword() async {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage("Please enter your email first");
      return;
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email)) {
      showMessage("Please enter a valid email");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      showMessage(
        "Password reset email sent. Check your inbox.",
      );
    }

    on FirebaseAuthException catch (e) {
      String message = "Unable to send password reset email";

      if (e.code == "user-not-found") {
        message = "No account found with this email";
      } else if (e.code == "invalid-email") {
        message = "Please enter a valid email";
      } else if (e.code == "network-request-failed") {
        message = "Please check your internet connection";
      }

      if (mounted) {
        showMessage(message);
      }
    }

    catch (e) {
      if (mounted) {
        showMessage(
          "Something went wrong. Please try again.",
        );
      }
    }
  }

  // =========================================================
  // SHOW MESSAGE
  // =========================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: darkNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 28,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),

              child: Column(
                children: [

                  // ==================================================
                  // BACK BUTTON
                  // ==================================================

                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: darkNavy,
                      ),
                      tooltip: "Back",
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // LOGO
                  // ==================================================

                  Container(
                    width: 125,
                    height: 125,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),

                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withOpacity(0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),

                      child: Image.asset(
                        'assets/images/campus_bite.jpeg',
                        fit: BoxFit.cover,

                        errorBuilder:
                            (context, error, stackTrace) {
                          return Container(
                            color: primaryOrange,
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 58,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  const Text(
                    "Student Login",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: darkNavy,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    "Welcome back to CampusBite",
                    style: TextStyle(
                      fontSize: 15,
                      color: textGrey,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Order from your favourite campus stalls.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8A8F98),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // LOGIN CARD
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(24),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(24),

                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(
                          "Login to your account",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: darkNavy,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          "Enter your registered email and password.",
                          style: TextStyle(
                            fontSize: 13,
                            color: textGrey,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // ==================================================
                        // EMAIL
                        // ==================================================

                        const Text(
                          "Email Address",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkNavy,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: emailController,
                          keyboardType:
                              TextInputType.emailAddress,

                          textInputAction:
                              TextInputAction.next,

                          decoration: InputDecoration(
                            hintText: "Enter your email",

                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: textGrey,
                            ),

                            filled: true,
                            fillColor:
                                const Color(0xFFF8F9FA),

                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),

                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),

                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),

                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(
                                color: primaryOrange,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // PASSWORD
                        // ==================================================

                        const Text(
                          "Password",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkNavy,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: passwordController,

                          obscureText: hidePassword,

                          textInputAction:
                              TextInputAction.done,

                          onSubmitted: (_) {
                            if (!isLoading) {
                              login();
                            }
                          },

                          decoration: InputDecoration(
                            hintText: "Enter your password",

                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: textGrey,
                            ),

                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  hidePassword =
                                      !hidePassword;
                                });
                              },

                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: textGrey,
                              ),
                            ),

                            filled: true,
                            fillColor:
                                const Color(0xFFF8F9FA),

                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),

                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),

                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),

                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(
                                color: primaryOrange,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        // ==================================================
                        // FORGOT PASSWORD
                        // ==================================================

                        Align(
                          alignment: Alignment.centerRight,

                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : forgotPassword,

                            style: TextButton.styleFrom(
                              foregroundColor:
                                  primaryOrange,
                            ),

                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // LOGIN BUTTON
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 54,

                          child: ElevatedButton(
                            onPressed:
                                isLoading ? null : login,

                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  primaryOrange,

                              foregroundColor:
                                  Colors.white,

                              disabledBackgroundColor:
                                  primaryOrange.withOpacity(0.55),

                              elevation: 0,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                            ),

                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,

                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,

                                    children: [

                                      Text(
                                        "LOGIN",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),

                                      SizedBox(width: 9),

                                      Icon(
                                        Icons
                                            .arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // REGISTER
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),

                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [

                        const Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 13,
                          ),
                        ),

                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },

                          style: TextButton.styleFrom(
                            foregroundColor:
                                primaryOrange,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                          ),

                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // FOOTER
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      Icon(
                        Icons.storefront_rounded,
                        size: 15,
                        color: Colors.grey.shade500,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        "CampusBite • Campus Food Ordering",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
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