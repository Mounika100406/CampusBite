import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FoodManagementScreen extends StatefulWidget {
  const FoodManagementScreen({super.key});

  @override
  State<FoodManagementScreen> createState() =>
      _FoodManagementScreenState();
}

class _FoodManagementScreenState extends State<FoodManagementScreen> {
  final CollectionReference foodCollection =
      FirebaseFirestore.instance.collection('foodItems');

  String? staffStallId;
  String staffStallName = "My Stall";
  bool loadingStaff = true;

  // ============================================================
  // FIXED FOOD IMAGES
  // ============================================================

  final List<String> foodImages = [
    'assets/images/pizza.png',
    'assets/images/burger.png',
    'assets/images/sandwich.jpg',
    'assets/images/fries.jpeg',
    'assets/images/samosa.jpeg',
    'assets/images/tea.jpg',
  ];

  // ============================================================
  // INIT
  // ============================================================

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
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            loadingStaff = false;
          });
        }
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("staff")
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        if (mounted) {
          setState(() {
            loadingStaff = false;
          });
        }
        return;
      }

      final data = doc.data();

      final String? stallId = data?["stallId"]?.toString();

      if (stallId == null || stallId.isEmpty) {
        if (mounted) {
          setState(() {
            loadingStaff = false;
          });
        }
        return;
      }

      String stallName = "My Stall";

      final stallDoc = await FirebaseFirestore.instance
          .collection("stalls")
          .doc(stallId)
          .get();

      if (stallDoc.exists) {
        stallName =
            stallDoc.data()?["name"]?.toString() ?? "My Stall";
      }

      if (!mounted) return;

      setState(() {
        staffStallId = stallId;
        staffStallName = stallName;
        loadingStaff = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingStaff = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to load stall details:\n$e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // ADD FOOD
  // ============================================================

  Future<void> addFood() async {
    if (staffStallId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Your account is not assigned to a stall.",
          ),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodFormScreen(
          foodImages: foodImages,
          stallId: staffStallId!,
          stallName: staffStallName,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // EDIT FOOD
  // ============================================================

  Future<void> editFood(
    String foodId,
    Map<String, dynamic> data,
  ) async {
    if (staffStallId == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodFormScreen(
          foodImages: foodImages,
          stallId: staffStallId!,
          stallName: staffStallName,
          foodId: foodId,
          existingData: data,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // DELETE FOOD
  // ============================================================

  Future<void> deleteFood(
    String foodId,
    String foodName,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Food',
          ),
          content: Text(
            'Are you sure you want to delete "$foodName"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await foodCollection.doc(foodId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Food deleted successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Failed to delete food:\n$e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // TOGGLE AVAILABILITY
  // ============================================================

  Future<void> toggleAvailability(
    String foodId,
    bool currentValue,
  ) async {
    try {
      await foodCollection.doc(foodId).update({
        'available': !currentValue,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            !currentValue
                ? 'Food is now available'
                : 'Food is now unavailable',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Failed to update availability:\n$e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // IMAGE DISPLAY
  // ============================================================

  Widget buildFoodImage(String imagePath) {
    if (imagePath.trim().isEmpty) {
      return Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.fastfood,
          size: 45,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.asset(
        imagePath,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.broken_image,
              size: 40,
              color: Colors.grey,
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
      appBar: AppBar(
        title: const Text(
          'Food Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: staffStallId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: addFood,
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Food',
              ),
            ),

      body: loadingStaff
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : staffStallId == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.store_mall_directory,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "No Stall Assigned",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Your staff account has not been assigned to a stall yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // ==================================================
                    // STALL HEADER
                    // ==================================================

                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        5,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor:
                                Colors.orange.shade800,
                            child: const Icon(
                              Icons.store,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Managing Stall",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  staffStallName,
                                  style: const TextStyle(
                                    fontSize: 19,
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

                    // ==================================================
                    // FOOD LIST
                    // ==================================================

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: foodCollection
                            .where(
                              'stallId',
                              isEqualTo: staffStallId,
                            )
                            .snapshots(),

                        builder: (
                          context,
                          snapshot,
                        ) {
                          // LOADING

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(),
                            );
                          }

                          // ERROR

                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(
                                  20,
                                ),
                                child: Text(
                                  'Error loading food items:\n\n'
                                  '${snapshot.error}',
                                  textAlign:
                                      TextAlign.center,
                                  style:
                                      const TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            );
                          }

                          // EMPTY

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.restaurant_menu,
                                    size: 75,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  const Text(
                                    'No food items available',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  const Text(
                                    'Tap "Add Food" to add a food item.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final foodItems =
                              snapshot.data!.docs;

                          return ListView.builder(
                            padding:
                                const EdgeInsets.all(16),
                            itemCount:
                                foodItems.length,
                            itemBuilder:
                                (context, index) {
                              final doc =
                                  foodItems[index];

                              final String foodId =
                                  doc.id;

                              final Map<String, dynamic>
                                  data =
                                  doc.data()
                                      as Map<String,
                                          dynamic>;

                              final String name =
                                  data['name']
                                          ?.toString() ??
                                      'Unnamed Food';

                              final String description =
                                  data['description']
                                          ?.toString() ??
                                      '';

                              final double price =
                                  data['price'] is num
                                      ? (data['price']
                                              as num)
                                          .toDouble()
                                      : double.tryParse(
                                            data['price']
                                                    ?.toString() ??
                                                '0',
                                          ) ??
                                          0;

                              final bool available =
                                  data['available'] ==
                                      true;

                              final String imagePath =
                                  data['image']
                                          ?.toString() ??
                                      '';

                              return Card(
                                margin:
                                    const EdgeInsets.only(
                                  bottom: 16,
                                ),
                                elevation: 4,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
                                  ),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(
                                    14,
                                  ),
                                  child: Column(
                                    children: [
                                      // FOOD INFORMATION

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          buildFoodImage(
                                            imagePath,
                                          ),

                                          const SizedBox(
                                            width: 15,
                                          ),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  name,
                                                  style:
                                                      const TextStyle(
                                                    fontSize:
                                                        20,
                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                  ),
                                                ),

                                                const SizedBox(
                                                  height: 7,
                                                ),

                                                if (description
                                                    .isNotEmpty)
                                                  Text(
                                                    description,
                                                    style:
                                                        TextStyle(
                                                      color: Colors
                                                          .grey
                                                          .shade700,
                                                      fontSize:
                                                          15,
                                                    ),
                                                  ),

                                                const SizedBox(
                                                  height: 8,
                                                ),

                                                Text(
                                                  '₹${price.toStringAsFixed(0)}',
                                                  style:
                                                      TextStyle(
                                                    fontSize:
                                                        20,
                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                    color: Colors
                                                        .orange
                                                        .shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 10,
                                      ),

                                      const Divider(),

                                      // ACTIONS

                                      Row(
                                        children: [
                                          Switch(
                                            value:
                                                available,
                                            activeColor:
                                                Colors.green,
                                            onChanged:
                                                (value) {
                                              toggleAvailability(
                                                foodId,
                                                available,
                                              );
                                            },
                                          ),

                                          Text(
                                            available
                                                ? 'Available'
                                                : 'Unavailable',
                                            style:
                                                TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight
                                                      .w500,
                                              color: available
                                                  ? Colors
                                                      .green
                                                  : Colors.red,
                                            ),
                                          ),

                                          const Spacer(),

                                          IconButton(
                                            tooltip: 'Edit',
                                            icon:
                                                const Icon(
                                              Icons.edit,
                                              color:
                                                  Colors.blue,
                                            ),
                                            onPressed: () {
                                              editFood(
                                                foodId,
                                                data,
                                              );
                                            },
                                          ),

                                          IconButton(
                                            tooltip: 'Delete',
                                            icon:
                                                const Icon(
                                              Icons.delete,
                                              color:
                                                  Colors.red,
                                            ),
                                            onPressed: () {
                                              deleteFood(
                                                foodId,
                                                name,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ============================================================================
// FOOD FORM SCREEN
// ============================================================================

class FoodFormScreen extends StatefulWidget {
  final List<String> foodImages;

  final String stallId;
  final String stallName;

  final String? foodId;

  final Map<String, dynamic>? existingData;

  const FoodFormScreen({
    super.key,
    required this.foodImages,
    required this.stallId,
    required this.stallName,
    this.foodId,
    this.existingData,
  });

  bool get isEditing => foodId != null;

  @override
  State<FoodFormScreen> createState() =>
      _FoodFormScreenState();
}

class _FoodFormScreenState
    extends State<FoodFormScreen> {
  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  final TextEditingController priceController =
      TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  String? selectedImage;

  bool available = true;

  bool isSaving = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      final data = widget.existingData!;

      nameController.text =
          data['name']?.toString() ?? '';

      descriptionController.text =
          data['description']?.toString() ?? '';

      priceController.text =
          data['price']?.toString() ?? '';

      final String existingImage =
          data['image']?.toString() ?? '';

      if (existingImage.isNotEmpty) {
        selectedImage = existingImage;
      }

      available = data['available'] == true;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE FOOD
  // ============================================================

  Future<void> saveFood() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Please select a food image',
          ),
        ),
      );

      return;
    }

    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final String name =
          nameController.text.trim();

      final String description =
          descriptionController.text.trim();

      final double price =
          double.parse(
        priceController.text.trim(),
      );

      // ========================================================
      // EDIT
      // ========================================================

      if (widget.isEditing) {
        await FirebaseFirestore.instance
            .collection('foodItems')
            .doc(widget.foodId)
            .update({
          'name': name,
          'description': description,
          'price': price,
          'image': selectedImage,
          'available': available,

          // IMPORTANT:
          // Keep food assigned to this staff member's stall.
          'stallId': widget.stallId,
        });
      }

      // ========================================================
      // ADD
      // ========================================================

      else {
        await FirebaseFirestore.instance
            .collection('foodItems')
            .add({
          'name': name,
          'description': description,
          'price': price,
          'image': selectedImage,
          'available': available,

          // IMPORTANT:
          // New food belongs to the current staff's stall.
          'stallId': widget.stallId,

          'createdAt':
              FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            widget.isEditing
                ? 'Food updated successfully'
                : 'Food added successfully',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration:
              const Duration(seconds: 8),
          content: Text(
            'Failed to save food:\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // IMAGE CARD
  // ============================================================

  Widget buildSelectedImage() {
    if (selectedImage == null) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade400,
          ),
        ),
        child: const Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 65,
              color: Colors.grey,
            ),
            SizedBox(height: 10),
            Text(
              'Select a food image',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(16),
      child: Image.asset(
        selectedImage!,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            width: double.infinity,
            height: 220,
            color: Colors.grey.shade200,
            child: const Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 55,
                  color: Colors.grey,
                ),
                SizedBox(height: 10),
                Text(
                  'Image not found',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // IMAGE SELECTION
  // ============================================================

  Future<void> selectImage() async {
    final String? result =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Food Image',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                GridView.builder(
                  shrinkWrap: true,
                  itemCount:
                      widget.foodImages.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder:
                      (context, index) {
                    final String image =
                        widget.foodImages[index];

                    return InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      onTap: () {
                        Navigator.pop(
                          context,
                          image,
                        );
                      },
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        child: Image.asset(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Container(
                              color: Colors
                                  .grey
                                  .shade200,
                              child:
                                  const Icon(
                                Icons
                                    .broken_image,
                                color:
                                    Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedImage = result;
      });
    }
  }

  // ============================================================
  // BUILD FORM
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Edit Food'
              : 'Add Food',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 700,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding:
                  const EdgeInsets.all(20),
              children: [
                // =================================================
                // STALL
                // =================================================

                Container(
                  padding:
                      const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color:
                        Colors.orange.shade50,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.store,
                        color: Colors
                            .orange
                            .shade800,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              "Stall",
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              widget.stallName,
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight
                                        .bold,
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

                // =================================================
                // IMAGE
                // =================================================

                const Text(
                  'Food Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                buildSelectedImage(),

                const SizedBox(
                  height: 12,
                ),

                SizedBox(
                  height: 52,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        isSaving
                            ? null
                            : selectImage,
                    icon: const Icon(
                      Icons.photo_library,
                    ),
                    label: Text(
                      selectedImage == null
                          ? 'SELECT FOOD IMAGE'
                          : 'CHANGE IMAGE',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // =================================================
                // FOOD NAME
                // =================================================

                TextFormField(
                  controller:
                      nameController,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      InputDecoration(
                    labelText:
                        'Food Name',
                    hintText:
                        'Example: Pizza',
                    prefixIcon:
                        const Icon(
                      Icons.fastfood,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter food name';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 18,
                ),

                // =================================================
                // DESCRIPTION
                // =================================================

                TextFormField(
                  controller:
                      descriptionController,
                  maxLines: 3,
                  decoration:
                      InputDecoration(
                    labelText:
                        'Description',
                    hintText:
                        'Example: Fresh cheese pizza',
                    prefixIcon:
                        const Icon(
                      Icons.description,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter description';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 18,
                ),

                // =================================================
                // PRICE
                // =================================================

                TextFormField(
                  controller:
                      priceController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      InputDecoration(
                    labelText:
                        'Price',
                    hintText:
                        'Example: 200',
                    prefixIcon:
                        const Icon(
                      Icons.currency_rupee,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter price';
                    }

                    final double? price =
                        double.tryParse(
                      value.trim(),
                    );

                    if (price == null) {
                      return 'Please enter a valid price';
                    }

                    if (price < 0) {
                      return 'Price cannot be negative';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 18,
                ),

                // =================================================
                // AVAILABILITY
                // =================================================

                Card(
                  elevation: 0,
                  color:
                      Colors.grey.shade100,
                  child:
                      SwitchListTile(
                    value: available,
                    activeColor:
                        Colors.green,
                    title: const Text(
                      'Food Available',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      available
                          ? 'Students can order this food'
                          : 'Students cannot order this food',
                    ),
                    secondary: Icon(
                      available
                          ? Icons
                              .check_circle
                          : Icons.cancel,
                      color: available
                          ? Colors.green
                          : Colors.red,
                    ),
                    onChanged:
                        isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  available =
                                      value;
                                });
                              },
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // =================================================
                // SAVE BUTTON
                // =================================================

                SizedBox(
                  height: 55,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        isSaving
                            ? null
                            : saveFood,
                    icon: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save,
                          ),
                    label: Text(
                      isSaving
                          ? 'SAVING...'
                          : widget.isEditing
                              ? 'UPDATE FOOD'
                              : 'ADD FOOD',
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          Colors
                              .orange
                              .shade800,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
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
        ),
      ),
    );
  }
}
