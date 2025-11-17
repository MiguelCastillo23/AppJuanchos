import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'mis_pedidos_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  String _categoriaSeleccionada = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final List<Map<String, dynamic>> _categorias = [
    {'nombre': 'Todos', 'icono': Icons.grid_view},
    {'nombre': 'Salchipapas', 'icono': FontAwesomeIcons.bowlRice},
    {'nombre': 'Hamburguesas', 'icono': FontAwesomeIcons.burger}, 
    {'nombre': 'Alitas', 'icono': FontAwesomeIcons.drumstickBite},
    {'nombre': 'Parrillas', 'icono': FontAwesomeIcons.fire},
    {'nombre': 'Bebidas', 'icono': FontAwesomeIcons.wineGlass},
    {'nombre': 'Adicionales', 'icono': FontAwesomeIcons.plus}
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juanchos'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Filtro de categorías
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final categoria = _categorias[index];
                final isSelected = _categoriaSeleccionada == categoria['nombre'];
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      children: [
                        Icon(
                          categoria['icono'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(categoria['nombre']),
                      ],
                    ),
                    selectedColor: Colors.orange,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _categoriaSeleccionada = categoria['nombre'];
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          // Grid de productos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _categoriaSeleccionada == 'Todos'
                  ? FirebaseFirestore.instance.collection('productos').snapshots()
                  : FirebaseFirestore.instance
                      .collection('productos')
                      .where('k_cate', isEqualTo: _categoriaSeleccionada)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, 
                          size: 80, 
                          color: Colors.grey[400]
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay productos disponibles',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final productos = snapshot.data!.docs;

                // Filtrar por búsqueda si hay query
                final productosFiltrados = _searchQuery.isEmpty
                    ? productos
                    : productos.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final categoria = (data['k_cate'] ?? '').toString().toLowerCase();
                        final nombre = (data['l_nomb'] ?? '').toString().toLowerCase();
                        final descripcion = (data['l_desc'] ?? '').toString().toLowerCase();
                        
                        return categoria.contains(_searchQuery) ||
                               nombre.contains(_searchQuery) ||
                               descripcion.contains(_searchQuery);
                      }).toList();

                if (productosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, 
                          size: 80, 
                          color: Colors.grey[400]
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron productos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Intenta con otra búsqueda',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final producto = productosFiltrados[index].data() as Map<String, dynamic>;
                    final productoId = productosFiltrados[index].id;

                    return _ProductoCard(
                      nombre: producto['l_nomb'] ?? 'Sin nombre',
                      descripcion: producto['l_desc'] ?? 'Sin descripción',
                      precio: (producto['s_prec'] ?? 0.0).toDouble(),
                      imagenUrl: producto['l_imag'] ?? '',
                      onAgregarCarrito: () {
                        _agregarAlCarrito(producto, productoId);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _agregarAlCarrito(Map<String, dynamic> producto, String id) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    cart.agregarProducto(
      id,
      producto['l_nomb'] ?? 'Sin nombre',
      producto['l_desc'] ?? 'Sin descripción',
      (producto['s_prec'] ?? 0.0).toDouble(),
      producto['l_imag'] ?? '',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto['l_nomb']} agregado al carrito'),
        duration: const Duration(milliseconds: 500),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Ver carrito',
          textColor: Colors.white,
          onPressed: () {
            // Navegar al carrito si es necesario
          },
        ),
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagenUrl;
  final VoidCallback onAgregarCarrito;

  const _ProductoCard({
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenUrl,
    required this.onAgregarCarrito,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: imagenUrl.isNotEmpty
                ? Image.network(
                    imagenUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey[500],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 140,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey[500],
                    ),
                  ),
          ),
          
          // Información del producto
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del producto
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Descripción
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(),
                  
                  // Precio y botón
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'S/ ${precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(
                        height: 26,
                        width: 50,
                        child: ElevatedButton(
                          onPressed: onAgregarCarrito,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.add_shopping_cart, size: 18),
                        ),
                      ),
                    ],
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