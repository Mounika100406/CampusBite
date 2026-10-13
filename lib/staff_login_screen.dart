import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'staff_dashboard_screen.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  Future<void> staffLogin() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty) {
      showMessage("Please enter email and password");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ------------------------------------------------
      // STEP 1: Firebase Authentication
      // ------------------------------------------------
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user == null) {
        showMessage("Unable to login. Please try again.");
        return;
      }

      String uid = user.uid;

      print("Staff Firebase UID: $uid");

      // ------------------------------------------------
      // STEP 2: Check staff document in Firestore
      // ------------------------------------------------
      DocumentSnapshot staffDoc = await FirebaseFirestore.instance
          .collection("staff")
          .doc(uid)
          .get();

      print("Staff document exists: ${staffDoc.exists}");

      // ------------------------------------------------
      // STEP 3: Staff document does not exist
      // ------------------------------------------------
      if (!staffDoc.exists) {
        await FirebaseAuth.instance.signOut();

        showMessage(
          "Login successful, but staff profile was not found.\n"
          "Create staff/$uid in Firestore.",
        );

        return;
      }

      // ------------------------------------------------
      // STEP 4: Read staff data
      // ------------------------------------------------
      Map<String, dynamic> staffData =
          staffDoc.data() as Map<String, dynamic>;

      String role = staffData["role"]?.toString() ?? "";
      bool active = staffData["active"] == true;

      print("Staff role: $role");
      print("Staff active: $active");

      // ------------------------------------------------
      // STEP 5: Check staff role
      // ------------------------------------------------
      if (role != "staff") {
        await FirebaseAuth.instance.signOut();

        showMessage(
          "You don't have staff access.\n"
          "Role found: $role",
        );

        return;
      }

      // ------------------------------------------------
      // STEP 6: Check active status
      // ------------------------------------------------
      if (!active) {
        await FirebaseAuth.instance.signOut();

        showMessage("Your staff account is inactive.");

        return;
      }

      // ------------------------------------------------
      // STEP 7: Login successful
      // ------------------------------------------------
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const StaffDashboardScreen(),
        ),
        (route) => false,
      );
    }

    // ------------------------------------------------
    // Firebase Authentication Errors
    // ------------------------------------------------
    on FirebaseAuthException catch (e) {
      print("Firebase Auth Error Code: ${e.code}");
      print("Firebase Auth Error Message: ${e.message}");

      String message;

      switch (e.code) {
        case "user-not-found":
          message = "Staff account not found.";
          break;

        case "wrong-password":
          message = "Incorrect password.";
          break;

        case "invalid-credential":
          message = "Invalid email or password.";
          break;

        case "invalid-email":
          message = "Invalid email address.";
          break;

        case "user-disabled":
          message = "This staff account has been disabled.";
          break;

        case "too-many-requests":
          message = "Too many login attempts. Try again later.";
          break;

        case "network-request-failed":
          message = "Network error. Check your internet connection.";
          break;

        case "operation-not-allowed":
          message = "Email/password login is not enabled in Firebase.";
          break;

        default:
          message =
              "Authentication error: ${e.code}\n"
              "${e.message ?? 'Unknown error'}";
      }

      showMessage(message);
    }

    // ------------------------------------------------
    // Firestore Errors
    // ------------------------------------------------
    on FirebaseException catch (e) {
      print("Firebase Error Code: ${e.code}");
      print("Firebase Error Message: ${e.message}");

      String message;

      switch (e.code) {
        case "permission-denied":
          message =
              "Firestore permission denied.\n"
              "Please check your Firestore Rules.";
          break;

        case "unavailable":
          message =
              "Firestore is currently unavailable.\n"
              "Check your internet connection.";
          break;

        case "not-found":
          message = "Firestore document was not found.";
          break;

        default:
          message =
              "Firebase error: ${e.code}\n"
              "${e.message ?? 'Unknown Firebase error'}";
      }

      // If authentication was successful but Firestore failed,
      // sign out the staff user.
      await FirebaseAuth.instance.signOut();

      showMessage(message);
    }

    // ------------------------------------------------
    // Any other error
    // ------------------------------------------------
    catch (e) {
      print("Unknown Error: $e");

      await FirebaseAuth.instance.signOut();

      showMessage(
        "Unexpected error:\n$e",
      );
    }

    // ------------------------------------------------
    // Stop loading
    // ------------------------------------------------
    finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------
  // Show Snackbar Message
  // ------------------------------------------------
  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F8F8),

      // ------------------------------------------------
      // APP BAR
      // ------------------------------------------------
      appBar: AppBar(
        title: const Text(
          "Staff Login",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // ------------------------------------------------
      // BODY
      // ------------------------------------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),

        child: Column(
          children: [
            const SizedBox(height: 30),

            // ------------------------------------------------
            // STAFF ICON
            // ------------------------------------------------
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 75,
                color: Colors.deepOrange,
              ),
            ),

            const SizedBox(height: 25),

            // ------------------------------------------------
            // TITLE
            // ------------------------------------------------
            const Text(
              "CampusBite Staff",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Login to manage food orders",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 40),

            // ------------------------------------------------
            // EMAIL
            // ------------------------------------------------
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,

              decoration: InputDecoration(
                labelText: "Email",
                hintText: "Enter staff email",

                prefixIcon: const Icon(Icons.email),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------
            // PASSWORD
            // ------------------------------------------------
            TextField(
              controller: passwordController,
              obscureText: hidePassword,

              decoration: InputDecoration(
                labelText: "Password",
                hintText: "Enter password",

                prefixIcon: const Icon(Icons.lock),

                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },

                  icon: Icon(
                    hidePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ------------------------------------------------
            // LOGIN BUTTON
            // ------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: isLoading ? null : staffLogin,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                child: isLoading
                    ? const SizedBox(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        "STAFF LOGIN",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}