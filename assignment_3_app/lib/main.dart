import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'food_planner.db'),
    onCreate: (db, version) {
      db.execute(
        'CREATE TABLE food_items(id INTEGER PRIMARY KEY, name TEXT, cost REAL)',
      );
      db.execute(
        'CREATE TABLE order_plans(id INTEGER PRIMARY KEY, date TEXT, target_cost REAL, selected_items TEXT)',
      );
    },
    version: 1,
  );

  runApp(MyApp(database));
}

class MyApp extends StatelessWidget {
  final Future<Database> database;

  MyApp(this.database);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodPlanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(database),
    );
  }
}

class HomePage extends StatelessWidget {
  final Future<Database> database;

  HomePage(this.database);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('FoodPlanner', style: TextStyle(color: Colors.white)),
            SizedBox(width: 8),
            Icon(Icons.restaurant, color: Colors.white, size: 20),
          ],
        ),
        backgroundColor: Colors.blue[900],
      ),
      backgroundColor: Colors.lightBlue[50],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Create and manage custom order plans with ease!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 34,
                fontStyle: FontStyle.italic,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildMainButton(
                    context,
                    'Food Items',
                    Colors.green[300]!,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddFoodPage(database)),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  _buildMainButton(
                    context,
                    'New Order Plan',
                    Colors.green[400]!,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => OrderPlanPage(database)),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  _buildMainButton(
                    context,
                    'Search for Order Plan',
                    Colors.green[500]!,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QueryOrderPage(database)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(BuildContext context, String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class AddFoodPage extends StatefulWidget {
  final Future<Database> database;

  AddFoodPage(this.database);

  @override
  _AddFoodPageState createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  Future<void> _addFoodItem(String name, double cost) async {
    final db = await widget.database;
    await db.insert(
      'food_items',
      {'name': name, 'cost': cost},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> _getFoodItems() async {
    final db = await widget.database;
    return await db.query('food_items');
  }

  Future<void> _deleteFoodItem(int id) async {
    final db = await widget.database;
    await db.delete('food_items', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('FoodPlanner', style: TextStyle(color: Colors.white)),
            SizedBox(width: 8),
            Icon(Icons.restaurant, color: Colors.white, size: 20),
          ],
        ),
        backgroundColor: Colors.blue[900],
      ),
      backgroundColor: Colors.lightBlue[50],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Manage Foods',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Food Item Name'),
                  ),
                  TextField(
                    controller: _costController,
                    decoration: InputDecoration(labelText: 'Cost of Food Item'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text;
                      final cost = double.tryParse(_costController.text);

                      if (name.isNotEmpty && cost != null) {
                        _addFoodItem(name, cost).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('The food item has successfully been added!')),
                          );
                          _nameController.clear();
                          _costController.clear();
                          setState(() {});
                        });
                      }
                    },
                    child: Text('Add Food'),
                  ),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getFoodItems(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          final items = snapshot.data ?? [];
                          return ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                title: Text(item['name']),
                                subtitle: Text('\$${item['cost']}'),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteFoodItem(item['id']).then((_) {
                                      setState(() {});
                                    });
                                  },
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderPlanPage extends StatefulWidget {
  final Future<Database> database;

  OrderPlanPage(this.database);

  @override
  _OrderPlanPageState createState() => _OrderPlanPageState();
}

class _OrderPlanPageState extends State<OrderPlanPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _targetCostController = TextEditingController();
  List<Map<String, dynamic>> _foodItems = [];
  List<int> _selectedItems = [];

  Future<void> _fetchFoodItems() async {
    final db = await widget.database;
    final items = await db.query('food_items');
    setState(() {
      _foodItems = items;
    });
  }

  Future<void> _createOrderPlan(String date, double targetCost) async {
    final db = await widget.database;
    final selectedItems = _selectedItems.map((id) => id.toString()).join(',');
    await db.insert(
      'order_plans',
      {'date': date, 'target_cost': targetCost, 'selected_items': selectedItems},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('FoodPlanner', style: TextStyle(color: Colors.white)),
            SizedBox(width: 8),
            Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
          ],
        ),
        backgroundColor: Colors.blue[900],
      ),
      backgroundColor: Colors.lightBlue[50],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Create a New Order Plan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _dateController,
                    decoration: InputDecoration(labelText: 'Date of Order (YYYY-MM-DD)'),
                  ),
                  TextField(
                    controller: _targetCostController,
                    decoration: InputDecoration(labelText: 'Target Cost'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Choose from the Following Food Items:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _foodItems.length,
                      itemBuilder: (context, index) {
                        final item = _foodItems[index];
                        return CheckboxListTile(
                          title: Text(item['name']),
                          subtitle: Text('\$${item['cost']}'),
                          value: _selectedItems.contains(item['id']),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedItems.add(item['id']);
                              } else {
                                _selectedItems.remove(item['id']);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final date = _dateController.text;
                      final targetCost = double.tryParse(_targetCostController.text);

                      if (date.isNotEmpty && targetCost != null && _selectedItems.isNotEmpty) {
                        _createOrderPlan(date, targetCost).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('The order plan has successfully been created!')),
                          );
                          _dateController.clear();
                          _targetCostController.clear();
                          setState(() {
                            _selectedItems.clear();
                          });
                        });
                      }
                    },
                    child: Text('Create Plan'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QueryOrderPage extends StatefulWidget {
  final Future<Database> database;

  QueryOrderPage(this.database);

  @override
  _QueryOrderPageState createState() => _QueryOrderPageState();
}

class _QueryOrderPageState extends State<QueryOrderPage> {
  final TextEditingController _queryController = TextEditingController();
  List<Map<String, dynamic>> _orderPlans = [];

  Future<void> _fetchOrderPlans(String queryDate) async {
    final db = await widget.database;
    final plans = await db.query(
      'order_plans',
      where: 'date = ?',
      whereArgs: [queryDate],
    );
    setState(() {
      _orderPlans = plans;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchFoodItemsByIds(List<int> ids) async {
    final db = await widget.database;
    final items = await db.query(
      'food_items',
      where: 'id IN (${ids.join(',')})',
    );
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('FoodPlanner', style: TextStyle(color: Colors.white)),
            SizedBox(width: 8),
            Icon(Icons.search, color: Colors.white, size: 20),
          ],
        ),
        backgroundColor: Colors.blue[900],
      ),
      backgroundColor: Colors.lightBlue[50],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Search for Order Plans',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
          TextField(
            controller: _queryController,
            decoration: InputDecoration(labelText: 'Enter the Date of the Order (YYYY-MM-DD)'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final queryDate = _queryController.text;
              if (queryDate.isNotEmpty) {
                _fetchOrderPlans(queryDate);
              }
            },
            child: Text('Search for Order'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _orderPlans.length,
              itemBuilder: (context, index) {
                final plan = _orderPlans[index];
                final selectedIds = (plan['selected_items'] as String)
                    .split(',')
                    .map((e) => int.tryParse(e))
                    .whereType<int>()
                    .toList();

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchFoodItemsByIds(selectedIds),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final items = snapshot.data ?? [];
                      final itemNames = items.map((e) => e['name']).join(', ');
                      return ListTile(
                        title: Text('Date: ${plan['date']}'),
                        subtitle: Text('Items: $itemNames\nTarget: \$${plan['target_cost']}'),
                      );
                    }
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