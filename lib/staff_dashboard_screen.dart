import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'staff_login_screen.dart';
import 'food_management_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() =>
      _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  String? staffStallId;
  String staffStallName = "Loading...";

  bool isLoadingStaff = true;

  @override
  void initState() {
    super.initState();
    loadStaffDetails();
  }

  // ============================================================
  // LOAD STAFF DETAILS
  // ============================================================

  Future<void> loadStaffDetails() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoadingStaff = false;
          staffStallName = "Staff not logged in";
        });

        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> staffDoc =
          await FirebaseFirestore.instance
              .collection("staff")
              .doc(user.uid)
              .get();

      if (!staffDoc.exists) {
        if (!mounted) return;

        setState(() {
          isLoadingStaff = false;
          staffStallId = null;
          staffStallName = "Staff account not found";
        });

        return;
      }

      final Map<String, dynamic>? staffData = staffDoc.data();

      final String? stallId =
          staffData?["stallId"]?.toString();

      if (stallId == null || stallId.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoadingStaff = false;
          staffStallId = null;
          staffStallName = "No stall assigned";
        });

        return;
      }

      String stallName = "Your Stall";

      final DocumentSnapshot<Map<String, dynamic>> stallDoc =
          await FirebaseFirestore.instance
              .collection("stalls")
              .doc(stallId)
              .get();

      if (stallDoc.exists) {
        final Map<String, dynamic>? stallData =
            stallDoc.data();

        stallName =
            stallData?["name"]?.toString() ?? "Your Stall";
      }

      if (!mounted) return;

      setState(() {
        staffStallId = stallId;
        staffStallName = stallName;
        isLoadingStaff = false;
      });
    } catch (e) {
      debugPrint("Error loading staff details: $e");

      if (!mounted) return;

      setState(() {
        isLoadingStaff = false;
        staffStallId = null;
        staffStallName = "Unable to load stall";
      });
    }
  }

  // ============================================================
  // MARK ORDER AS READY
  // ============================================================

  Future<void> markOrderReady(String orderId) async {
    if (staffStallId == null) {
      throw Exception("No stall assigned to this staff account.");
    }

    final DocumentReference<Map<String, dynamic>> orderRef =
        FirebaseFirestore.instance
            .collection("orders")
            .doc(orderId);

    final DocumentSnapshot<Map<String, dynamic>> orderDoc =
        await orderRef.get();

    if (!orderDoc.exists) {
      throw Exception("Order not found.");
    }

    final Map<String, dynamic>? orderData =
        orderDoc.data();

    final String orderStallId =
        orderData?["stallId"]?.toString() ?? "";

    // Extra protection:
    // Staff can update only their own stall's orders.
    if (orderStallId != staffStallId) {
      throw Exception(
        "You are not allowed to update this order.",
      );
    }

    await orderRef.update({
      "status": "READY",
      "readyAt": FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // MARK ORDER AS COMPLETED
  // ============================================================

  Future<void> markOrderCompleted(String orderId) async {
    if (staffStallId == null) {
      throw Exception("No stall assigned to this staff account.");
    }

    final DocumentReference<Map<String, dynamic>> orderRef =
        FirebaseFirestore.instance
            .collection("orders")
            .doc(orderId);

    final DocumentSnapshot<Map<String, dynamic>> orderDoc =
        await orderRef.get();

    if (!orderDoc.exists) {
      throw Exception("Order not found.");
    }

    final Map<String, dynamic>? orderData =
        orderDoc.data();

    final String orderStallId =
        orderData?["stallId"]?.toString() ?? "";

    if (orderStallId != staffStallId) {
      throw Exception(
        "You are not allowed to update this order.",
      );
    }

    await orderRef.update({
      "status": "COMPLETED",
      "completedAt": FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // OPEN WHATSAPP
  // ============================================================

  Future<void> sendWhatsAppMessage({
    required String phone,
    required String studentName,
    required String orderNumber,
  }) async {
    if (phone.trim().isEmpty) {
      throw Exception("Student phone number is not available.");
    }

    String cleanPhone =
        phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPhone.length == 10) {
      cleanPhone = "91$cleanPhone";
    }

    final String message =
        "Hello $studentName,\n\n"
        "Your CampusBite order #$orderNumber is READY! 🎉\n\n"
        "Please collect your food from $staffStallName.\n\n"
        "Thank you for using CampusBite! 🍔";

    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$cleanPhone"
      "?text=${Uri.encodeComponent(message)}",
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception("Could not open WhatsApp.");
      }
    } catch (e) {
      debugPrint("WhatsApp error: $e");
      rethrow;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Logout error: $e");
    }

    if (!context.mounted) return;

    // Remove the complete staff dashboard navigation stack
    // and go directly to Staff Login.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const StaffLoginScreen(),
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
      backgroundColor: const Color(0xffF8F8F8),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          "Staff Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        actions: [
          // FOOD MANAGEMENT
          IconButton(
            onPressed: staffStallId == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const FoodManagementScreen(),
                      ),
                    );
                  },
            icon: const Icon(
              Icons.restaurant_menu,
            ),
            tooltip: "Food Management",
          ),

          // LOGOUT
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(
              Icons.logout,
            ),
            tooltip: "Logout",
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: isLoadingStaff
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.deepOrange,
              ),
            )
          : staffStallId == null
              ? _buildNoStallAssigned()
              : StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>
                >(
                  stream: FirebaseFirestore.instance
                      .collection("orders")
                      .where(
                        "stallId",
                        isEqualTo: staffStallId,
                      )
                      .snapshots(),

                  builder: (context, snapshot) {
                    // ------------------------------------------------
                    // LOADING
                    // ------------------------------------------------

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.deepOrange,
                        ),
                      );
                    }

                    // ------------------------------------------------
                    // ERROR
                    // ------------------------------------------------

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "Error loading orders:\n${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    }

                    // ------------------------------------------------
                    // NO DATA
                    // ------------------------------------------------

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return _buildDashboardWithNoOrders();
                    }

                    // ------------------------------------------------
                    // GET ORDERS
                    // ------------------------------------------------

                    final List<
                        QueryDocumentSnapshot<
                            Map<String, dynamic>>> orders =
                        snapshot.data!.docs.toList();

                    // ------------------------------------------------
                    // SORT NEWEST FIRST
                    // ------------------------------------------------

                    orders.sort((a, b) {
                      final Map<String, dynamic> aData =
                          a.data();

                      final Map<String, dynamic> bData =
                          b.data();

                      final Timestamp? aTime =
                          aData["createdAt"] as Timestamp?;

                      final Timestamp? bTime =
                          bData["createdAt"] as Timestamp?;

                      if (aTime == null && bTime == null) {
                        return 0;
                      }

                      if (aTime == null) {
                        return 1;
                      }

                      if (bTime == null) {
                        return -1;
                      }

                      return bTime.compareTo(aTime);
                    });

                    // ------------------------------------------------
                    // COUNT STATUS
                    // ------------------------------------------------

                    final int preparingCount =
                        orders.where((doc) {
                      return doc.data()["status"] ==
                          "PREPARING";
                    }).length;

                    final int readyCount =
                        orders.where((doc) {
                      return doc.data()["status"] ==
                          "READY";
                    }).length;

                    final int completedCount =
                        orders.where((doc) {
                      return doc.data()["status"] ==
                          "COMPLETED";
                    }).length;

                    return Column(
                      children: [
                        // ==================================================
                        // STALL HEADER
                        // ==================================================

                        _buildStallHeader(),

                        // ==================================================
                        // ORDER SUMMARY
                        // ==================================================

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildCountCard(
                                  title: "Preparing",
                                  count: preparingCount,
                                  icon: Icons.restaurant,
                                  color: Colors.orange,
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: _buildCountCard(
                                  title: "Ready",
                                  count: readyCount,
                                  icon: Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: _buildCountCard(
                                  title: "Completed",
                                  count: completedCount,
                                  icon: Icons.done_all,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ==================================================
                        // ORDER LIST
                        // ==================================================

                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];

                              final Map<String, dynamic> data =
                                  order.data();

                              final String status =
                                  data["status"]?.toString() ??
                                      "PREPARING";

                              return OrderCard(
                                orderId: order.id,
                                data: data,

                                onReady: status == "PREPARING"
                                    ? () async {
                                        await markOrderReady(
                                          order.id,
                                        );

                                        await sendWhatsAppMessage(
                                          phone: data[
                                                      "studentPhone"]
                                                  ?.toString() ??
                                              "",
                                          studentName: data[
                                                      "studentName"]
                                                  ?.toString() ??
                                              "Student",
                                          orderNumber: data[
                                                      "orderNumber"]
                                                  ?.toString() ??
                                              "Unknown",
                                        );
                                      }
                                    : null,

                                onCompleted: status == "READY"
                                    ? () async {
                                        await markOrderCompleted(
                                          order.id,
                                        );
                                      }
                                    : null,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  // ============================================================
  // STALL HEADER
  // ============================================================

  Widget _buildStallHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepOrange.shade400,
            Colors.orange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "Managing Stall",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  staffStallName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Only orders from your stall are shown",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD WITH NO ORDERS
  // ============================================================

  Widget _buildDashboardWithNoOrders() {
    return Column(
      children: [
        _buildStallHeader(),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildCountCard(
                  title: "Preparing",
                  count: 0,
                  icon: Icons.restaurant,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildCountCard(
                  title: "Ready",
                  count: 0,
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildCountCard(
                  title: "Completed",
                  count: 0,
                  icon: Icons.done_all,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _buildNoOrders(),
        ),
      ],
    );
  }

  // ============================================================
  // NO STALL ASSIGNED
  // ============================================================

  Widget _buildNoStallAssigned() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.store_mall_directory_outlined,
              size: 80,
              color: Colors.orange,
            ),

            const SizedBox(height: 20),

            const Text(
              "No Stall Assigned",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Your staff account has not been assigned "
              "to a food stall yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: () {
                logout(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text("BACK TO STAFF LOGIN"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO ORDERS
  // ============================================================

  Widget _buildNoOrders() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey,
          ),

          const SizedBox(height: 20),

          const Text(
            "No orders yet",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              "New orders for $staffStallName "
              "will appear here.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COUNT CARD
  // ============================================================

  Widget _buildCountCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 25,
          ),

          const SizedBox(height: 6),

          Text(
            "$count",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// ORDER CARD
// =================================================================

class OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  final Future<void> Function()? onReady;
  final Future<void> Function()? onCompleted;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.data,
    required this.onReady,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // ORDER DATA
    // ============================================================

    final String orderNumber =
        data["orderNumber"]?.toString() ?? "Unknown";

    final String studentName =
        data["studentName"]?.toString() ?? "Student";

    final String studentPhone =
        data["studentPhone"]?.toString() ?? "";

    final String paymentMethod =
        data["paymentMethod"]?.toString() ?? "CASH";

    final String status =
        data["status"]?.toString() ?? "PREPARING";

    final int total =
        (data["totalAmount"] as num?)?.toInt() ?? 0;

    final List<dynamic> items =
        data["items"] is List ? data["items"] : [];

    // ============================================================
    // STATUS DETAILS
    // ============================================================

    Color statusColor;
    Color statusBackground;
    IconData statusIcon;

    if (status == "READY") {
      statusColor = Colors.green;
      statusBackground = Colors.green.shade100;
      statusIcon = Icons.check_circle;
    } else if (status == "COMPLETED") {
      statusColor = Colors.blue;
      statusBackground = Colors.blue.shade100;
      statusIcon = Icons.done_all;
    } else {
      statusColor = Colors.deepOrange;
      statusBackground = Colors.orange.shade100;
      statusIcon = Icons.restaurant;
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // ORDER NUMBER + STATUS
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "Order #$orderNumber",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),

                        const SizedBox(width: 5),

                        Flexible(
                          child: Text(
                            status,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            const Divider(),

            const SizedBox(height: 10),

            // ==================================================
            // STUDENT
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons.person,
                  color: Colors.deepOrange,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      if (studentPhone.isNotEmpty)
                        Text(
                          studentPhone,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // FOOD ITEMS
            // ==================================================

            const Text(
              "Items",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            ...items.map(
              (item) {
                final Map<String, dynamic> food =
                    item is Map
                        ? Map<String, dynamic>.from(item)
                        : <String, dynamic>{};

                final String name =
                    food["name"]?.toString() ?? "";

                final int quantity =
                    (food["quantity"] as num?)?.toInt() ??
                        1;

                final int price =
                    (food["price"] as num?)?.toInt() ??
                        0;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 6,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "$name × $quantity",
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ),

                      Text(
                        "₹${price * quantity}",
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            const Divider(),

            // ==================================================
            // TOTAL
            // ==================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  "₹$total",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              "Payment: $paymentMethod",
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // PREPARING → READY
            // ==================================================

            if (status == "PREPARING" &&
                onReady != null)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await onReady!();

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Order marked as READY. "
                            "WhatsApp opened 🎉",
                          ),
                          behavior:
                              SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            "Failed to update order: $e",
                          ),
                          behavior:
                              SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.check_circle,
                  ),
                  label: const Text(
                    "MARK READY & NOTIFY WHATSAPP",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

            // ==================================================
            // READY → COMPLETED
            // ==================================================

            if (status == "READY" &&
                onCompleted != null)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await onCompleted!();

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Order marked as COMPLETED ✅",
                          ),
                          behavior:
                              SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            "Failed to complete order: $e",
                          ),
                          behavior:
                              SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.done_all,
                  ),
                  label: const Text(
                    "MARK COMPLETED",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

            // ==================================================
            // COMPLETED MESSAGE
            // ==================================================

            if (status == "COMPLETED")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.done_all,
                      color: Colors.blue,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        "This order has been completed.",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ==================================================
            // PHONE WARNING
            // ==================================================

            if (status == "PREPARING" &&
                studentPhone.trim().isEmpty)
              const Padding(
                padding:
                    EdgeInsets.only(top: 8),
                child: Text(
                  "Student phone number is not available. "
                  "WhatsApp notification cannot be opened.",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}