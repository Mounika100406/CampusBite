import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final String stallId;
  final String stallName;

  const MenuScreen({
    super.key,
    required this.stallId,
    required this.stallName,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const Color primaryOrange = Color(0xFFE69A2D);
  static const Color darkNavy = Color(0xFF17324D);
  static const Color background = Color(0xFFF7F8FA);
  static const Color textGrey = Color(0xFF747B84);

  final Map<String, int> quantities = {};

  String searchQuery = '';

  // ============================================================
  // GET FOOD IMAGE
  // ============================================================

  String getImagePath(String? image, String foodName) {
    if (image != null && image.isNotEmpty) {
      return image;
    }

    final name = foodName.toLowerCase();

    if (name.contains("pizza")) {
      return "assets/images/pizza.png";
    }

    if (name.contains("burger")) {
      return "assets/images/burger.png";
    }

    if (name.contains("sandwich")) {
      return "assets/images/sandwich.jpg";
    }

    if (name.contains("fries")) {
      return "assets/images/fries.jpeg";
    }

    if (name.contains("samosa")) {
      return "assets/images/samosa.jpeg";
    }

    if (name.contains("tea")) {
      return "assets/images/tea.jpg";
    }

    return "assets/images/burger.png";
  }

  // ============================================================
  // INCREASE QUANTITY
  // ============================================================

  void increaseQuantity(String id) {
    setState(() {
      quantities[id] = (quantities[id] ?? 0) + 1;
    });
  }

  // ============================================================
  // DECREASE QUANTITY
  // ============================================================

  void decreaseQuantity(String id) {
    setState(() {
      if ((quantities[id] ?? 0) > 0) {
        quantities[id] = quantities[id]! - 1;
      }
    });
  }

  // ============================================================
  // OPEN CART
  // ============================================================

  void openCart(List<QueryDocumentSnapshot> foods) {
    final selectedFoods = <Map<String, dynamic>>[];

    for (final food in foods) {
      final id = food.id;
      final quantity = quantities[id] ?? 0;

      if (quantity > 0) {
        final data =
            food.data() as Map<String, dynamic>;

        selectedFoods.add({
          "id": id,
          "name": data["name"] ?? "Food",
          "price": data["price"] ?? 0,
          "quantity": quantity,
          "image": getImagePath(
            data["image"]?.toString(),
            data["name"]?.toString() ?? "",
          ),
        });
      }
    }

    // ==========================================================
    // EMPTY CART
    // ==========================================================

    if (selectedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Text(
                "Please select at least one food item.",
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: darkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // OPEN CART
    // ==========================================================

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cart: selectedFoods,
          stallId: widget.stallId,
          stallName: widget.stallName,
        ),
      ),
    );
  }

  // ============================================================
  // TOTAL CART COUNT
  // ============================================================

  int getCartCount() {
    int count = 0;

    for (final quantity in quantities.values) {
      count += quantity;
    }

    return count;
  }

  // ============================================================
  // TOTAL CART PRICE
  // ============================================================

  double getCartTotal(
    List<QueryDocumentSnapshot> foods,
  ) {
    double total = 0;

    for (final food in foods) {
      final quantity = quantities[food.id] ?? 0;

      if (quantity > 0) {
        final data =
            food.data() as Map<String, dynamic>;

        final price =
            (data["price"] as num?)?.toDouble() ?? 0;

        total += price * quantity;
      }
    }

    return total;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },

          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              widget.stallName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                color: darkNavy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const Text(
              "CampusBite",
              style: TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),

      // ==========================================================
      // MENU
      // ==========================================================

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("foodItems")
            .where(
              "available",
              isEqualTo: true,
            )
            .where(
              "stallId",
              isEqualTo: widget.stallId,
            )
            .snapshots(),

        builder: (context, snapshot) {
          // ========================================================
          // LOADING
          // ========================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryOrange,
                strokeWidth: 3,
              ),
            );
          }

          // ========================================================
          // ERROR
          // ========================================================

          if (snapshot.hasError) {
            return _errorView(
              snapshot.error.toString(),
            );
          }

          final allFoods =
              snapshot.data?.docs ?? [];

          // ========================================================
          // SEARCH FILTER
          // ========================================================

          final foods = allFoods.where((food) {
            if (searchQuery.trim().isEmpty) {
              return true;
            }

            final data =
                food.data()
                    as Map<String, dynamic>;

            final name =
                data["name"]
                        ?.toString()
                        .toLowerCase() ??
                    "";

            final description =
                data["description"]
                        ?.toString()
                        .toLowerCase() ??
                    "";

            final query =
                searchQuery
                    .trim()
                    .toLowerCase();

            return name.contains(query) ||
                description.contains(query);
          }).toList();

          // ========================================================
          // NO FOOD
          // ========================================================

          if (allFoods.isEmpty) {
            return _emptyMenuView();
          }

          // ========================================================
          // CART INFORMATION
          // ========================================================

          final cartCount =
              getCartCount();

          final cartTotal =
              getCartTotal(foods);

          return Column(
            children: [

              // ====================================================
              // SCROLLABLE CONTENT
              // ====================================================

              Expanded(
                child: SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),

                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    20,
                  ),

                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth: 1000,
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          // ========================================
                          // STALL HERO
                          // ========================================

                          _buildStallHero(
                            allFoods.length,
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          // ========================================
                          // SEARCH
                          // ========================================

                          Container(
                            decoration:
                                BoxDecoration(
                              color: Colors.white,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          16),

                              border:
                                  Border.all(
                                color: Colors
                                    .grey
                                    .shade200,
                              ),
                            ),

                            child: TextField(
                              onChanged:
                                  (value) {
                                setState(() {
                                  searchQuery =
                                      value;
                                });
                              },

                              decoration:
                                  InputDecoration(
                                hintText:
                                    "Search food items",

                                hintStyle:
                                    const TextStyle(
                                  color:
                                      Color(
                                          0xFF9AA0A8),
                                  fontSize: 13,
                                ),

                                prefixIcon:
                                    const Icon(
                                  Icons
                                      .search_rounded,
                                  color:
                                      Color(
                                          0xFF7D858E),
                                ),

                                suffixIcon:
                                    searchQuery
                                            .isNotEmpty
                                        ? IconButton(
                                            onPressed:
                                                () {
                                              setState(() {
                                                searchQuery =
                                                    '';
                                              });
                                            },
                                            icon:
                                                const Icon(
                                              Icons
                                                  .close_rounded,
                                              color:
                                                  Color(
                                                      0xFF8A9098),
                                            ),
                                          )
                                        : const Icon(
                                            Icons
                                                .restaurant_menu_rounded,
                                            color:
                                                primaryOrange,
                                            size:
                                                20,
                                          ),

                                filled: true,
                                fillColor:
                                    Colors.white,

                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      16,
                                  vertical:
                                      16,
                                ),

                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              16),
                                  borderSide:
                                      BorderSide
                                          .none,
                                ),

                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              16),
                                  borderSide:
                                      BorderSide(
                                    color: Colors
                                        .grey
                                        .shade200,
                                  ),
                                ),

                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              16),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        primaryOrange,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 25,
                          ),

                          // ========================================
                          // MENU TITLE
                          // ========================================

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                            children: [

                              const Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Text(
                                    "Today's Menu",
                                    style:
                                        TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                      color:
                                          darkNavy,
                                    ),
                                  ),

                                  SizedBox(
                                    height: 4,
                                  ),

                                  Text(
                                    "Fresh food available now",
                                    style:
                                        TextStyle(
                                      fontSize: 12,
                                      color:
                                          textGrey,
                                    ),
                                  ),
                                ],
                              ),

                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color:
                                      primaryOrange
                                          .withOpacity(
                                              0.10),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              10),
                                ),

                                child: Text(
                                  "${foods.length} items",
                                  style:
                                      const TextStyle(
                                    color:
                                        primaryOrange,
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // ========================================
                          // SEARCH EMPTY
                          // ========================================

                          if (foods.isEmpty)
                            _noSearchResults()

                          // ========================================
                          // FOOD GRID/LIST
                          // ========================================

                          else
                            LayoutBuilder(
                              builder:
                                  (context,
                                      constraints) {
                                final isWide =
                                    constraints
                                            .maxWidth >=
                                        720;

                                if (isWide) {
                                  return GridView
                                      .builder(
                                    shrinkWrap:
                                        true,

                                    physics:
                                        const NeverScrollableScrollPhysics(),

                                    itemCount:
                                        foods.length,

                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          2,
                                      crossAxisSpacing:
                                          15,
                                      mainAxisSpacing:
                                          15,
                                      childAspectRatio:
                                          1.55,
                                    ),

                                    itemBuilder:
                                        (context,
                                            index) {
                                      return _buildFoodCard(
                                        foods[index],
                                      );
                                    },
                                  );
                                }

                                return Column(
                                  children:
                                      foods.map(
                                    (food) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                          bottom:
                                              13,
                                        ),
                                        child:
                                            _buildFoodCard(
                                          food,
                                        ),
                                      );
                                    },
                                  ).toList(),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ====================================================
              // CART BAR
              // ====================================================

              if (cartCount > 0)
                SafeArea(
                  top: false,

                  child: Container(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      16,
                      10,
                      16,
                      12,
                    ),

                    decoration:
                        BoxDecoration(
                      color: Colors.white,

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(
                                  0.10),
                          blurRadius: 18,
                          offset:
                              const Offset(
                            0,
                            -5,
                          ),
                        ),
                      ],
                    ),

                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 1000,
                        ),

                        child:
                            ElevatedButton(
                          onPressed: () =>
                              openCart(
                            allFoods,
                          ),

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                primaryOrange,

                            foregroundColor:
                                Colors.white,

                            elevation: 0,

                            minimumSize:
                                const Size(
                              double.infinity,
                              58,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          17),
                            ),
                          ),

                          child: Row(
                            children: [

                              Container(
                                width: 36,
                                height: 36,

                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .white
                                      .withOpacity(
                                          0.18),
                                  shape:
                                      BoxShape
                                          .circle,
                                ),

                                child:
                                    Center(
                                  child:
                                      Text(
                                    "$cartCount",
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                      fontSize:
                                          13,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    Text(
                                      "View Cart",
                                      style:
                                          TextStyle(
                                        fontSize:
                                            15,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                      ),
                                    ),

                                    SizedBox(
                                      height: 2,
                                    ),

                                    Text(
                                      "Review your selected items",
                                      style:
                                          TextStyle(
                                        fontSize:
                                            10,
                                        color:
                                            Colors
                                                .white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                "₹${cartTotal.toStringAsFixed(0)}",

                                style:
                                    const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),

                              const SizedBox(
                                width: 7,
                              ),

                              const Icon(
                                Icons
                                    .arrow_forward_rounded,
                                size: 21,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // STALL HERO
  // ============================================================

  Widget _buildStallHero(int itemCount) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            darkNavy,
            Color(0xFF294D6B),
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(23),

        boxShadow: [
          BoxShadow(
            color:
                darkNavy.withOpacity(0.14),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [

          Container(
            width: 65,
            height: 65,

            decoration: BoxDecoration(
              color: primaryOrange,
              borderRadius:
                  BorderRadius.circular(18),
            ),

            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  widget.stallName,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Fresh food • Order now",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 11),

                Row(
                  children: [

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),

                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(
                                0.12),
                        borderRadius:
                            BorderRadius
                                .circular(8),
                      ),

                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [

                          const Icon(
                            Icons
                                .restaurant_menu_rounded,
                            color:
                                Colors.white,
                            size: 13,
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Text(
                            "$itemCount items",

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),

                      decoration:
                          BoxDecoration(
                        color: const Color(
                            0xFF2E9B57),

                        borderRadius:
                            BorderRadius
                                .circular(8),
                      ),

                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [

                          Icon(
                            Icons
                                .check_circle_rounded,
                            color:
                                Colors.white,
                            size: 13,
                          ),

                          SizedBox(width: 4),

                          Text(
                            "Open",
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOD CARD
  // ============================================================

  Widget _buildFoodCard(
    QueryDocumentSnapshot food,
  ) {
    final data =
        food.data()
            as Map<String, dynamic>;

    final id = food.id;

    final name =
        data["name"]?.toString() ??
            "Food";

    final description =
        data["description"]?.toString() ??
            "";

    final price =
        (data["price"] as num?)
                ?.toDouble() ??
            0;

    final image = getImagePath(
      data["image"]?.toString(),
      name,
    );

    final quantity =
        quantities[id] ?? 0;

    return Container(
      padding:
          const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
                    0.035),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [

          // ========================================================
          // FOOD IMAGE
          // ========================================================

          ClipRRect(
            borderRadius:
                BorderRadius.circular(16),

            child: Image.asset(
              image,

              height: 105,
              width: 105,

              fit: BoxFit.cover,

              errorBuilder:
                  (context, error, stack) {
                return Container(
                  height: 105,
                  width: 105,

                  color:
                      const Color(
                          0xFFF0F1F3),

                  child: const Icon(
                    Icons
                        .fastfood_rounded,
                    size: 36,
                    color:
                        Color(0xFF9AA0A8),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 14),

          // ========================================================
          // FOOD DETAILS
          // ========================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Text(
                  name,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                    color: darkNavy,
                  ),
                ),

                if (description
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      top: 5,
                    ),

                    child: Text(
                      description,

                      maxLines: 2,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          const TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),

                const SizedBox(
                  height: 9,
                ),

                Text(
                  "₹${price.toStringAsFixed(0)}",

                  style:
                      const TextStyle(
                    color:
                        primaryOrange,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                // ==================================================
                // QUANTITY CONTROLS
                // ==================================================

                Container(
                  height: 37,

                  decoration:
                      BoxDecoration(
                    color:
                        quantity > 0
                            ? primaryOrange
                                .withOpacity(
                                    0.10)
                            : const Color(
                                0xFFF3F4F6),

                    borderRadius:
                        BorderRadius.circular(
                            11),

                    border: Border.all(
                      color: quantity > 0
                          ? primaryOrange
                              .withOpacity(
                                  0.25)
                          : Colors
                              .transparent,
                    ),
                  ),

                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [

                      IconButton(
                        onPressed:
                            quantity > 0
                                ? () {
                                    decreaseQuantity(
                                        id);
                                  }
                                : null,

                        padding:
                            EdgeInsets.zero,

                        constraints:
                            const BoxConstraints(
                          minWidth: 35,
                          minHeight: 35,
                        ),

                        icon: Icon(
                          Icons
                              .remove_rounded,
                          size: 18,
                          color: quantity >
                                  0
                              ? primaryOrange
                              : const Color(
                                  0xFFB4BAC1),
                        ),
                      ),

                      SizedBox(
                        width: 23,

                        child: Text(
                          "$quantity",

                          textAlign:
                              TextAlign.center,

                          style:
                              const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight
                                    .w800,
                            color: darkNavy,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          increaseQuantity(
                              id);
                        },

                        padding:
                            EdgeInsets.zero,

                        constraints:
                            const BoxConstraints(
                          minWidth: 35,
                          minHeight: 35,
                        ),

                        icon:
                            const Icon(
                          Icons
                              .add_rounded,
                          size: 19,
                          color:
                              primaryOrange,
                        ),
                      ),
                    ],
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
  // EMPTY MENU
  // ============================================================

  Widget _emptyMenuView() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 105,
              height: 105,

              decoration:
                  BoxDecoration(
                color:
                    primaryOrange
                        .withOpacity(
                            0.10),
                shape:
                    BoxShape.circle,
              ),

              child: const Icon(
                Icons
                    .restaurant_menu_rounded,
                size: 50,
                color:
                    primaryOrange,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              "No food available",
              style:
                  TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.w800,
                color: darkNavy,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              "This stall currently has no available items.\nPlease check again later.",
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 13,
                height: 1.45,
                color: textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO SEARCH RESULTS
  // ============================================================

  Widget _noSearchResults() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(35),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: [

          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color:
                Color(0xFF9AA0A8),
          ),

          const SizedBox(
            height: 15,
          ),

          const Text(
            "No food found",
            style:
                TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
              color: darkNavy,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Nothing matches "$searchQuery".',
            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 12,
              color: textGrey,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextButton(
            onPressed: () {
              setState(() {
                searchQuery = '';
              });
            },

            child:
                const Text(
              "Clear Search",
              style:
                  TextStyle(
                color:
                    primaryOrange,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _errorView(String error) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 85,
              height: 85,

              decoration:
                  BoxDecoration(
                color:
                    Colors.red.shade50,
                shape:
                    BoxShape.circle,
              ),

              child: const Icon(
                Icons.cloud_off_rounded,
                color:
                    Colors.redAccent,
                size: 42,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              "Unable to load menu",
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
                color: darkNavy,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              "Please check your connection and try again.",
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 13,
                color: textGrey,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label:
                  const Text(
                "Try Again",
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryOrange,

                foregroundColor:
                    Colors.white,

                elevation: 0,

                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                          13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}