import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmpresaProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _empresaExiste = false;

  bool get empresaExiste => _empresaExiste;

  Future<void> checkEmpresa() async {
    final user = _auth.currentUser;
    if (user == null) {
      _empresaExiste = false;
      notifyListeners();
      return;
    }
    final doc = await _firestore.collection('empresas').doc(user.uid).get();
    _empresaExiste = doc.exists;
    notifyListeners();
  }

  Future<void> crearEmpresa({
    required String ruc,
    required String nombre,
    required String sector,
    required int numTrabajadores,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    await _firestore.collection('empresas').doc(user.uid).set({
      'ruc': ruc,
      'nombre': nombre,
      'sector': sector,
      'numTrabajadores': numTrabajadores,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': user.uid,
    });
    _empresaExiste = true;
    notifyListeners();
  }
}
