import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/empresa_provider.dart';
import 'dashboard_screen.dart';

class RegistroEmpresaScreen extends StatefulWidget {
  const RegistroEmpresaScreen({super.key});

  @override
  State<RegistroEmpresaScreen> createState() => _RegistroEmpresaScreenState();
}

class _RegistroEmpresaScreenState extends State<RegistroEmpresaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rucController = TextEditingController();
  final _nombreController = TextEditingController();
  final _sectorController = TextEditingController();
  final _numTrabajadoresController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _rucController.dispose();
    _nombreController.dispose();
    _sectorController.dispose();
    _numTrabajadoresController.dispose();
    super.dispose();
  }

  Future<void> _guardarEmpresa() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<EmpresaProvider>(context, listen: false);
      await provider.crearEmpresa(
        ruc: _rucController.text.trim(),
        nombre: _nombreController.text.trim(),
        sector: _sectorController.text.trim(),
        numTrabajadores: int.parse(_numTrabajadoresController.text),
      );
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos de la empresa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _rucController,
                decoration: const InputDecoration(labelText: 'RUC'),
                validator: (v) => v != null && v.length == 11 ? null : 'RUC debe tener 11 dígitos',
              ),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Razón social'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Requerido',
              ),
              TextFormField(
                controller: _sectorController,
                decoration: const InputDecoration(labelText: 'Sector (ej. construcción, pesca, agro)'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Requerido',
              ),
              TextFormField(
                controller: _numTrabajadoresController,
                decoration: const InputDecoration(labelText: 'Número de trabajadores'),
                keyboardType: TextInputType.number,
                validator: (v) => v != null && int.tryParse(v) != null ? null : 'Debe ser número',
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _guardarEmpresa,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Guardar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
