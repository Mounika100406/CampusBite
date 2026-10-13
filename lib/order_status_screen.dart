import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderId;
  final String orderNumber;

  const OrderStatusScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Order Status",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .doc(orderId)
            .snapshots(),

        builder: (context, snapshot) {
          // =========================
          // LOADING
          // =========================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // =========================
          // ERROR
          // =========================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error loading order:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // =========================
          // ORDER NOT FOUND
          // =========================

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Order not found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final data = snapshot.data!.data()!;

          // =========================
          // ORDER DATA
          // =========================

          final String status =
              data["status"]?.toString().toUpperCase() ?? "PREPARING";

          final String stallName =
              data["stallName"]?.toString() ?? "Campus Food Stall";

          final double total =
              data["totalAmount"] is num
                  ? (data["totalAmount"] as num).toDouble()
                  : 0;

          final List<dynamic> items =
              data["items"] is List ? data["items"] : [];

          // =========================
          // STATUS DETAILS
          // =========================

          IconData statusIcon;
          Color statusColor;
          Color statusBackground;
          String statusTitle;
          String statusMessage;

          if (status == "READY") {
            statusIcon = Icons.check_circle;
            statusColor = Colors.green;
            statusBackground = Colors.green.shade50;
            statusTitle = "Your Food is Ready! 🎉";
            statusMessage =
                "Please go to $stallName and collect your order.";
          } else if (status == "COMPLETED") {
            statusIcon = Icons.done_all;
            statusColor = Colors.blue;
            statusBackground = Colors.blue.shade50;
            statusTitle = "Order Completed ✅";
            statusMessage =
                "Your order has been successfully collected. Thank you!";
          } else {
            statusIcon = Icons.restaurant;
            statusColor = Colors.orange;
            statusBackground = Colors.orange.shade50;
            statusTitle = "Preparing Your Food 🍔";
            statusMessage =
                "$stallName is preparing your order. Please wait.";
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // =========================
                  // STATUS ICON
                  // =========================

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusIcon,
                      size: 80,
                      color: statusColor,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =========================
                  // STATUS TITLE
                  // =========================

                  Text(
                    statusTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // =========================
                  // ORDER NUMBER
                  // =========================

                  Text(
                    "Order #$orderNumber",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // =========================
                  // STALL NAME
                  // =========================

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.store,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          stallName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // STATUS MESSAGE
                  // =========================

                  Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // ORDER PROGRESS
                  // =========================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Order Progress",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildProgressStep(
                          title: "Order Placed",
                          subtitle: "Your order has been received",
                          icon: Icons.receipt_long,
                          active: true,
                          completed: true,
                          color: Colors.blue,
                        ),

                        _buildProgressLine(
                          active:
                              status == "READY" ||
                              status == "COMPLETED",
                        ),

                        _buildProgressStep(
                          title: "Preparing",
                          subtitle: "The stall is preparing your food",
                          icon: Icons.restaurant,
                          active:
                              status == "PREPARING" ||
                              status == "READY" ||
                              status == "COMPLETED",
                          completed:
                              status == "READY" ||
                              status == "COMPLETED",
                          color: Colors.orange,
                        ),

                        _buildProgressLine(
                          active:
                              status == "READY" ||
                              status == "COMPLETED",
                        ),

                        _buildProgressStep(
                          title: "Ready",
                          subtitle: "Food is ready for collection",
                          icon: Icons.check_circle,
                          active:
                              status == "READY" ||
                              status == "COMPLETED",
                          completed:
                              status == "READY" ||
                              status == "COMPLETED",
                          color: Colors.green,
                        ),

                        _buildProgressLine(
                          active: status == "COMPLETED",
                        ),

                        _buildProgressStep(
                          title: "Completed",
                          subtitle: "Order has been collected",
                          icon: Icons.done_all,
                          active: status == "COMPLETED",
                          completed: status == "COMPLETED",
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // ORDER DETAILS
                  // =========================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Order Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        if (items.isEmpty)
                          const Text(
                            "No items found",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),

                        ...items.map(
                          (item) {
                            final String name =
                                item["name"]?.toString() ?? "Item";

                            final int quantity =
                                item["quantity"] is num
                                    ? (item["quantity"] as num).toInt()
                                    : 1;

                            final double price =
                                item["price"] is num
                                    ? (item["price"] as num).toDouble()
                                    : 0;

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12,
                              ),

                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "$name × $quantity",
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    "₹${(price * quantity).toInt()}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const Divider(),

                        const SizedBox(height: 8),

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
                              "₹${total.toInt()}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // PAYMENT
                  // =========================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments,
                          color: Colors.green,
                        ),

                        SizedBox(width: 10),

                        Flexible(
                          child: Text(
                            "Pay cash when you collect your order",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // READY MESSAGE
                  // =========================

                  if (status == "READY")
                    _buildInfoCard(
                      icon: Icons.notifications_active,
                      title: "Your order is ready! 🎉",
                      message:
                          "Go to $stallName and collect your food.",
                      color: Colors.green,
                    ),

                  // =========================
                  // PREPARING MESSAGE
                  // =========================

                  if (status == "PREPARING")
                    _buildInfoCard(
                      icon: Icons.hourglass_top,
                      title: "Your food is being prepared 🍔",
                      message:
                          "Please wait for the stall owner to mark your order as READY.",
                      color: Colors.orange,
                    ),

                  // =========================
                  // COMPLETED MESSAGE
                  // =========================

                  if (status == "COMPLETED")
                    _buildInfoCard(
                      icon: Icons.done_all,
                      title: "Order completed successfully! ✅",
                      message:
                          "You have collected your order from $stallName.",
                      color: Colors.blue,
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PROGRESS STEP
  // ============================================================

  static Widget _buildProgressStep({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool active,
    required bool completed,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: active
                ? color.withOpacity(0.15)
                : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            completed ? Icons.check : icon,
            color: active ? color : Colors.grey,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.black : Colors.grey,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROGRESS LINE
  // ============================================================

  static Widget _buildProgressLine({
    required bool active,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        left: 20,
        top: 3,
        bottom: 3,
      ),
      height: 25,
      width: 2,
      color: active
          ? Colors.green
          : Colors.grey.shade300,
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  static Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 35,
          ),

          const SizedBox(height: 10),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
