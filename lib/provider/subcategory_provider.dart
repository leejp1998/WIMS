import 'package:flutter/material.dart';

class SubCategoryProvider extends ChangeNotifier {
  List<String> subCategories = ['Subcategory 1', 'Subcategory 2'];

  void addCategory(String subCategory) {
    subCategories.add(subCategory);
    notifyListeners();
  }
}