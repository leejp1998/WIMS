import 'dart:io';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final _databaseName = 'wims.db';
  static final _databaseVersion = 1;

  // Define table names
  static final tableItems = 'items';
  static final tableCategories = 'categories';
  static final tableSubcategories = 'subcategories';
  static final tableImages = 'images';

  // Define column names
  static final columnId = 'id';
  static final columnName = 'name';
  static final columnCount = 'count';
  static final columnCategory = 'category';
  static final columnSubcategory = 'subcategory';
  static final columnImageId = 'image_id';
  static final columnCategoryName = 'category_name';
  static final columnSubcategoryName = 'subcategory_name';
  static final columnCategoryNameFk = 'category_name';
  static final columnImageData = 'image_data';

  static final DEFAULT_CATEGORIES = ['Books and Documents', 'Clothing', 'Electronics', 'Furniture', 'Home Improvement Materials',
                                     'Household Supplies', 'Kitchen Supplies', 'Memorabilia', 'Miscellaneous', 'Sports and Recreation',
                                     'Tools and Equipment', 'Toys and Games'];
  // map: subcategory -> category
  static final Map<String, String> DEFAULT_SUBCATEGORIES_MAP = {
    'Books': 'Books and Documents',
    'Important Documents': 'Books and Documents',
    'Paperwork': 'Books and Documents',
    'Accessories': 'Clothing',
    'Seasonal Clothing': 'Clothing',
    'Shoes': 'Clothing',
    'Cables and Chargers': 'Electronics',
    'Larger Appliances': 'Electronics',
    'Small Electronics': 'Electronics',
    'Decorative Pieces': 'Furniture',
    'Indoor Furniture': 'Furniture',
    'Outdoor Furniture': 'Furniture',
    'Flooring': 'Home Improvement Materials',
    'Paint': 'Home Improvement Materials',
    'Tiles': 'Home Improvement Materials',
    'Batteries': 'Household Supplies',
    'Cleaning Supplies': 'Household Supplies',
    'Laundry Supplies': 'Household Supplies',
    'Light Bulbs': 'Household Supplies',
    'Paper Goods': 'Household Supplies',
    'Cookware': 'Kitchen Supplies',
    'Dishware': 'Kitchen Supplies',
    'Pantry Items': 'Kitchen Supplies',
    'Small Appliances': 'Kitchen Supplies',
    'Utensils': 'Kitchen Supplies',
    'Family Heirlooms': 'Memorabilia',
    'Old Photographs': 'Memorabilia',
    'Sentimental Items': 'Memorabilia',
    'Miscellaneous Items': 'Miscellaneous',
    'Bicycles': 'Sports and Recreation',
    'Camping Gear': 'Sports and Recreation',
    'Sports Equipment': 'Sports and Recreation',
    'Gardening Equipment': 'Tools and Equipment',
    'Hand Tools': 'Tools and Equipment',
    'Power Tools': 'Tools and Equipment',
    'Board Games': 'Toys and Games',
    'Children\'s Toys': 'Toys and Games',
    'Recreational Items': 'Toys and Games',
  };
  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    // Uncomment this after debugging
    // if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }


  Future<bool> _isDatabaseInitialized() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDatabaseInitialized') ?? false;
  }

  Future<void> _markDatabaseInitialized() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDatabaseInitialized', true);
  }

  Future<void> _initializeDatabase(Database db) async {
    print("Initializing database...");

    List<Map<String, dynamic>> result = await db.query(tableCategories);
    if (result.isEmpty) {
      print("Categories table is empty, adding default categories...");

      await db.transaction((Transaction txn) async {
        Batch batch = txn.batch();

        for (String category in DEFAULT_CATEGORIES) {
          batch.insert(tableCategories, {columnCategoryName: category});
        }
        print("Default categories added successfully!");

        for (var entry in DEFAULT_SUBCATEGORIES_MAP.entries) {
          batch.insert(tableSubcategories, {
            columnSubcategoryName: entry.key,
            columnCategoryNameFk: entry.value,
          });
        }
        print("Default subcategories with categories added successfully!");

        await batch.commit();
      });
    } else {
      print("Categories table already populated, skipping initialization.");
    }
  }

  // used in debug only
  static Future<void> deleteDatabaseFile() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    await deleteDatabase(join(documentsDirectory.path, _databaseName));
    print("Database file deleted!");
  }

  // Function to open the database
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  // Function to create the database tables
  Future<void> _onCreate(Database db, int version) async {
    bool isDebugMode = true;
    assert(isDebugMode = true);

    if (isDebugMode) {
      // Drop existing tables (if any)

      await db.execute('DROP TABLE IF EXISTS $tableItems');
      await db.execute('DROP TABLE IF EXISTS $tableCategories');
      await db.execute('DROP TABLE IF EXISTS $tableSubcategories');
      await db.execute('DROP TABLE IF EXISTS $tableImages');

      print("Database dropped (debug mode)!");
    }
    // Create items table
    await db.execute('''
      CREATE TABLE $tableItems (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnCount INTEGER NOT NULL,
        $columnCategory TEXT,
        $columnSubcategory TEXT,
        $columnImageId INTEGER,
        FOREIGN KEY ($columnCategory) REFERENCES $tableCategories ($columnCategoryName),
        FOREIGN KEY ($columnSubcategory) REFERENCES $tableSubcategories ($columnSubcategoryName),
        FOREIGN KEY ($columnImageId) REFERENCES $tableImages ($columnId)
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE $tableCategories (
        $columnCategoryName TEXT PRIMARY KEY
      )
    ''');

    // Create subcategories table
    await db.execute('''
      CREATE TABLE $tableSubcategories (
        $columnSubcategoryName TEXT PRIMARY KEY,
        $columnCategoryNameFk TEXT,
        FOREIGN KEY ($columnCategoryNameFk) REFERENCES $tableCategories ($columnCategoryName)
      )
    ''');

    // Create images table
    await db.execute('''
      CREATE TABLE $tableImages (
        $columnId INTEGER PRIMARY KEY,
        $columnImageData BLOB NOT NULL
      )
    ''');

    // Initialize the database with default categories and mark it initialized
    await _initializeDatabase(db);
    await _markDatabaseInitialized();
  }

  Future<int> insertItem(String name, int count) async {
    Database db = await instance.database;
    return await db.insert(
      DatabaseHelper.tableItems,
      {
        DatabaseHelper.columnName: name,
        DatabaseHelper.columnCount: count,
      },
    );
  }

  Future<int> insertItemWithCategory(String name, int count, String category) async {
    Database db = await instance.database;
    return await db.insert(
      DatabaseHelper.tableItems,
      {
        DatabaseHelper.columnName: name,
        DatabaseHelper.columnCount: count,
        DatabaseHelper.columnCategory: category,
      },
    );
  }

  Future<int> insertItemWithCategoryAndSubcategory(String name, int count, String category, String subcategory) async {
    Database db = await instance.database;
    return await db.insert(
      DatabaseHelper.tableItems,
      {
        DatabaseHelper.columnName: name,
        DatabaseHelper.columnCount: count,
        DatabaseHelper.columnCategory: category,
        DatabaseHelper.columnSubcategory: subcategory,
      },
    );
  }

  Future<int> insertItemWithCategoryAndSubcategoryAndImage(String name, int count, String category, String subcategory, int imageId) async {
    Database db = await instance.database;
    return await db.insert(
      DatabaseHelper.tableItems,
      {
        DatabaseHelper.columnName: name,
        DatabaseHelper.columnCount: count,
        DatabaseHelper.columnCategory: category,
        DatabaseHelper.columnSubcategory: subcategory,
        DatabaseHelper.columnImageId: imageId,
      },
    );
  }

  Future<void> insertNewCategory(String newCategory) async {
    Database db = await DatabaseHelper.instance.database;
    await db.insert(DatabaseHelper.tableCategories, {DatabaseHelper.columnCategoryName: newCategory}
        , conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> insertNewSubcategory(String newSubcategory, String category) async {
    Database db = await DatabaseHelper.instance.database;
    await db.insert(DatabaseHelper.tableSubcategories, {
      DatabaseHelper.columnSubcategoryName: newSubcategory,
      DatabaseHelper.columnCategoryNameFk: category,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> loadAllItems() async {
    Database db = await database;
    return await db.query(tableItems);
  }

  // Function to load categories from the database
  Future<List<String>> loadAllCategories() async {
    Database db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> result = await db.query(DatabaseHelper.tableCategories);
    List<String> resultList = result.map((category) => category[DatabaseHelper.columnCategoryName] as String).toList();
    resultList.sort((a, b) {return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());});
    return resultList;
  }

  Future<List<String>> loadAllSubcategories(String category) async {
    Database db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> result = await db.query(
        DatabaseHelper.tableSubcategories,
        where: '${DatabaseHelper.columnCategoryNameFk} = ?',
        whereArgs: [category]);
    List<String> resultList = result.map((category) => category[DatabaseHelper.columnSubcategoryName] as String).toList();
    resultList.sort((a, b) {return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());});
    return resultList;
  }

  Future<int> updateItem(int id, String name, int count) async {
    Database db = await instance.database;
    Map<String, dynamic> updatedValues = {
      'name': name,
      'count': count,
    };
    return await db.update(
      DatabaseHelper.tableItems,
      updatedValues,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateItemWithCategory(int id, String name, int count, String category) async {
    Database db = await instance.database;
    Map<String, dynamic> updatedValues = {
      'name': name,
      'count': count,
      'category': category,
    };
    return await db.update(
      DatabaseHelper.tableItems,
      updatedValues,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateItemWithCategoryAndSubcategory(int id, String name, int count, String category, String subcategory) async {
    Database db = await instance.database;
    Map<String, dynamic> updatedValues = {
      'name': name,
      'count': count,
      'category': category,
      'subcategory': subcategory,
    };
    return await db.update(
      DatabaseHelper.tableItems,
      updatedValues,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateItemWithCategoryAndSubcategoryAndImage(int id, String name, int count, String category, String subcategory, int imageId) async {
    Database db = await instance.database;
    Map<String, dynamic> updatedValues = {
      'name': name,
      'count': count,
      'category': category,
      'subcategory': subcategory,
      'image_id': imageId,
    };
    return await db.update(
      DatabaseHelper.tableItems,
      updatedValues,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeItem(int id) async {
    try {
      Database db = await instance.database;

      await db.delete(
        tableItems,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error removing item: $e');
    }
  }
}