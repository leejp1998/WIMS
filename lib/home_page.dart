import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'add_item_form.dart';
import 'edit_item_form.dart';
import 'helper/custom_search_delegate.dart';
import 'helper/database_helper.dart'; // Replace with your actual project name

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Map<String, dynamic>> items;
  List<String> categories = [];
  List<String> subcategories = [];
  List<String> selectedCategories = [];
  List<String> filterCategories = [];
  List<String> selectedSubcategories = [];

  final _longPressGestureRecognizer = LongPressGestureRecognizer();

  @override
  void initState() {
    super.initState();
    // Load items from the database when the page is initialized
    loadItems();
  }

  @override
  void dispose() {
    _longPressGestureRecognizer.dispose();
    super.dispose();
  }

  void editItemCallback() {
    loadItems();
  }

  Future<void> loadItems() async {
    items = await DatabaseHelper.instance.loadAllItems();
    setState(() {});
  }

  void _handleOnTap(Map<String, dynamic> selectedItem) {
    // Navigate to the edit page with the selected item data
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return EditItemForm(
          selectedItem: selectedItem,
          editItemCallback: editItemCallback,
        );
      },
    ).then((_) {
      // Reload items after adding a new item
      loadItems();
    });
  }

  /*
    Search Functionality
   */
  void searchItems(String searchTerm) async {
    List<Map<String, dynamic>> searchedItems =
        await DatabaseHelper.instance.searchItems(searchTerm);
    setState(() {
      items = searchedItems;
    });
  }

  /*
    Filter Functionalities
   */
  void applyFilter() {
    filterCategories = [];
    filterCategories.addAll(selectedCategories);
    if (filterCategories.isNotEmpty) {
      loadItemsWithFilterCategory(selectedCategories: filterCategories);
    } else {
      loadItems();
    }
  }

  Future<void> loadItemsWithFilterCategory(
      {required List<String> selectedCategories}) async {
    items = await DatabaseHelper.instance
        .loadItemsWithFilterCategory(selectedCategories: selectedCategories);
    setState(() {});
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return FutureBuilder<List<String>>(
            future: DatabaseHelper.instance.loadAllCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text(
                  'No results found.',
                  style: TextStyle(fontSize: 18),
                ));
              } else {
                categories = snapshot.data!;
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return AlertDialog(
                      title: const Text('Filter Items'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Categories:'),
                          Wrap(
                            children: categories.map((String category) {
                              return FilterChip(
                                label: Text(category),
                                selected: selectedCategories.contains(category),
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected &&
                                        !selectedCategories
                                            .contains(category)) {
                                      selectedCategories.add(category);
                                    } else {
                                      selectedCategories.remove(category);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedCategories = [];
                            });
                          },
                          child: const Text('Reset'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Apply the filter and reload items
                            applyFilter();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Apply'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              selectedCategories = [];
                              selectedCategories.addAll(filterCategories);
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    );
                  },
                );
              }
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WIMS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate:
                    CustomSearchDelegate(editItemCallback: editItemCallback),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              showFilterDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Handle sorting functionality
            },
          ),
          // TODO: Add multiple removal in the future.
          // IconButton(
          //   icon: Icon(Icons.remove_circle_outline),
          //   onPressed: () {
          //     // Handle remove functionality
          //   },
          // ),
        ],
      ),
      body: items.isNotEmpty
          ? ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _handleOnTap(items[index]);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    color: Theme.of(context).primaryColorLight,
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(items[index]['name'] ?? ''),
                              Text('Count: ${items[index]['count']}'),
                            ],
                          ),
                          const SizedBox(height: 4), // Adjust spacing as needed
                          if (items[index]['category'] != null)
                            Text(
                              '${items[index]['category']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          if (items[index]['subcategory'] != null)
                            Text(
                              '${items[index]['subcategory']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black38),
                            ),
                        ],
                      ),
                      // Handle null image_id
                      leading: items[index]['image_id'] != null
                          ? Image.network(
                              'url_to_your_image') // Replace with your logic to load images
                          : null, // Replace with your fallback image or icon
                      // Add more details or customize as needed
                    ),
                  ),
                );
              },
            )
          : filterCategories.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome to Wims!',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Start adding your items!',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No item found meeting the filter criteria!',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show item form when button is pressed
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return AddItemForm();
            },
          ).then((_) {
            // Reload items after adding a new item
            loadItems();
          });
        },
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).highlightColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
