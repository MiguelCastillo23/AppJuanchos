import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagenUrl;
  int cantidad;

  CartItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenUrl,
    this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  int get totalCantidad {
    int total = 0;
    _items.forEach((key, item) {
      total += item.cantidad;
    });
    return total;
  }

  double get totalPrecio {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.subtotal;
    });
    return total;
  }

  bool get isEmpty => _items.isEmpty;

  void agregarProducto(String id, String nombre, String descripcion, 
      double precio, String imagenUrl) {
    if (_items.containsKey(id)) {
      // Si ya existe, aumentar cantidad
      _items[id]!.cantidad++;
    } else {
      // Si no existe, agregar nuevo
      _items[id] = CartItem(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
        precio: precio,
        imagenUrl: imagenUrl,
      );
    }
    notifyListeners();
  }

  void aumentarCantidad(String id) {
    if (_items.containsKey(id)) {
      _items[id]!.cantidad++;
      notifyListeners();
    }
  }

  void disminuirCantidad(String id) {
    if (_items.containsKey(id)) {
      if (_items[id]!.cantidad > 1) {
        _items[id]!.cantidad--;
      } else {
        _items.remove(id);
      }
      notifyListeners();
    }
  }

  void eliminarProducto(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void limpiarCarrito() {
    _items.clear();
    notifyListeners();
  }

  bool contieneProducto(String id) {
    return _items.containsKey(id);
  }

  int cantidadProducto(String id) {
    return _items.containsKey(id) ? _items[id]!.cantidad : 0;
  }
}