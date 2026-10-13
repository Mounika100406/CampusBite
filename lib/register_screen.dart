import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  // =========================================================
  // REGISTER USER
  // =========================================================

  Future<void> register() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword =
        confirmPasswordController.text.trim();

    // ---------------------------------------------------------
    // VALIDATION
    // ---------------------------------------------------------

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    if (name.length < 3) {
      showMessage("Please enter a valid name");
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      showMessage(
        "Please enter a valid 10-digit mobile number",
      );
      return;
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email)) {
      showMessage("Please enter a valid email address");
      return;
    }

    if (password.length < 6) {
      showMessage(
        "Password must contain at least 6 characters",
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage("Passwords do not match");
      return;
    }

    // ---------------------------------------------------------
    // START LOADING
    // ---------------------------------------------------------

    setState(() {
      isLoading = true;
    });

    try {
      // =======================================================
      // STEP 1: CREATE FIREBASE AUTH ACCOUNT
      // =======================================================

      print("STEP 1: Creating Firebase account...");

      UserCredential userCredential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user == null) {
        print("ERROR: Firebase user is null");

        if (mounted) {
          showMessage(
            "Registration failed. User was not created.",
          );
        }

        return;
      }

      print("STEP 1 SUCCESS");
      print("User UID: ${user.uid}");

      // =======================================================
      // STEP 2: SAVE USER DATA IN FIRESTORE
      // =======================================================

      print("STEP 2: Saving user data to Firestore...");

      try {
        await FirebaseFirestore.instance
            .collection("students")
            .doc(user.uid)
            .set({
          "name": name,
          "email": email,
          "phone": phone,
          "createdAt": FieldValue.serverTimestamp(),
        });

        print("STEP 2 SUCCESS: Firestore data saved");
      } on FirebaseException catch (e) {
        print("FIRESTORE ERROR CODE: ${e.code}");
        print("FIRESTORE ERROR MESSAGE: ${e.message}");

        // If Firestore fails, delete the Auth account
        // so we don't leave an incomplete registration.
        try {
          await user.delete();
        } catch (deleteError) {
          print(
            "Could not delete incomplete Auth account: "
            "$deleteError",
          );
        }

        if (mounted) {
          if (e.code == "permission-denied") {
            showMessage(
              "Firestore permission denied. Check Firestore rules.",
            );
          } else if (e.code == "unavailable") {
            showMessage(
              "Firestore is unavailable. Check your internet.",
            );
          } else {
            showMessage(
              "Firestore error: ${e.message ?? e.code}",
            );
          }
        }

        return;
      }

      // =======================================================
      // STEP 3: UPDATE FIREBASE DISPLAY NAME
      // =======================================================

      print("STEP 3: Updating display name...");

      try {
        await user.updateDisplayName(name);
        print("STEP 3 SUCCESS");
      } catch (e) {
        print("Display name update failed: $e");
      }

      // =======================================================
      // REGISTRATION SUCCESS
      // =======================================================

      if (!mounted) return;

      showMessage("Registration successful!");

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

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
      print("=================================");
      print("FIREBASE AUTH ERROR");
      print("ERROR CODE: ${e.code}");
      print("ERROR MESSAGE: ${e.message}");
      print("=================================");

      String message = "Registration failed";

      if (e.code == "email-already-in-use") {
        message =
            "An account already exists with this email.";
      } else if (e.code == "invalid-email") {
        message =
            "Please enter a valid email address.";
      } else if (e.code == "weak-password") {
        message =
            "Password is too weak. Use at least 6 characters.";
      } else if (e.code == "operation-not-allowed") {
        message =
            "Email/Password login is disabled in Firebase.";
      } else if (e.code == "network-request-failed") {
        message =
            "Network error. Please check your internet connection.";
      } else if (e.code == "too-many-requests") {
        message =
            "Too many attempts. Please try again later.";
      } else if (e.code == "invalid-credential") {
        message =
            "Invalid registration details.";
      } else {
        message =
            "Firebase error: ${e.message ?? e.code}";
      }

      if (mounted) {
        showMessage(message);
      }
    }

    // =========================================================
    // OTHER ERROR
    // =========================================================

    catch (e) {
      print("=================================");
      print("UNKNOWN REGISTRATION ERROR");
      print("ERROR: $e");
      print("=================================");

      if (mounted) {
        showMessage(
          "Something went wrong. Check the terminal for details.",
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
      ),
    );
  }

  // =========================================================
  // DISPOSE CONTROLLERS
  // =========================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Account",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),

        child: Column(
          children: [
            const SizedBox(height: 15),

            // -------------------------------------------------
            // ICON
            // -------------------------------------------------

            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.person_add,
                size: 65,
                color: Colors.deepOrange,
              ),
            ),

            const SizedBox(height: 20),

            // -------------------------------------------------
            // TITLE
            // -------------------------------------------------

            const Text(
              "Create your account",

              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Join CampusBite and order food easily",

              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 30),

            // -------------------------------------------------
            // NAME
            // -------------------------------------------------

            TextField(
              controller: nameController,

              textCapitalization:
                  TextCapitalization.words,

              decoration: InputDecoration(
                labelText: "Full Name",
                hintText: "Enter your name",

                prefixIcon: const Icon(
                  Icons.person_outline,
                ),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // -------------------------------------------------
            // EMAIL
            // -------------------------------------------------

            TextField(
              controller: emailController,

              keyboardType:
                  TextInputType.emailAddress,

              decoration: InputDecoration(
                labelText: "Email",
                hintText: "Enter your email",

                prefixIcon: const Icon(
                  Icons.email_outlined,
                ),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // -------------------------------------------------
            // PHONE
            // -------------------------------------------------

            TextField(
              controller: phoneController,

              keyboardType:
                  TextInputType.phone,

              maxLength: 10,

              decoration: InputDecoration(
                labelText: "Mobile Number",
                hintText: "Enter 10-digit number",

                prefixIcon: const Icon(
                  Icons.phone_outlined,
                ),

                prefixText: "+91 ",

                counterText: "",

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // -------------------------------------------------
            // PASSWORD
            // -------------------------------------------------

            TextField(
              controller: passwordController,

              obscureText: hidePassword,

              decoration: InputDecoration(
                labelText: "Password",
                hintText: "Minimum 6 characters",

                prefixIcon: const Icon(
                  Icons.lock_outline,
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
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // -------------------------------------------------
            // CONFIRM PASSWORD
            // -------------------------------------------------

            TextField(
              controller:
                  confirmPasswordController,

              obscureText:
                  hideConfirmPassword,

              decoration: InputDecoration(
                labelText: "Confirm Password",
                hintText: "Re-enter your password",

                prefixIcon: const Icon(
                  Icons.lock_reset_outlined,
                ),

                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hideConfirmPassword =
                          !hideConfirmPassword;
                    });
                  },

                  icon: Icon(
                    hideConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // -------------------------------------------------
            // REGISTER BUTTON
            // -------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed:
                    isLoading ? null : register,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.deepOrange,

                  foregroundColor:
                      Colors.white,

                  disabledBackgroundColor:
                      Colors.deepOrange.shade200,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),

                child: isLoading
                    ? const SizedBox(
                        height: 25,
                        width: 25,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "CREATE ACCOUNT",

                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // -------------------------------------------------
            // FOOTER
            // -------------------------------------------------

            Text(
              "By creating an account, you agree to use CampusBite responsibly.",

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
