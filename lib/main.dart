import 'package:flutter/material.dart';
import 'clover_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clover Test App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CloverTestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CloverTestPage extends StatefulWidget {
  const CloverTestPage({super.key});

  @override
  State<CloverTestPage> createState() => _CloverTestPageState();
}

class _CloverTestPageState extends State<CloverTestPage> {
  final _amountController = TextEditingController(text: '1000');
  String _paymentStatus = '';
  bool _isConnected = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    CloverService.disconnect(); // Limpieza al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clover SDK Test'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 30),
            _buildPaymentForm(),
            const SizedBox(height: 30),
            _buildActionButtons(),
            const SizedBox(height: 30),
            _buildLogOutput(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.payment, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              'Estado: ${_isConnected ? 'CONECTADO' : 'DESCONECTADO'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _isConnected
                  ? 'Listo para procesar pagos'
                  : 'Conecta el dispositivo Clover',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simular Pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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
            const Text(
              'Ejemplo: 1000 = \$10.00',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.link),
          label: const Text('Conectar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          onPressed: _isConnected ? null : _initializeClover,
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.payment),
          label: const Text('Pagar'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          onPressed: _isConnected && !_isProcessing ? _makePayment : null,
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.link_off),
          label: const Text('Desconectar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          onPressed: _isConnected ? _disconnectClover : null,
        ),
      ],
    );
  }

  Widget _buildLogOutput() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registro de Actividad',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              _paymentStatus.isEmpty
                  ? 'No hay actividad reciente...'
                  : _paymentStatus,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            if (_isProcessing) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeClover() async {
    setState(() {
      _isProcessing = true;
      _paymentStatus = 'Inicializando conexión con Clover...';
    });

    try {
      final success = await CloverService.initialize();

      setState(() {
        _isConnected = success;
        _paymentStatus = success
            ? '✅ Dispositivo Clover conectado correctamente'
            : '❌ Error al conectar con Clover';
      });
    } catch (e) {
      setState(() {
        _paymentStatus = '❌ Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _makePayment() async {
    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      setState(() => _paymentStatus = '⚠️ Ingrese un monto válido');
      return;
    }

    setState(() {
      _isProcessing = true;
      _paymentStatus =
          'Procesando pago por \$${(amount / 100).toStringAsFixed(2)}...';
    });

    try {
      final result = await CloverService.makePayment(amount);
      setState(() => _paymentStatus = result);
    } catch (e) {
      setState(() => _paymentStatus = '❌ Error en el pago: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _disconnectClover() async {
    setState(() {
      _isProcessing = true;
      _paymentStatus = 'Desconectando dispositivo Clover...';
    });

    try {
      final success = await CloverService.disconnect();
      setState(() {
        _isConnected = !success;
        _paymentStatus = success
            ? '✅ Dispositivo Clover desconectado correctamente'
            : '❌ Error al desconectar Clover';
      });
    } catch (e) {
      setState(() {
        _paymentStatus = '❌ Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
