import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  List<CartItem> _items = [];
  static const String _cartKey = 'payment_cart';

  List<CartItem> get items => List.unmodifiable(_items);
  
  int get itemCount => _items.length;
  
  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPayment);

  bool isInCart(String installmentId) {
    return _items.any((item) => item.id == installmentId);
  }

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString(_cartKey);
      
      if (cartData != null) {
        final List<dynamic> jsonList = json.decode(cartData);
        _items = jsonList.map((json) => CartItem.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = json.encode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartData);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  Future<void> addItem(CartItem item) async {
    if (!isInCart(item.id)) {
      _items.add(item);
      await _saveCart();
      notifyListeners();
    }
  }

  Future<void> removeItem(String installmentId) async {
    _items.removeWhere((item) => item.id == installmentId);
    await _saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

  CartItem? getItem(String installmentId) {
    try {
      return _items.firstWhere((item) => item.id == installmentId);
    } catch (e) {
      return null;
    }
  }
}