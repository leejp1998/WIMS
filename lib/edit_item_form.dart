import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wims/formatter/text_input_formatter.dart';
import 'package:wims/provider/category_provider.dart';

import 'helper/database_helper.dart';

class EditItemForm extends StatefulWidget {
  final Map<String, dynamic> selectedItem;
  final VoidCallback editItemCallback;

  EditItemForm({required this.selectedItem, required this.editItemCallback});

  @override
  _EditItemFormState createState() => _EditItemFormState();
}

class _EditItemFormState extends State<EditItemForm> {
  late int id;
  late String categoryName;
  late String subcategoryName;
  late String itemName;
  late int itemCount;
  late int imageId;
  bool isUpdated = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with the selected item's data
    id = widget.selectedItem['id'];
    itemName = widget.selectedItem['name'];
    itemCount = widget.selectedItem['count'];
    categoryName = widget.selectedItem['category'] ?? '';
    subcategoryName = widget.selectedItem['subcategory'] ?? '';
    imageId = widget.selectedItem['image_id'] ?? -1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            initialValue: itemName,
            onChanged: (value) {
              setState(() {
                itemName = value;
                isUpdated = true;
              });
            },
            decoration: const InputDecoration(labelText: 'Item Name'),
            inputFormatters: [CapitalizeWordsTextInputFormatter()],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: itemCount.toString(),
            onChanged: (value) {
              setState(() {
                itemCount = int.tryParse(value) ?? itemCount;
                isUpdated = true;
              });
            },
            decoration: const InputDecoration(labelText: 'Count'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          FutureBuilder(
            future: DatabaseHelper.instance.loadAllCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('Error loading categories');
              } else {
                List<String> categories = snapshot.data as List<String>;
                return DropdownButtonFormField<String>(
                  value: categoryName.isNotEmpty ? categoryName : null,
                  items: [
                    for (String category in categories)
                      DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    const DropdownMenuItem<String>(
                      value: 'addNewCategory',
                      child: Text('Add New Category'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == 'addNewCategory') {
                      await _showAddCategoryDialog(context);
                    } else {
                      setState(() {
                        if (categoryName != value) subcategoryName = '';
                        categoryName = value!;
                      });
                    }
                    isUpdated = true;
                  },
                  decoration: const InputDecoration(labelText: 'Category'),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<String>>(
            future: fetchSubcategories(categoryName),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // While the Future is still running, show a loading indicator
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                // If there is an error with the Future, show an error message
                return Text('Error: ${snapshot.error}');
              } else if (categoryName.isEmpty) {
                // If the Future has no data or empty data, show a message indicating no subcategories
                return const Text('Select category to see subcategory option');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return DropdownButtonFormField<String>(
                  value: subcategoryName.isNotEmpty ? subcategoryName : null,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'addNewSubcategory',
                      child: Text('Add New Subcategory'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == 'addNewSubcategory') {
                      await _showAddSubCategoryDialog(context);
                    } else {
                      setState(() {
                        subcategoryName = value!;
                      });
                    }
                    isUpdated = true;
                  },
                  decoration: const InputDecoration(labelText: 'Subcategory'),
                );
              } else {
                // If the Future completes successfully and has data, build the dropdown menu
                List<String> subcategories = snapshot.data as List<String>;
                return DropdownButtonFormField<String>(
                  value: subcategoryName.isNotEmpty ? subcategoryName : null,
                  items: [
                    for (String subcategory in subcategories)
                      DropdownMenuItem<String>(
                        value: subcategory,
                        child: Text(subcategory),
                      ),
                    const DropdownMenuItem<String>(
                      value: 'addNewSubcategory',
                      child: Text('Add New Subcategory'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == 'addNewSubcategory') {
                      await _showAddSubCategoryDialog(context);
                    } else {
                      setState(() {
                        subcategoryName = value!;
                      });
                    }
                    isUpdated = true;
                  },
                  decoration: const InputDecoration(labelText: 'Subcategory'),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          // Image picker section (implement as needed)
          ElevatedButton(
            onPressed: () {
              // Implement image picker logic here
            },
            child: const Text('Pick Image'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              // Update item logic
              if (itemName.isNotEmpty &&
                  itemCount > 0 &&
                  categoryName.isNotEmpty &&
                  subcategoryName.isNotEmpty) {
                await DatabaseHelper.instance
                    .updateItemWithCategoryAndSubcategory(
                  id,
                  itemName,
                  itemCount,
                  categoryName,
                  subcategoryName,
                );
              } else if (itemName.isNotEmpty &&
                  itemCount > 0 &&
                  categoryName.isNotEmpty) {
                await DatabaseHelper.instance.updateItemWithCategory(
                    id, itemName, itemCount, categoryName);
              } else if (itemName.isNotEmpty && itemCount > 0) {
                await DatabaseHelper.instance
                    .updateItem(id, itemName, itemCount);
              }

              widget.editItemCallback();

              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await DatabaseHelper.instance.removeItem(id);
                    Navigator.pop(context);
                  },
                  child: const Text('Remove'),
                ),
              ),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    String newCategory = '';
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Category'),
          content: TextFormField(
            onChanged: (value) {
              newCategory = value;
            },
            decoration: InputDecoration(labelText: 'New Category'),
            inputFormatters: [CapitalizeWordsTextInputFormatter()],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Insert the new category into the database
                await DatabaseHelper.instance.insertNewCategory(newCategory);

                // Update the dropdown items
                setState(() {
                  categoryName = newCategory;
                  subcategoryName = '';
                });

                Navigator.pop(context); // Close the dialog
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddSubCategoryDialog(BuildContext context) async {
    String newSubcategory = '';
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Subcategory'),
          content: TextFormField(
            onChanged: (value) {
              newSubcategory = value;
            },
            decoration: InputDecoration(labelText: 'New Subcategory'),
            inputFormatters: [CapitalizeWordsTextInputFormatter()],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Insert the new category into the database
                await DatabaseHelper.instance
                    .insertNewSubcategory(newSubcategory, categoryName);

                // Update the dropdown items
                setState(() {
                  subcategoryName = newSubcategory;
                });

                Navigator.pop(context); // Close the dialog
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> fetchSubcategories(String category) async {
    if (category.isEmpty) {
      return [];
    }
    List<String> subcategories =
        await DatabaseHelper.instance.loadAllSubcategoriesWithCategory(category);
    return subcategories;
  }
}
