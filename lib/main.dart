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
    Color primaryColor = const Color(0xFFd8c8b8);
    Color primaryColorDark = const Color(0xFF8d7966);
    Color highlightColor = const Color(0xFFE0ADAD);
    Color primaryColorLight = const Color(0xFFe2ddd9);

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

