import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './product.dart';
import '../models/http_exception.dart';

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    //   isFavorite: false,
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    //   isFavorite: false,
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    //   isFavorite: false,
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    //   isFavorite: false,
    // ),
  ];

  //var _showFavoritesOnly = false;
  final String authToken;
  final String userId;

  Products(this.authToken, this._items, this.userId);

  List<Product> get items {
    // if (_showFavoritesOnly) {
    //   return _items.where((element) => element.isFavorite).toList();
    // }
    return [..._items];
  }

  List<Product> get favoriteItems {
    return items.where((element) => element.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => id == prod.id);
  }

  // void showFavoritesOnly() {
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }

  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url = Uri.parse(
      'https://flutter-sh-7bffd-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filterString',
    );
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url = Uri.parse(
        'https://flutter-sh-7bffd-default-rtdb.firebaseio.com/userfavorites/$userId.json?auth=$authToken',
      );
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProductes = [];
      extractedData.forEach((prodId, prodData) {
        loadedProductes.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          imageUrl: prodData['imageUrl'],
          isFavorite:
              favoriteData == null ? false : favoriteData[prodId] ?? false,
          price: prodData['price'],
        ));
      });
      _items = loadedProductes;
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> addProduct(Product p) async {
    final url = Uri.parse(
      'https://flutter-sh-7bffd-default-rtdb.firebaseio.com/products.json?auth=$authToken',
    );

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': p.title,
          'description': p.description,
          'price': p.price,
          'imageUrl': p.imageUrl,
          'creatorId': userId
        }),
      );
      final newProd = Product(
        id: json.decode(response.body)['name'],
        title: p.title,
        description: p.description,
        price: p.price,
        imageUrl: p.imageUrl,
      );
      _items.add(newProd);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product p) async {
    final prodIndex = _items.indexWhere((prod) => p.id == prod.id);
    if (prodIndex >= 0) {
      final url = Uri.parse(
        'https://flutter-sh-7bffd-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken',
      );
      await http.patch(url,
          body: json.encode({
            'title': p.title,
            'description': p.description,
            'price': p.price,
            'imageUrl': p.imageUrl,
          }));
      _items[prodIndex] = p;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.parse(
      'https://flutter-sh-7bffd-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken',
    );
    final existingProdIndex = _items.indexWhere((element) => id == element.id);
    var existingProd = _items[existingProdIndex];
    _items.removeAt(existingProdIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProdIndex, existingProd);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProd = null;
  }
}
