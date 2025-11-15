import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/credit_product.dart';

class CreditProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene todos los productos de crédito para una microfinanciera específica
  Future<List<CreditProduct>> getProductsByMfId(String mfId) async {
    try {
      final querySnapshot = await _firestore
          .collection('microfinancieras')
          .doc(mfId)
          .collection('products')
          .get();

      return querySnapshot.docs
          .map((doc) => CreditProduct.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos de crédito: $e');
    }
  }

  /// Obtiene un producto específico por su ID
  Future<CreditProduct?> getProductById(String mfId, String productId) async {
    try {
      final docSnapshot = await _firestore
          .collection('microfinancieras')
          .doc(mfId)
          .collection('products')
          .doc(productId)
          .get();

      if (docSnapshot.exists) {
        return CreditProduct.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  /// Obtiene productos que permiten un monto específico
  Future<List<CreditProduct>> getProductsByAmountRange(String mfId, double amount) async {
    try {
      final querySnapshot = await _firestore
          .collection('microfinancieras')
          .doc(mfId)
          .collection('products')
          .where('amountMin', isLessThanOrEqualTo: amount)
          .where('amountMax', isGreaterThanOrEqualTo: amount)
          .get();

      return querySnapshot.docs
          .map((doc) => CreditProduct.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos por rango de monto: $e');
    }
  }

  /// Stream para escuchar cambios en los productos en tiempo real
  Stream<List<CreditProduct>> getProductsStream(String mfId) {
    return _firestore
        .collection('microfinancieras')
        .doc(mfId)
        .collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CreditProduct.fromFirestore(doc))
            .toList());
  }
}