import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'menu_screen.dart';

class StallsScreen extends StatefulWidget {
  const StallsScreen({super.key});

  @override
  State<StallsScreen> createState() => _StallsScreenState();
}

class _StallsScreenState extends State<StallsScreen> {
  static const Color primaryOrange = Color(0xFFE69A2D);
  static const Color darkNavy = Color(0xFF17324D);
  static const Color background = Color(0xFFF7F8FA);
  static const Color textGrey = Color(0xFF747B84);

  String searchQuery = '';

  // ============================================================
  // OPEN STALL MENU
  // ============================================================

  void openStall({
    required BuildContext context,
    required String stallId,
    required String stallName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(
          stallId: stallId,
          stallName: stallName,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("stalls")
              .where("active", isEqualTo: true)
              .snapshots(),

          builder: (context, snapshot) {
            // ======================================================
            // LOADING
            // ======================================================

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryOrange,
                  strokeWidth: 3,
                ),
              );
            }

            // ======================================================
            // ERROR
            // ======================================================

            if (snapshot.hasError) {
              return _errorView(
                context,
                snapshot.error.toString(),
              );
            }

            // ======================================================
            // GET STALLS
            // ======================================================

            final allStalls =
                snapshot.data?.docs ?? [];

            // ======================================================
            // SEARCH FILTER
            // ======================================================

            final stalls = allStalls.where((stall) {
              final data =
                  stall.data() as Map<String, dynamic>;

              final name =
                  data["name"]?.toString().toLowerCase() ?? "";

              final location =
                  data["location"]?.toString().toLowerCase() ?? "";

              final query =
                  searchQuery.toLowerCase().trim();

              if (query.isEmpty) {
                return true;
              }

              return name.contains(query) ||
                  location.contains(query);
            }).toList();

            // ======================================================
            // MAIN CONTENT
            // ======================================================

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                30,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1000,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      // ==================================================
                      // HEADER
                      // ==================================================

                      Row(
                        children: [

                          // BACK BUTTON
                          Container(
                            width: 44,
                            height: 44,

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(13),

                              border: Border.all(
                                color:
                                    Colors.grey.shade200,
                              ),
                            ),

                            child: IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },

                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: darkNavy,
                                size: 21,
                              ),
                            ),
                          ),

                          const SizedBox(width: 13),

                          // TITLE
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                Text(
                                  "Campus Stalls",
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight:
                                        FontWeight.w800,
                                    color: darkNavy,
                                  ),
                                ),

                                SizedBox(height: 3),

                                Text(
                                  "Choose where you want to order",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // STORE ICON
                          Container(
                            width: 44,
                            height: 44,

                            decoration: BoxDecoration(
                              color:
                                  primaryOrange
                                      .withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.storefront_rounded,
                              color: primaryOrange,
                              size: 22,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // ==================================================
                      // WELCOME CARD
                      // ==================================================

                      Container(
                        width: double.infinity,

                        padding:
                            const EdgeInsets.all(20),

                        decoration: BoxDecoration(
                          gradient:
                              const LinearGradient(
                            colors: [
                              darkNavy,
                              Color(0xFF274866),
                            ],

                            begin:
                                Alignment.topLeft,

                            end:
                                Alignment.bottomRight,
                          ),

                          borderRadius:
                              BorderRadius.circular(22),

                          boxShadow: [
                            BoxShadow(
                              color:
                                  darkNavy
                                      .withOpacity(0.15),
                              blurRadius: 18,
                              offset:
                                  const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [

                            Container(
                              width: 58,
                              height: 58,

                              decoration:
                                  BoxDecoration(
                                color:
                                    primaryOrange,
                                borderRadius:
                                    BorderRadius
                                        .circular(17),
                              ),

                              child: const Icon(
                                Icons.restaurant_rounded,
                                color: Colors.white,
                                size: 29,
                              ),
                            ),

                            const SizedBox(width: 15),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Text(
                                    "Hungry?",
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),

                                  SizedBox(height: 4),

                                  Text(
                                    "Explore all the food stalls on your campus and order without waiting in line.",
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.white70,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // SEARCH
                      // ==================================================

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(16),

                          border: Border.all(
                            color:
                                Colors.grey.shade200,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black
                                      .withOpacity(
                                          0.035),
                              blurRadius: 12,
                              offset:
                                  const Offset(0, 4),
                            ),
                          ],
                        ),

                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },

                          decoration:
                              InputDecoration(
                            hintText:
                                "Search stalls or locations",

                            hintStyle:
                                const TextStyle(
                              color:
                                  Color(0xFF9AA0A8),
                              fontSize: 13,
                            ),

                            prefixIcon:
                                const Icon(
                              Icons.search_rounded,
                              color:
                                  Color(0xFF7D858E),
                            ),

                            suffixIcon:
                                searchQuery
                                        .isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
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
                                            .tune_rounded,
                                        color:
                                            primaryOrange,
                                        size: 21,
                                      ),

                            filled: true,
                            fillColor:
                                Colors.white,

                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(16),
                              borderSide:
                                  BorderSide.none,
                            ),

                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(16),
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
                                      .circular(16),
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

                      const SizedBox(height: 27),

                      // ==================================================
                      // SECTION HEADER
                      // ==================================================

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
                                "Available Stalls",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                  color:
                                      darkNavy,
                                ),
                              ),

                              SizedBox(height: 4),

                              Text(
                                "Tap a stall to view its menu",
                                style: TextStyle(
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
                              horizontal: 12,
                              vertical: 8,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  primaryOrange
                                      .withOpacity(
                                          0.10),
                              borderRadius:
                                  BorderRadius
                                      .circular(12),
                            ),

                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min,

                              children: [

                                const Icon(
                                  Icons
                                      .storefront_rounded,
                                  size: 16,
                                  color:
                                      primaryOrange,
                                ),

                                const SizedBox(
                                  width: 6,
                                ),

                                Text(
                                  "${allStalls.length}",
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    color:
                                        primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 17),

                      // ==================================================
                      // NO STALLS
                      // ==================================================

                      if (allStalls.isEmpty)
                        _emptyView()

                      // ==================================================
                      // NO SEARCH RESULTS
                      // ==================================================

                      else if (stalls.isEmpty)
                        _noSearchResults()

                      // ==================================================
                      // STALL GRID / LIST
                      // ==================================================

                      else
                        LayoutBuilder(
                          builder:
                              (context, constraints) {
                            final isWide =
                                constraints.maxWidth >=
                                    700;

                            if (isWide) {
                              return GridView.builder(
                                shrinkWrap: true,

                                physics:
                                    const NeverScrollableScrollPhysics(),

                                itemCount:
                                    stalls.length,

                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio:
                                      1.65,
                                ),

                                itemBuilder:
                                    (context, index) {
                                  return _buildStallCard(
                                    context,
                                    stalls[index],
                                    index,
                                  );
                                },
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,

                              physics:
                                  const NeverScrollableScrollPhysics(),

                              itemCount:
                                  stalls.length,

                              itemBuilder:
                                  (context, index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets
                                          .only(
                                    bottom: 14,
                                  ),

                                  child:
                                      _buildStallCard(
                                    context,
                                    stalls[index],
                                    index,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // STALL CARD
  // ============================================================

  Widget _buildStallCard(
    BuildContext context,
    QueryDocumentSnapshot stall,
    int index,
  ) {
    final data =
        stall.data() as Map<String, dynamic>;

    final String stallId = stall.id;

    final String stallName =
        data["name"]?.toString() ??
            "Food Stall";

    final String location =
        data["location"]?.toString() ??
            "Campus";

    final bool active =
        data["active"] == true;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: active
            ? () {
                openStall(
                  context: context,
                  stallId: stallId,
                  stallName: stallName,
                );
              }
            : null,

        borderRadius:
            BorderRadius.circular(22),

        child: Container(
          padding: const EdgeInsets.all(17),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(22),

            border: Border.all(
              color: Colors.grey.shade200,
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.045),
                blurRadius: 15,
                offset:
                    const Offset(0, 6),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ========================================================
              // TOP ROW
              // ========================================================

              Row(
                children: [

                  // STALL ICON
                  Container(
                    width: 62,
                    height: 62,

                    decoration: BoxDecoration(
                      gradient:
                          LinearGradient(
                        colors: [
                          primaryOrange
                              .withOpacity(0.16),
                          primaryOrange
                              .withOpacity(0.07),
                        ],

                        begin:
                            Alignment.topLeft,

                        end:
                            Alignment.bottomRight,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),

                    child: Icon(
                      _getStallIcon(
                        stallName,
                        index,
                      ),

                      color:
                          primaryOrange,

                      size: 31,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // NAME + LOCATION
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Text(
                          stallName,

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .w800,
                            color:
                                darkNavy,
                          ),
                        ),

                        const SizedBox(
                          height: 7,
                        ),

                        Row(
                          children: [

                            const Icon(
                              Icons
                                  .location_on_outlined,
                              size: 15,
                              color:
                                  textGrey,
                            ),

                            const SizedBox(
                              width: 4,
                            ),

                            Expanded(
                              child: Text(
                                location,

                                maxLines: 1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color:
                                      textGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ========================================================
              // DIVIDER
              // ========================================================

              Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),

              const SizedBox(height: 13),

              // ========================================================
              // BOTTOM ROW
              // ========================================================

              Row(
                children: [

                  // OPEN / CLOSED
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),

                    decoration:
                        BoxDecoration(
                      color: active
                          ? const Color(
                              0xFFEAF8EF)
                          : const Color(
                              0xFFFFEEEE),

                      borderRadius:
                          BorderRadius.circular(
                              9),
                    ),

                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [

                        Container(
                          width: 7,
                          height: 7,

                          decoration:
                              BoxDecoration(
                            color: active
                                ? const Color(
                                    0xFF2E9B57)
                                : const Color(
                                    0xFFD9534F),
                            shape:
                                BoxShape.circle,
                          ),
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Text(
                          active
                              ? "Open"
                              : "Closed",

                          style:
                              TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w700,
                            color: active
                                ? const Color(
                                    0xFF27824A)
                                : const Color(
                                    0xFFC13F3A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // VIEW MENU
                  if (active)
                    const Row(
                      children: [

                        Text(
                          "View Menu",
                          style:
                              TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w800,
                            color:
                                primaryOrange,
                          ),
                        ),

                        SizedBox(
                          width: 5,
                        ),

                        Icon(
                          Icons
                              .arrow_forward_rounded,
                          size: 18,
                          color:
                              primaryOrange,
                        ),
                      ],
                    )
                  else
                    const Text(
                      "Currently unavailable",
                      style: TextStyle(
                        fontSize: 11,
                        color: textGrey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STALL ICON
  // ============================================================

  IconData _getStallIcon(
    String stallName,
    int index,
  ) {
    final name =
        stallName.toLowerCase();

    if (name.contains("cafe") ||
        name.contains("coffee")) {
      return Icons.local_cafe_rounded;
    }

    if (name.contains("juice") ||
        name.contains("drink")) {
      return Icons.local_drink_rounded;
    }

    if (name.contains("bakery") ||
        name.contains("cake")) {
      return Icons.bakery_dining_rounded;
    }

    if (name.contains("canteen")) {
      return Icons.restaurant_rounded;
    }

    if (name.contains("snack")) {
      return Icons.fastfood_rounded;
    }

    final icons = [
      Icons.storefront_rounded,
      Icons.restaurant_rounded,
      Icons.fastfood_rounded,
      Icons.local_cafe_rounded,
      Icons.bakery_dining_rounded,
    ];

    return icons[index % icons.length];
  }

  // ============================================================
  // EMPTY STALLS
  // ============================================================

  Widget _emptyView() {
    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(top: 15),

      padding:
          const EdgeInsets.all(35),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: [

          Container(
            width: 90,
            height: 90,

            decoration: BoxDecoration(
              color:
                  primaryOrange.withOpacity(0.10),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.storefront_outlined,
              size: 45,
              color: primaryOrange,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "No stalls available",
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.w800,
              color: darkNavy,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            "There are currently no active food stalls on campus.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO SEARCH RESULTS
  // ============================================================

  Widget _noSearchResults() {
    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(top: 15),

      padding:
          const EdgeInsets.all(35),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: [

          const Icon(
            Icons.search_off_rounded,
            size: 55,
            color: Color(0xFF9AA0A8),
          ),

          const SizedBox(height: 16),

          const Text(
            "No stalls found",
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
              color: darkNavy,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'No stall matches "$searchQuery".',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: textGrey,
            ),
          ),

          const SizedBox(height: 15),

          TextButton(
            onPressed: () {
              setState(() {
                searchQuery = '';
              });
            },

            child: const Text(
              "Clear Search",
              style: TextStyle(
                color: primaryOrange,
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

  Widget _errorView(
    BuildContext context,
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 90,
              height: 90,

              decoration: BoxDecoration(
                color:
                    Colors.red.shade50,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 45,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Unable to load stalls",
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
                color: darkNavy,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Please check your connection and try again.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: textGrey,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label: const Text(
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