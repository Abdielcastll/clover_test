import 'package:flutter/material.dart';
import 'clover_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clover POS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CloverPOSPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CloverPOSPage extends StatefulWidget {
  const CloverPOSPage({super.key});

  @override
  State<CloverPOSPage> createState() => _CloverPOSPageState();
}

class _CloverPOSPageState extends State<CloverPOSPage> {
  final _amountController = TextEditingController(text: '1000');
  String _statusMessage = '';
  bool _isConnected = false;
  bool _isLoading = false;
  List<dynamic> _inventoryItems = [];
  Map<String, dynamic>? _selectedItem;

  @override
  void dispose() {
    _amountController.dispose();
    CloverService.disconnect();
    super.dispose();
  }

  Future<void> _initializeClover() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Conectando con Clover...';
    });

    try {
      final success = await CloverService.initialize();
      setState(() {
        _isConnected = success;
        _statusMessage = success
            ? '✅ Conexión exitosa con Clover'
            : '❌ Error al conectar con Clover';
      });

      if (success) {
        await _loadInventory();
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Cargando inventario...';
    });

    try {
      final items = await CloverService.getInventoryItems();
      setState(() {
        _inventoryItems = items;
        _statusMessage = '✅ Inventario cargado (${items.length} items)';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error al cargar inventario: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectItem(String itemId) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Obteniendo detalles del producto...';
    });

    try {
      final item = await CloverService.getItemDetails(itemId);
      setState(() {
        _selectedItem = item;
        if (item != null) {
          _amountController.text = (item['price'] ?? 0).toString();
          _statusMessage = '✅ Producto seleccionado: ${item['name']}';
        } else {
          _statusMessage = '⚠️ Producto no encontrado';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error al obtener producto: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayment() async {
    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      setState(() => _statusMessage = '⚠️ Ingrese un monto válido');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage =
          'Procesando pago de \$${(amount / 100).toStringAsFixed(2)}...';
    });

    try {
      final result = await CloverService.makePayment(amount);
      setState(() => _statusMessage = result);
    } catch (e) {
      setState(() => _statusMessage = '❌ Error en el pago: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectClover() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Desconectando de Clover...';
    });

    try {
      final success = await CloverService.disconnect();
      setState(() {
        _isConnected = !success;
        _statusMessage =
            success ? '✅ Desconexión exitosa' : '❌ Error al desconectar';
        _inventoryItems = [];
        _selectedItem = null;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clover POS'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadInventory,
              tooltip: 'Actualizar inventario',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildConnectionStatus(),
                  const SizedBox(height: 20),
                  if (_isConnected) _buildInventorySection(),
                  const SizedBox(height: 20),
                  _buildPaymentSection(),
                ],
              ),
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isConnected ? Icons.check_circle : Icons.error,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 10),
            Text(
              _isConnected ? 'Conectado a Clover' : 'Desconectado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
            const Spacer(),
            if (!_isConnected)
              ElevatedButton(
                onPressed: _isLoading ? null : _initializeClover,
                child: const Text('Conectar'),
              )
            else
              ElevatedButton(
                onPressed: _isLoading ? null : _disconnectClover,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Desconectar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: _inventoryItems.isEmpty
                  ? const Center(child: Text('No hay productos disponibles'))
                  : ListView.builder(
                      itemCount: _inventoryItems.length,
                      itemBuilder: (context, index) {
                        final item = _inventoryItems[index];
                        return ListTile(
                          title: Text(item['name'] ?? 'Sin nombre'),
                          subtitle: Text(
                              '\$${(item['price'] / 100).toStringAsFixed(2)}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectItem(item['id']),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Procesar Pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto (en centavos)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            if (_selectedItem != null)
              Text(
                'Producto: ${_selectedItem!['name']} - \$${(_selectedItem!['price'] / 100).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnected && !_isLoading ? _processPayment : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Procesar Pago'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[200],
      child: Row(
        children: [
          if (_isLoading) const CircularProgressIndicator(),
          if (_isLoading) const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage,
              style: const TextStyle(fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
