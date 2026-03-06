import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/category.dart';
import 'package:shopping_list_app/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  // ✨ เพิ่มตัวแปรสำหรับรับข้อมูลเดิม (เผื่อกรณีเป็นการกดแก้ไข)
  const NewItem({super.key, this.existingItem});
  final GroceryItem? existingItem;

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  @override
  void initState() {
    super.initState();
    // ✨ ถ้ารับข้อมูลเดิมมา ให้เอามาใส่ในช่องกรอกข้อมูล (โหมดแก้ไข)
    if (widget.existingItem != null) {
      _enteredName = widget.existingItem!.name;
      _enteredQuantity = widget.existingItem!.quantity;
      _selectedCategory = widget.existingItem!.category;
    }
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });

      if (widget.existingItem == null) {
        // --- โหมดเพิ่มรายการใหม่ (POST) ---
        final url = Uri.https('flutter-prepp-37d0c-default-rtdb.firebaseio.com',
            'shopping-list.json');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': _enteredName,
            'quantity': _enteredQuantity,
            'category': _selectedCategory.title,
          }),
        );

        final Map<String, dynamic> resData = json.decode(response.body);
        if (!context.mounted) return;

        Navigator.of(context).pop(
          GroceryItem(
            id: resData['name'],
            name: _enteredName,
            quantity: _enteredQuantity,
            category: _selectedCategory,
          ),
        );
      } else {
        // --- โหมดแก้ไขรายการเดิม (PATCH) ---
        final url = Uri.https('flutter-prepp-37d0c-default-rtdb.firebaseio.com',
            'shopping-list/${widget.existingItem!.id}.json');
        await http.patch(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': _enteredName,
            'quantity': _enteredQuantity,
            'category': _selectedCategory.title,
          }),
        );

        if (!context.mounted) return;

        Navigator.of(context).pop(
          GroceryItem(
            id: widget.existingItem!.id,
            name: _enteredName,
            quantity: _enteredQuantity,
            category: _selectedCategory,
          ),
        );
      }
    }
  }

  IconData _getCategoryIcon(String title) {
    switch (title) {
      case 'Vegetables':
        return Icons.eco;
      case 'Fruit':
        return Icons.apple;
      case 'Meat':
        return Icons.restaurant;
      case 'Dairy':
        return Icons.water_drop;
      case 'Carbs':
        return Icons.bakery_dining;
      case 'Sweets':
        return Icons.icecream;
      case 'Spices':
        return Icons.local_fire_department;
      case 'Convenience':
        return Icons.fastfood;
      case 'Hygiene':
        return Icons.clean_hands;
      case 'Other':
        return Icons.star;
      default:
        return Icons.shopping_bag;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✨ เช็คว่ากำลังแก้ไขอยู่หรือไม่ เพื่อเปลี่ยนชื่อหัวข้อและปุ่ม
    final isEditing = widget.existingItem != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2E4032)),
        title: Text(
          isEditing
              ? 'Edit item'
              : 'Add a new item', // ✨ เปลี่ยนข้อความแถบด้านบน
          style: const TextStyle(
            color: Color(0xFF2E4032),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.green.shade50, width: 1),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _enteredName, // ✨ ใส่ค่าเดิมถ้ามี
                  maxLength: 50,
                  style:
                      const TextStyle(color: Color(0xFF2E4032), fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.green.shade700),
                    filled: true,
                    fillColor: Colors.green.shade50.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.green.shade400, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        value.trim().length <= 1 ||
                        value.trim().length > 50) {
                      return 'Must be between 1 and 50 characters.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredName = value!;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        style: const TextStyle(
                            color: Color(0xFF2E4032), fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          labelStyle: TextStyle(color: Colors.green.shade700),
                          filled: true,
                          fillColor: Colors.green.shade50.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.green.shade400, width: 1.5),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: _enteredQuantity.toString(),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              int.tryParse(value) == null ||
                              int.tryParse(value)! <= 0) {
                            return 'Must be a valid, positive number.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredQuantity = int.parse(value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField(
                        value: _selectedCategory,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                            color: Color(0xFF2E4032), fontSize: 14),
                        borderRadius: BorderRadius.circular(16),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.green.shade50.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                        items: [
                          for (final category in categories.entries)
                            DropdownMenuItem(
                              value: category.value,
                              child: Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(category.value.title),
                                    color: category.value.color,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    category.value.title,
                                    style: const TextStyle(
                                        color: Color(0xFF2E4032), fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSending
                          ? null
                          : () {
                              _formKey.currentState!.reset();
                            },
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600),
                      child:
                          const Text('Reset', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSending ? null : _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isEditing
                                  ? 'Save Changes'
                                  : 'Add Item', // ✨ เปลี่ยนข้อความปุ่ม
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
