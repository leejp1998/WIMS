import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wims/app_loading_screen.dart';
import 'package:wims/home_page.dart';
import 'package:wims/provider/category_provider.dart';

import 'helper/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isDebugMode = true;
  assert(isDebugMode = true);

  if (isDebugMode) {
    // Delete the entire database file before initializing the app
    await DatabaseHelper.deleteDatabaseFile();
  }
  await DatabaseHelper.instance.database;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CategoryProvider()),
      ],
      child: Wims(),
    ),
  );
}

class Wims extends StatelessWidget {
  const Wims({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFF6e6e6e);
    Color primaryColorDark = const Color(0xFF3b3b3b);
    Color highlightColor = const Color(0xFF845858);
    Color primaryColorLight = const Color(0xFFa1a1a1);

    return MaterialApp(
      title: 'WIMS',
      theme: ThemeData(
        primaryColor: primaryColor,
        primaryColorDark: primaryColorDark,
        primaryColorLight: primaryColorLight,
        highlightColor: highlightColor,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: AppLoadingScreen(),
    );
  }
}

