import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_status_screen.dart';

class OrderScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final int total;

  const OrderScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.total,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {

  bool isLoading = true;
  String status = "PREPARING";

  @override
  void initState() {
    super.initState();

    getOrderStatus();
  }

  // --------------------------------------------------
  // GET ORDER STATUS FROM FIRESTORE
  // --------------------------------------------------

  Future<void> getOrderStatus() async {

    try {

      DocumentSnapshot document =
          await FirebaseFirestore.instance
              .collection("orders")
              .doc(widget.orderId)
              .get();

      if (document.exists) {

        Map<String, dynamic> data =
            document.data()
                as Map<String, dynamic>;

        if (mounted) {

          setState(() {

            status =
                data["status"] ?? "PREPARING";

            isLoading = false;
          });
        }

      } else {

        if (mounted) {

          setState(() {
            isLoading = false;
          });
        }
      }

    } catch (e) {

      if (mounted) {

        setState(() {
          isLoading = false;
        });

        showMessage(
          "Unable to load order",
        );
      }
    }
  }

  // --------------------------------------------------
  // TRACK ORDER
  // --------------------------------------------------

  void trackOrder() {

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) =>
            OrderStatusScreen(
          orderNumber:
              int.tryParse(widget.orderNumber) ?? 0,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SNACKBAR
  // --------------------------------------------------

  void showMessage(String message) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Order Confirmed",

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          children: [

            const SizedBox(
              height: 30,
            ),

            // ----------------------------------------
            // SUCCESS ICON
            // ----------------------------------------

            Container(

              padding:
                  const EdgeInsets.all(25),

              decoration:
                  BoxDecoration(

                color:
                    Colors.green.shade50,

                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(

                Icons.check,

                size: 70,

                color:
                    Colors.green,
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            const Text(

              "Order Placed! 🎉",

              style:
                  TextStyle(
                fontSize: 28,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(

              "Your order has been sent to the food stall.",

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    Colors.grey,

                fontSize:
                    15,
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ----------------------------------------
            // ORDER DETAILS
            // ----------------------------------------

            Container(

              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(25),

              decoration:
                  BoxDecoration(

                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  22,
                ),

                boxShadow: [

                  BoxShadow(
                    color:
                        Colors.black
                            .withOpacity(
                      0.05,
                    ),

                    blurRadius:
                        10,
                  ),
                ],
              ),

              child:
                  Column(

                children: [

                  const Text(

                    "ORDER NUMBER",

                    style:
                        TextStyle(
                      color:
                          Colors.grey,

                      letterSpacing:
                          1,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(

                    "#${widget.orderNumber}",

                    style:
                        const TextStyle(
                      fontSize:
                          38,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          Colors.deepOrange,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Divider(),

                  const SizedBox(
                    height: 15,
                  ),

                  // TOTAL
                  Row(

                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [

                      const Text(

                        "Total Amount",

                        style:
                            TextStyle(
                          fontSize:
                              16,
                        ),
                      ),

                      Text(

                        "₹${widget.total}",

                        style:
                            const TextStyle(
                          fontSize:
                              20,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // PAYMENT
                  Container(

                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets.all(
                      12,
                    ),

                    decoration:
                        BoxDecoration(

                      color:
                          Colors.green.shade50,

                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),

                    child:
                        const Row(

                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [

                        Icon(
                          Icons.payments,

                          color:
                              Colors.green,
                        ),

                        SizedBox(
                          width:
                              10,
                        ),

                        Text(

                          "Pay cash when you collect",

                          style:
                              TextStyle(
                            color:
                                Colors.green,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ----------------------------------------
            // ORDER STATUS
            // ----------------------------------------

            Container(

              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                18,
              ),

              decoration:
                  BoxDecoration(

                color:
                    status == "READY"
                        ? Colors.green.shade50
                        : Colors.orange.shade50,

                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),

              child:
                  Column(

                children: [

                  Icon(

                    status == "READY"
                        ? Icons.check_circle
                        : Icons.restaurant,

                    size:
                        45,

                    color:
                        status == "READY"
                            ? Colors.green
                            : Colors.deepOrange,
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(

                    status == "READY"
                        ? "Your food is READY! 🎉"
                        : "Your food is being prepared",

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontSize:
                          17,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          status == "READY"
                              ? Colors.green
                              : Colors.deepOrange,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(

                    status == "READY"
                        ? "Please collect your order from the stall."
                        : "Please wait while the stall prepares your order.",

                    textAlign:
                        TextAlign.center,

                    style:
                        const TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ----------------------------------------
            // TRACK ORDER
            // ----------------------------------------

            SizedBox(

              width:
                  double.infinity,

              height:
                  55,

              child:
                  ElevatedButton(

                onPressed:
                    isLoading
                        ? null
                        : trackOrder,

                style:
                    ElevatedButton.styleFrom(

                  backgroundColor:
                      Colors.deepOrange,

                  foregroundColor:
                      Colors.white,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                child:
                    isLoading

                        ? const SizedBox(

                            width:
                                25,

                            height:
                                25,

                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,

                              strokeWidth:
                                  3,
                            ),
                          )

                        : const Text(

                            "TRACK MY ORDER",

                            style:
                                TextStyle(
                              fontSize:
                                  17,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
