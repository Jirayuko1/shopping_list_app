import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;
  
  final Set<String> _completedItems = {}; 

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https('flutter-prepp-37d0c-default-rtdb.firebaseio.com', 'shopping-list.json');

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
        return;
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere((catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (ctx) => const NewItem()),
    );

    if (newItem == null) return;
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _editItem(GroceryItem item, int index) async {
    final updatedItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => NewItem(existingItem: item), 
      ),
    );

    if (updatedItem == null) return;
    setState(() {
      _groceryItems[index] = updatedItem; 
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
      _completedItems.remove(item.id); 
    });

    final url = Uri.https('flutter-prepp-37d0c-default-rtdb.firebaseio.com', 'shopping-list/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  IconData _getCategoryIcon(String title) {
    switch (title) {
      case 'Vegetables': return Icons.eco;
      case 'Fruit': return Icons.apple;
      case 'Meat': return Icons.restaurant;
      case 'Dairy': return Icons.water_drop;
      case 'Carbs': return Icons.bakery_dining;
      case 'Sweets': return Icons.icecream;
      case 'Spices': return Icons.local_fire_department;
      case 'Convenience': return Icons.fastfood;
      case 'Hygiene': return Icons.clean_hands;
      case 'Other': return Icons.star;
      default: return Icons.shopping_bag;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.green[200]),
          const SizedBox(height: 16),
          Text(
            'ไม่มีรายการ ซื้ออะไรดีนะ?',
            style: TextStyle(color: Colors.green[800], fontSize: 16),
          ),
        ],
      ),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (_groceryItems.isNotEmpty) {
      // ✨ 1. จัดกลุ่มข้อมูลตามหมวดหมู่ (หมวดหมู่ไหนไม่มีของ ก็จะไม่แสดง)
      final Map<String, List<GroceryItem>> groupedItems = {};
      for (final item in _groceryItems) {
        final categoryName = item.category.title;
        if (!groupedItems.containsKey(categoryName)) {
          groupedItems[categoryName] = [];
        }
        groupedItems[categoryName]!.add(item);
      }

      // ✨ 2. สร้างหน้าจอจากกลุ่มข้อมูลที่จัดไว้
      content = ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: groupedItems.entries.map((entry) {
          final categoryName = entry.key;
          final itemsInCategory = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✨ หัวข้อหมวดหมู่ (Category Header)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12, left: 8),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(categoryName),
                      size: 22,
                      color: itemsInCategory.first.category.color, // ดึงสีหมวดหมู่มาใช้
                    ),
                    const SizedBox(width: 8),
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900, // สีเขียวเข้มให้ดูแพง
                      ),
                    ),
                  ],
                ),
              ),
              // ✨ รายการสินค้าในหมวดหมู่นี้
              ...itemsInCategory.map((currentItem) {
                final isDone = _completedItems.contains(currentItem.id);
                // ต้องหาตำแหน่ง index จริงๆ จากลิสต์หลัก เพื่อให้ระบบแก้ไข (Edit) ทำงานถูกตัว
                final originalIndex = _groceryItems.indexOf(currentItem);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    onDismissed: (direction) {
                      _removeItem(currentItem);
                    },
                    key: ValueKey(currentItem.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDone ? Colors.grey[50] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(isDone ? 0 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isDone ? Colors.grey.shade300 : Colors.green.shade100, 
                          width: 1
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _editItem(currentItem, originalIndex),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDone ? Colors.grey.shade200 : currentItem.category.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDone ? Colors.grey.shade400 : currentItem.category.color.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(currentItem.category.title),
                              color: isDone ? Colors.grey.shade500 : currentItem.category.color,
                              size: 24,
                            ),
                          ),
                        ),
                        title: Text(
                          currentItem.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? Colors.grey.shade500 : const Color(0xFF2E4032),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDone ? Colors.grey.shade200 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: isDone ? Colors.grey.shade400 : Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${currentItem.quantity}x',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDone ? Colors.grey.shade500 : Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Checkbox(
                              value: isDone,
                              activeColor: Colors.green.shade600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _completedItems.add(currentItem.id);
                                  } else {
                                    _completedItems.remove(currentItem.id);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(), // วาดการ์ดสินค้าในหมวดหมู่นั้นๆ
            ],
          );
        }).toList(),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Your Grocery List',
          style: TextStyle(
            color: Color(0xFF2E4032),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
            ),
          ),
        ],
      ),
      body: content,
    );
  }
}