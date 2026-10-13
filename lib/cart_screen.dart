import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'order_status_screen.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;

  // Selected stall information
  final String stallId;
  final String stallName;

  const CartScreen({
    super.key,
    required this.cart,
    required this.stallId,
    required this.stallName,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isLoading = false;

  // ============================================================
  // CALCULATE TOTAL
  // ============================================================

  int get total {
    int amount = 0;

    for (final item in widget.cart) {
      final int price = (item["price"] as num?)?.toInt() ?? 0;
      final int quantity =
          (item["quantity"] as num?)?.toInt() ?? 0;

      amount += price * quantity;
    }

    return amount;
  }

  // ============================================================
  // INCREASE QUANTITY
  // ============================================================

  void increase(int index) {
    setState(() {
      final currentQuantity =
          (widget.cart[index]["quantity"] as num?)?.toInt() ?? 0;

      widget.cart[index]["quantity"] = currentQuantity + 1;
    });
  }

  // ============================================================
  // DECREASE QUANTITY
  // ============================================================

  void decrease(int index) {
    setState(() {
      final currentQuantity =
          (widget.cart[index]["quantity"] as num?)?.toInt() ?? 0;

      if (currentQuantity > 1) {
        widget.cart[index]["quantity"] = currentQuantity - 1;
      } else {
        widget.cart.removeAt(index);
      }
    });
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // PLACE ORDER
  // ============================================================

  Future<void> placeOrder() async {
    // ----------------------------------------------------------
    // CHECK CART
    // ----------------------------------------------------------

    if (widget.cart.isEmpty) {
      showMessage("Your cart is empty");
      return;
    }

    // ----------------------------------------------------------
    // CHECK LOGIN
    // ----------------------------------------------------------

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage("Please login before placing an order");
      return;
    }

    // ----------------------------------------------------------
    // CHECK STALL
    // ----------------------------------------------------------

    if (widget.stallId.trim().isEmpty) {
      showMessage("Stall information is missing");
      return;
    }

    if (widget.stallName.trim().isEmpty) {
      showMessage("Stall name is missing");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ========================================================
      // GET STUDENT DETAILS
      // ========================================================

      final DocumentSnapshot studentDocument =
          await FirebaseFirestore.instance
              .collection("students")
              .doc(user.uid)
              .get();

      if (!studentDocument.exists) {
        showMessage("Student profile not found");

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        return;
      }

      final Map<String, dynamic> studentData =
          studentDocument.data() as Map<String, dynamic>;

      final String studentName =
          studentData["name"]?.toString() ?? "Student";

      final String studentPhone =
          studentData["phone"]?.toString() ?? "";

      // ========================================================
      // CREATE ORDER NUMBER
      // ========================================================

      final String orderNumber =
          "CB${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

      // ========================================================
      // PREPARE ORDER ITEMS
      // ========================================================

      final List<Map<String, dynamic>> orderItems = [];

      for (final item in widget.cart) {
        orderItems.add({
          "foodId": item["id"]?.toString() ?? "",
          "name": item["name"]?.toString() ?? "",
          "price": (item["price"] as num?)?.toInt() ?? 0,
          "quantity": (item["quantity"] as num?)?.toInt() ?? 0,
        });
      }

      // ========================================================
      // SAVE ORDER TO FIRESTORE
      // ========================================================

      final DocumentReference orderReference =
          await FirebaseFirestore.instance
              .collection("orders")
              .add({
        // ------------------------------------------------------
        // ORDER DETAILS
        // ------------------------------------------------------

        "orderNumber": orderNumber,

        // ------------------------------------------------------
        // STUDENT DETAILS
        // ------------------------------------------------------

        "studentId": user.uid,
        "studentName": studentName,
        "studentPhone": studentPhone,

        // ------------------------------------------------------
        // STALL DETAILS
        // ------------------------------------------------------

        // IMPORTANT:
        // These are dynamic.
        // They are NOT hardcoded to main_stall.

        "stallId": widget.stallId,
        "stallName": widget.stallName,

        // ------------------------------------------------------
        // FOOD ITEMS
        // ------------------------------------------------------

        "items": orderItems,

        // ------------------------------------------------------
        // PAYMENT
        // ------------------------------------------------------

        "totalAmount": total,
        "paymentMethod": "CASH",

        // ------------------------------------------------------
        // ORDER STATUS
        // ------------------------------------------------------

        "status": "PREPARING",

        // ------------------------------------------------------
        // TIME
        // ------------------------------------------------------

        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // ========================================================
      // SHOW SUCCESS SCREEN
      // ========================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSuccessScreen(
            orderId: orderReference.id,
            orderNumber: orderNumber,
            total: total,
            stallName: widget.stallName,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        showMessage(
          "Firebase error: ${e.message ?? "Something went wrong"}",
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          "Something went wrong. Please try again.",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // FOOD IMAGE
  // ============================================================

  Widget buildFoodImage(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return Container(
        height: 75,
        width: 75,
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.fastfood,
          color: Colors.orange,
          size: 32,
        ),
      );
    }

    if (imagePath.startsWith("http")) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imagePath,
          height: 75,
          width: 75,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 75,
              width: 75,
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.fastfood,
                color: Colors.grey,
                size: 32,
              ),
            );
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        imagePath,
        height: 75,
        width: 75,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 75,
            width: 75,
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.fastfood,
              color: Colors.grey,
              size: 32,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          "My Cart",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: widget.cart.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                // ==================================================
                // STALL INFORMATION
                // ==================================================

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    8,
                  ),
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.shade100,
                    ),
                  ),

                  child: Row(
                    children: [
                      Container(
                        height: 45,
                        width: 45,

                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: const Icon(
                          Icons.storefront,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            const Text(
                              "Ordering from",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              widget.stallName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // CART ITEMS
                // ==================================================

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),

                    itemCount: widget.cart.length,

                    itemBuilder: (context, index) {
                      final item = widget.cart[index];

                      final String name =
                          item["name"]?.toString() ?? "Food";

                      final int price =
                          (item["price"] as num?)?.toInt() ?? 0;

                      final int quantity =
                          (item["quantity"] as num?)?.toInt() ?? 0;

                      final int itemTotal =
                          price * quantity;

                      final String? image =
                          item["image"]?.toString();

                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: 14,
                        ),

                        padding: const EdgeInsets.all(14),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(18),

                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            // ======================================
                            // IMAGE
                            // ======================================

                            buildFoodImage(image),

                            const SizedBox(width: 13),

                            // ======================================
                            // FOOD DETAILS
                            // ======================================

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,

                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    "₹$price",
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 9),

                                  Row(
                                    children: [
                                      // MINUS
                                      InkWell(
                                        onTap: () {
                                          decrease(index);
                                        },

                                        borderRadius:
                                            BorderRadius.circular(
                                          20,
                                        ),

                                        child: Container(
                                          height: 32,
                                          width: 32,

                                          decoration:
                                              BoxDecoration(
                                            color: Colors
                                                .orange
                                                .shade50,
                                            shape:
                                                BoxShape.circle,
                                          ),

                                          child: const Icon(
                                            Icons.remove,
                                            size: 18,
                                            color:
                                                Colors.orange,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Text(
                                        "$quantity",
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // PLUS
                                      InkWell(
                                        onTap: () {
                                          increase(index);
                                        },

                                        borderRadius:
                                            BorderRadius.circular(
                                          20,
                                        ),

                                        child: Container(
                                          height: 32,
                                          width: 32,

                                          decoration:
                                              const BoxDecoration(
                                            color: Colors.orange,
                                            shape:
                                                BoxShape.circle,
                                          ),

                                          child: const Icon(
                                            Icons.add,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // ======================================
                            // ITEM TOTAL
                            // ======================================

                            Text(
                              "₹$itemTotal",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // ==================================================
                // ORDER SUMMARY
                // ==================================================

                Container(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    18,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),

                  child: SafeArea(
                    top: false,

                    child: Column(
                      children: [
                        // ------------------------------------------
                        // TOTAL
                        // ------------------------------------------

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [
                            const Text(
                              "Total Amount",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              "₹$total",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ------------------------------------------
                        // PAYMENT
                        // ------------------------------------------

                        Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),

                            const SizedBox(width: 7),

                            Text(
                              "Payment: Cash at pickup",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // ------------------------------------------
                        // PLACE ORDER BUTTON
                        // ------------------------------------------

                        SizedBox(
                          width: double.infinity,
                          height: 55,

                          child: ElevatedButton(
                            onPressed:
                                isLoading ? null : placeOrder,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,

                              disabledBackgroundColor:
                                  Colors.orange.shade200,

                              elevation: 2,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                            ),

                            child: isLoading
                                ? const SizedBox(
                                    height: 25,
                                    width: 25,

                                    child:
                                        CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "PLACE ORDER",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // EMPTY CART
  // ============================================================

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              height: 110,
              width: 110,

              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Colors.orange.shade300,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Your cart is empty",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Add some delicious food from the stall.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },

              icon: const Icon(Icons.arrow_back),

              label: const Text("BACK TO MENU"),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ORDER SUCCESS SCREEN
// ============================================================

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  final String orderNumber;
  final int total;
  final String stallName;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.total,
    required this.stallName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    // =================================================
                    // SUCCESS ICON
                    // =================================================

                    Container(
                      height: 100,
                      width: 100,

                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 70,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =================================================
                    // SUCCESS TITLE
                    // =================================================

                    const Text(
                      "Order Placed Successfully!",
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Your food order has been sent to $stallName.",
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =================================================
                    // ORDER DETAILS CARD
                    // =================================================

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(20),

                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [
                          _detailRow(
                            "Order Number",
                            orderNumber,
                          ),

                          const Divider(height: 25),

                          _detailRow(
                            "Stall",
                            stallName,
                          ),

                          const Divider(height: 25),

                          _detailRow(
                            "Total",
                            "₹$total",
                          ),

                          const Divider(height: 25),

                          _detailRow(
                            "Payment",
                            "Cash at Pickup",
                          ),

                          const Divider(height: 25),

                          _detailRow(
                            "Status",
                            "PREPARING",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // INFORMATION
                    // =================================================

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),

                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              "Your order is being prepared. "
                              "The stall will notify you when "
                              "your food is ready.",
                              style: TextStyle(
                                color:
                                    Colors.grey.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =================================================
                    // TRACK ORDER
                    // =================================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderStatusScreen(
                                orderId: orderId,
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =================================================
                    // BACK TO HOME
                    // =================================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const HomeScreen(),
                            ),
                            (route) => false,
                          );
                        },

                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,

                          side: const BorderSide(
                            color: Colors.orange,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),

                        child: const Text(
                          "BACK TO HOME",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  static Widget _detailRow(
    String title,
    String value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),

        const SizedBox(width: 15),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
