import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../edit_item_form.dart';
import 'database_helper.dart';

class CustomSearchDelegate extends SearchDelegate<String> {
  late List<Map<String, dynamic>> results;
  final VoidCallback editItemCallback;

  CustomSearchDelegate({required this.editItemCallback});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = ''; // Clear the search query
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, ''); // Close the search bar
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildSearchResults(context);
  }

  Widget buildSearchResults(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.searchItems(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found.', style: TextStyle(fontSize: 18),));
        } else {
          results = snapshot.data!;
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return EditItemForm(selectedItem: results[index], editItemCallback: editItemCallback,);
                    },
                  ).then((_) {
                    editItemCallback();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  color: Theme.of(context).primaryColorLight,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(results[index]['name'] ?? ''),
                            Text('Count: ${results[index]['count']}'),
                          ],
                        ),
                        const SizedBox(height: 4), // Adjust spacing as needed
                        if (results[index]['category'] != null)
                          Text(
                            '${results[index]['category']}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        if (results[index]['subcategory'] != null)
                          Text(
                            '${results[index]['subcategory']}',
                            style: const TextStyle(fontSize: 12, color: Colors.black38),
                          ),
                      ],
                    ),
                    // Handle null image_id
                    leading: results[index]['image_id'] != null
                        ? Image.network(
                        'url_to_your_image') // Replace with your logic to load images
                        : null, // Replace with your fallback image or icon
                    // Add more details or customize as needed
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}