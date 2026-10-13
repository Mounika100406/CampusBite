import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_status_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    // ------------------------------------------------
    // Check Login
    // ------------------------------------------------

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Please login to view your orders",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // ------------------------------------------------
    // Firestore Orders
    // ------------------------------------------------

    return Scaffold(
      backgroundColor: const Color(0xffF8F8F8),

      appBar: AppBar(
        title: const Text(
          "My Orders",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where(
              "studentId",
              isEqualTo: user.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {
          // ------------------------------------------------
          // Loading
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
          // Error
          // ------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Unable to load orders",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ------------------------------------------------
          // No Orders
          // ------------------------------------------------

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return _buildEmptyOrders();
          }

          // ------------------------------------------------
          // Get Orders
          // ------------------------------------------------

          List<QueryDocumentSnapshot> orders =
              snapshot.data!.docs.toList();

          // ------------------------------------------------
          // Sort Newest First
          // ------------------------------------------------

          orders.sort((a, b) {
            Timestamp? dateA =
                a["createdAt"] as Timestamp?;

            Timestamp? dateB =
                b["createdAt"] as Timestamp?;

            if (dateA == null && dateB == null) {
              return 0;
            }

            if (dateA == null) {
              return 1;
            }

            if (dateB == null) {
              return -1;
            }

            return dateB.compareTo(dateA);
          });

          // ------------------------------------------------
          // Order List
          // ------------------------------------------------

          return RefreshIndicator(
            color: Colors.deepOrange,

            onRefresh: () async {
              await Future.delayed(
                const Duration(milliseconds: 500),
              );
            },

            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,

              itemBuilder: (context, index) {
                final order = orders[index];

                return _buildOrderCard(
                  context,
                  order,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY ORDERS
  // ============================================================

  Widget _buildEmptyOrders() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              height: 100,
              width: 100,

              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.receipt_long,
                size: 50,
                color: Colors.deepOrange,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "No Orders Yet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Your food orders will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(
    BuildContext context,
    QueryDocumentSnapshot order,
  ) {
    final Map<String, dynamic> data =
        order.data() as Map<String, dynamic>;

    String orderNumber =
        data["orderNumber"]?.toString() ?? "N/A";

    String status =
        data["status"]?.toString() ?? "PREPARING";

    String paymentMethod =
        data["paymentMethod"]?.toString() ?? "CASH";

    num totalAmount =
        data["totalAmount"] ?? 0;

    List<dynamic> items =
        data["items"] ?? [];

    Timestamp? createdAt =
        data["createdAt"] as Timestamp?;

    // ------------------------------------------------
    // Status Information
    // ------------------------------------------------

    bool isReady =
        status.toUpperCase() == "READY";

    Color statusColor =
        isReady ? Colors.green : Colors.orange;

    IconData statusIcon =
        isReady
            ? Icons.check_circle
            : Icons.access_time;

    String statusText =
        isReady
            ? "READY"
            : "PREPARING";

    // ------------------------------------------------
    // Date
    // ------------------------------------------------

    String orderDate = "";

    if (createdAt != null) {
      DateTime date = createdAt.toDate();

      orderDate =
          "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year} "
          "${date.hour.toString().padLeft(2, '0')}:"
          "${date.minute.toString().padLeft(2, '0')}";
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 18,
      ),

      elevation: 3,

      shadowColor:
          Colors.black.withOpacity(0.08),

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ==================================================
            // ORDER HEADER
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "Order Number",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        "#$orderNumber",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color:
                        statusColor.withOpacity(
                      0.1,
                    ),

                    borderRadius:
                        BorderRadius.circular(20),
                  ),

                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      Icon(
                        statusIcon,
                        size: 18,
                        color: statusColor,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            const Divider(),

            const SizedBox(height: 10),

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

            const SizedBox(height: 10),

            ...items.map(
              (item) {
                String name =
                    item["name"]?.toString() ??
                        "Item";

                num price =
                    item["price"] ?? 0;

                num quantity =
                    item["quantity"] ?? 1;

                num itemTotal =
                    price * quantity;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 9,
                  ),

                  child: Row(
                    children: [

                      // Quantity

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),

                        decoration:
                            BoxDecoration(
                          color: Colors
                              .deepOrange
                              .shade50,

                          borderRadius:
                              BorderRadius
                                  .circular(8),
                        ),

                        child: Text(
                          "x$quantity",

                          style:
                              const TextStyle(
                            color:
                                Colors.deepOrange,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Food name

                      Expanded(
                        child: Text(
                          name,
                          style:
                              const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ),

                      // Price

                      Text(
                        "₹$itemTotal",
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(),

            const SizedBox(height: 10),

            // ==================================================
            // TOTAL
            // ==================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                Text(
                  "₹$totalAmount",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.deepOrange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // PAYMENT + DATE
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: Colors.grey,
                ),

                const SizedBox(width: 6),

                Text(
                  paymentMethod,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const Spacer(),

                if (orderDate.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 15,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        orderDate,
                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // ==================================================
            // READY MESSAGE
            // ==================================================

            if (isReady) ...[
              const SizedBox(height: 15),

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(13),

                decoration: BoxDecoration(
                  color:
                      Colors.green.shade50,

                  borderRadius:
                      BorderRadius.circular(12),

                  border: Border.all(
                    color:
                        Colors.green.shade200,
                  ),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        "Your order is ready! "
                        "Please collect it from the stall.",

                        style: TextStyle(
                          color: Colors.green,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 15),

            // ==================================================
            // TRACK ORDER BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) =>
                          OrderStatusScreen(
                        orderId: order.id,
                        orderNumber: orderNumber,
                      ),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.track_changes,
                ),

                label: const Text(
                  "TRACK MY ORDER",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.deepOrange,

                  foregroundColor:
                      Colors.white,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
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