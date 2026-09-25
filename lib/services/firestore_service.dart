import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/cart_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current shop UID
  String get _shopId => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference get _shopRef => _db.collection('shops').doc(_shopId);

 // Get products collection reference
  CollectionReference get _productsRef => _shopRef.collection('products');

  // Add a new product
  Future<void> addProduct(Product product) async {
    await _productsRef.add(product.toMap());
  }

  // Stream all products
  Stream<List<Product>> getProducts() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Find product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    final query = await _productsRef.where('barcode', isEqualTo: barcode).limit(1).get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // Edit product
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _productsRef.doc(productId).update(data);
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).delete();
  }

  // ================= Expenses =================

  CollectionReference get _expensesRef => _shopRef.collection('expenses');

  Future<void> addExpense(Expense expense) async {
    await _expensesRef.add(expense.toMap());
  }

  Stream<List<Expense>> getTodayExpenses() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _expensesRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Expense.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<Expense>> getAllExpenses() {
    return _expensesRef.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Expense.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expensesRef.doc(expenseId).delete();
  }

  // ================= Invoices =================

  CollectionReference get _invoicesRef => _shopRef.collection('invoices');

  Future<int> recordInvoice({
    required List<CartItem> items,
    required double discount,
    required String paymentMethod,
  }) async {
    // .get() falls back to the local cache automatically when offline,
    // so this still works without internet (using the last-synced count).
    final shopSnapshot = await _shopRef.get();
    final currentNumber =
        (shopSnapshot.data() as Map<String, dynamic>?)?['lastInvoiceNumber'] ?? 1000;
    final newInvoiceNumber = (currentNumber as int) + 1;

    double subtotal = 0;
    for (var item in items) {
      subtotal += item.subtotal;
    }
    final total = subtotal - discount;

    final invoiceItems = items
        .map((item) => {
              'productId': item.productId,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
            })
        .toList();

    final batch = _db.batch();

    final invoiceRef = _invoicesRef.doc();
    batch.set(invoiceRef, {
      'invoiceNumber': newInvoiceNumber,
      'items': invoiceItems,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'date': Timestamp.now(),
    });

    // FieldValue.increment is an atomic field transform (not a full
    // transaction), so it's safe to queue offline too.
    batch.set(_shopRef, {'lastInvoiceNumber': FieldValue.increment(1)}, SetOptions(merge: true));
    
    for (var item in items) {
      final productRef = _productsRef.doc(item.productId);
      batch.update(productRef, {'stock': FieldValue.increment(-item.quantity)});
    }

    batch.commit().catchError((error) {
      print('Invoice sync will retry when back online: $error');
    });

    return newInvoiceNumber;
  }

  Stream<List<Invoice>> getTodayInvoices() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _invoicesRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Invoice.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<Invoice>> getAllInvoices() {
    return _invoicesRef.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Invoice.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<String> getShopName() async {
    final doc = await _shopRef.get();
    final data = doc.data() as Map<String, dynamic>?;
    return data?['shopName'] ?? 'My Shop';
  }
    Future<Map<String, dynamic>> getShopProfile() async {
    final doc = await _shopRef.get();
    return (doc.data() as Map<String, dynamic>?) ?? {};
  }

  Future<void> updateShopProfile({
    required String shopName,
    required String ownerName,
    required String address,
    required String phone,
  }) async {
    await _shopRef.set({
      'shopName': shopName,
      'ownerName': ownerName,
      'address': address,
      'phone': phone,
    }, SetOptions(merge: true));
  }

  // Deletes all sub-collections (products, invoices, expenses) then the
  // shop document itself. Firestore client SDK can't delete a document's
  // sub-collections automatically, so each one is cleared manually.
  Future<void> deleteAllShopData() async {
    await _deleteCollection(_productsRef);
    await _deleteCollection(_invoicesRef);
    await _deleteCollection(_expensesRef);
    await _shopRef.delete();
  }

  Future<void> _deleteCollection(CollectionReference ref) async {
    final snapshot = await ref.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}