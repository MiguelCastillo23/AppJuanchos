import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'productos_screen.dart';
import 'novedades_screen.dart';
import 'carrito_screen.dart';
import 'mis_pedidos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Juanchos',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProductosScreen(),
    const NovedadesScreen(),
    const CarritoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.orange,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Productos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Novedades',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${cart.totalCantidad}'),
              isLabelVisible: cart.totalCantidad > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Carrito',
          ),
        ],
      ),
    );
  }
}