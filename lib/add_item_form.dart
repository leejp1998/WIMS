import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wims/formatter/text_input_formatter.dart';
import 'package:wims/provider/category_provider.dart';

import 'helper/database_helper.dart';

class AddItemForm extends StatefulWidget {
  @override
  _AddItemFormState createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  String categoryName = '';
  String subcategoryName = '';
  String itemName = '';
  int itemCount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            onChanged: (value) {
              setState(() {
                itemName = value;
              });
            },
            decoration: const InputDecoration(labelText: 'Item Name'),
            inputFormatters: [CapitalizeWordsTextInputFormatter()],
          ),
          const SizedBox(height: 8),
          TextFormField(
            onChanged: (value) {
              setState(() {
                itemCount = int.tryParse(value) ?? 0;
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
                return DropdownButtonFormField<String>(
                  value: null,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'addNewCategory',
                      child: Text('Add New Category'),
                    ),
                  ],
                  onTap: () => {FocusScope.of(context).requestFocus(FocusNode())},
                  onChanged: (value) => {},
                  decoration: const InputDecoration(labelText: 'Category'),
                );
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
                  onTap: () => {FocusScope.of(context).requestFocus(FocusNode())},
                  onChanged: (value) async {
                    if (value == 'addNewCategory') {
                      await _showAddCategoryDialog(context);
                    } else {
                      setState(() {
                        if (categoryName != value) subcategoryName = '';
                        categoryName = value!;
                      });
                    }
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
                return const Text('Select category to see subcategory option');
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (categoryName.isEmpty) {
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
                  onTap: () => {FocusScope.of(context).requestFocus(FocusNode())},
                  onChanged: (value) async {
                    if (value == 'addNewSubcategory') {
                      await _showAddSubCategoryDialog(context);
                    } else {
                      setState(() {
                        subcategoryName = value!;
                      });
                    }
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
                  onTap: () => {FocusScope.of(context).requestFocus(FocusNode())},
                  onChanged: (value) async {
                    if (value == 'addNewSubcategory') {
                      await _showAddSubCategoryDialog(context);
                    } else {
                      setState(() {
                        subcategoryName = value!;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Subcategory'),
                );
              }
            },
          ),
          const Spacer(),
          //const SizedBox(height: 8),
          // Image picker section (implement as needed)
          // ElevatedButton(
          //   onPressed: () {
          //     // Implement image picker logic here
          //   },
          //   child: const Text('Pick Image'),
          // ),
          //const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              // TODO: Add a case where image is added and image_id exists
              if (itemName.isNotEmpty &&
                  itemCount > 0 &&
                  categoryName.isNotEmpty &&
                  subcategoryName.isNotEmpty) {
                await DatabaseHelper.instance
                    .insertItemWithCategoryAndSubcategory(
                  itemName,
                  itemCount,
                  categoryName,
                  subcategoryName,
                );
              } else if (itemName.isNotEmpty &&
                  itemCount > 0 &&
                  categoryName.isNotEmpty) {
                await DatabaseHelper.instance
                    .insertItemWithCategory(itemName, itemCount, categoryName);
              } else if (itemName.isNotEmpty && itemCount > 0) {
                await DatabaseHelper.instance.insertItem(itemName, itemCount);
              }

              Navigator.pop(context);
            },
            child: const Text('Add Item'),
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
    List<String> subcategories = await DatabaseHelper.instance
        .loadAllSubcategoriesWithCategory(category);
    return subcategories;
  }
}
