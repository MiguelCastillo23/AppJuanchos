import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_provider.dart';
import 'auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _direccionController = TextEditingController();
  final _notasController = TextEditingController();
  
  String _tipoEntrega = 'recojo'; // 'recojo' o 'delivery'
  bool _isLoading = false;

  @override
  void dispose() {
    _direccionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  double get costoDelivery => _tipoEntrega == 'delivery' ? 5.0 : 0.0;

  Future<void> _finalizarPedido() async {
    if (_tipoEntrega == 'delivery') {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isLoading = true);

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final authService = AuthService();
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener datos del usuario
      final datosUsuario = await authService.obtenerDatosUsuario();

      // Crear el pedido
      final pedido = {
        'usuario_id': user.uid,
        'nombre_cliente': datosUsuario?['nombre'] ?? user.displayName ?? 'Sin nombre',
        'email': user.email ?? '',
        'telefono': datosUsuario?['telefono'] ?? '',
        'fecha': FieldValue.serverTimestamp(),
        'tipo_entrega': _tipoEntrega,
        'direccion_entrega': _tipoEntrega == 'delivery' ? _direccionController.text.trim() : '',
        'notas': _notasController.text.trim(),
        'total_productos': cart.totalPrecio,
        'costo_delivery': costoDelivery,
        'total_final': cart.totalPrecio + costoDelivery,
        'cantidad_productos': cart.totalCantidad,
        'estado': 'Pendiente',
        'productos': cart.items.values.map((item) {
          return {
            'id_producto': item.id,
            'nombre': item.nombre,
            'precio': item.precio,
            'cantidad': item.cantidad,
            'subtotal': item.subtotal,
          };
        }).toList(),
      };

      await FirebaseFirestore.instance.collection('pedidos').add(pedido);

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Mostrar diálogo de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('¡Pedido realizado!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu pedido ha sido registrado exitosamente.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                        Text(
                          'S/ ${cart.totalPrecio.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (_tipoEntrega == 'delivery') ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery:', style: TextStyle(fontSize: 14)),
                          Text(
                            'S/ ${costoDelivery.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'S/ ${(cart.totalPrecio + costoDelivery).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _tipoEntrega == 'delivery'
                    ? 'Tu pedido será entregado en aproximadamente 45 minutos.'
                    : 'Tu pedido estará listo para recoger en 30 minutos.',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                cart.limpiarCarrito();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Pedido'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen del pedido
              const Text(
                'Resumen del pedido',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Productos:', style: TextStyle(fontSize: 16)),
                        Text(
                          '${cart.totalCantidad}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                        Text(
                          'S/ ${cart.totalPrecio.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tipo de entrega
              const Text(
                'Tipo de entrega',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Opción Recojo en tienda
              InkWell(
                onTap: () => setState(() => _tipoEntrega = 'recojo'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _tipoEntrega == 'recojo' ? Colors.orange : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _tipoEntrega == 'recojo' ? Colors.orange.shade50 : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.store,
                        size: 40,
                        color: _tipoEntrega == 'recojo' ? Colors.orange : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recojo en tienda',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _tipoEntrega == 'recojo' ? Colors.orange : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Listo en 30 minutos',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'GRATIS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _tipoEntrega == 'recojo' ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Opción Delivery
              InkWell(
                onTap: () => setState(() => _tipoEntrega = 'delivery'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _tipoEntrega == 'delivery' ? Colors.orange : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _tipoEntrega == 'delivery' ? Colors.orange.shade50 : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        size: 40,
                        color: _tipoEntrega == 'delivery' ? Colors.orange : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _tipoEntrega == 'delivery' ? Colors.orange : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Entrega en 45 minutos',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'S/ 5.00',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _tipoEntrega == 'delivery' ? Colors.orange : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Dirección (solo si es delivery)
              if (_tipoEntrega == 'delivery') ...[
                const Text(
                  'Dirección de entrega',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _direccionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ej: Av. San Carlos 123',
                    prefixIcon: const Icon(Icons.location_on, color: Colors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (_tipoEntrega == 'delivery' && (value == null || value.isEmpty)) {
                      return 'Ingresa tu dirección';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Notas adicionales
              const Text(
                'Notas adicionales (opcional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notasController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ej: Doble mayonesa, doble ajicito...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Total y botón
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total a pagar:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'S/ ${(cart.totalPrecio + costoDelivery).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _finalizarPedido,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Confirmar Pedido',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}