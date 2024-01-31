import 'package:flutter/material.dart';

class CategoryProvider extends ChangeNotifier {
  List<String> categories = ['Category 1', 'Category 2'];

  void addCategory(String category) {
    categories.add(category);
    notifyListeners();
  }
}