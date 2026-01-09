import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive_models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Box<User>? _userBox;
  Box<Product>? _productBox;
  Box<Fund>? _fundBox;
  Box<Transaction>? _transactionBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Adapter'ları kaydet (generated dosya import edilmeli)
    // Eğer generated dosya varsa otomatik kaydeder, yoksa manuel eklenmeli
    // build_runner çalıştığında bu adapter'lar oluşacak.
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(FundAdapter());
    Hive.registerAdapter(TransactionAdapter());

    _userBox = await Hive.openBox<User>('users');
    _productBox = await Hive.openBox<Product>('products');
    _fundBox = await Hive.openBox<Fund>('funds');
    _transactionBox = await Hive.openBox<Transaction>('transactions');

    // Başlangıç verilerini ekle (Eğer boşsa)
    await _seedDataIfNeeded();
  }

  Future<void> _seedDataIfNeeded() async {
    // Eski/Kırık URL'leri temizle (Migrasyon)
    if (_productBox!.isNotEmpty) {
      final brokenProducts = _productBox!.values
          .where((p) => p.imageUrl.contains('cdn.dsmcdn.com'))
          .toList();
      if (brokenProducts.isNotEmpty) {
        await _productBox!.clear();
      }
    }

    if (_productBox!.isEmpty) {
      final products = [
        Product(
            id: '1',
            name: 'Mavi Tişört',
            price: 150.0,
            imageUrl: 'https://picsum.photos/id/100/400/400',
            brand: 'Mavi',
            category: 'Tişört'),
        Product(
            id: '2',
            name: 'Siyah Kot',
            price: 400.0,
            imageUrl: 'https://picsum.photos/id/101/400/400',
            brand: 'Levi\'s',
            category: 'Pantolon'),
        Product(
            id: '3',
            name: 'Spor Ayakkabı',
            price: 1200.0,
            imageUrl: 'https://picsum.photos/id/102/400/400',
            brand: 'Nike',
            category: 'Ayakkabı'),
      ];
      await _productBox!.addAll(products);
    }

    if (_fundBox!.isEmpty) {
      final funds = [
        Fund(code: 'AFT', name: 'Ak Portföy Yeni Teknolojiler', price: 0.15),
        Fund(code: 'YAY', name: 'Yapı Kredi Yabancı Tek.', price: 2.30),
        Fund(code: 'TTE', name: 'İş Portföy BIST Teknoloji', price: 1.45),
        Fund(code: 'GMR', name: 'Inveo Portföy Gümüş', price: 1.80),
        Fund(code: 'AES', name: 'Ak Portföy Petrol', price: 0.90),
        Fund(code: 'KUB', name: 'Kuveyt Türk Katılım', price: 3.10),
        Fund(code: 'TI3', name: 'İş Portföy Sürdürülebilirlik', price: 1.20),
        // Daha fazla fon eklenebilir
      ];
      await _fundBox!.addAll(funds);
    }

    if (_userBox!.values.where((u) => u.email == 'admin').isEmpty) {
      final adminUser = User(
        id: 'admin_user_id',
        name: 'Sistem Yöneticisi',
        email: 'admin',
        password: 'admin',
        role: 'Yönetici',
        status: 'Aktif',
        registrationDate: DateTime.now(),
      );
      await _userBox!.put(adminUser.id, adminUser);
    }
  }

  // --- Users ---
  Future<List<User>> getAllUsers() async {
    return _userBox!.values.toList();
  }

  Future<User?> getUser(String email) async {
    try {
      return _userBox!.values.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<void> createUser(User user, String password) async {
    // Şifre zaten user objesinde olmalı ama parametre olarak geldiyse set edelim
    user.password = password;
    // user.id'yi key olarak kullanıyoruz
    await _userBox!.put(user.id, user);
  }

  Future<void> updateUser(User user) async {
    await user.save();
  }

  Future<String?> getPassword(String email) async {
    final user = await getUser(email);
    return user?.password;
  }

  // --- Products ---
  Future<List<Product>> getProducts() async {
    return _productBox!.values.toList();
  }

  Future<void> createProduct(Product product) async {
    await _productBox!.put(product.id, product);
  }

  Future<void> updateProduct(Product product) async {
    await product.save();
  }

  Future<void> deleteProduct(String id) async {
    await _productBox!.delete(id);
  }

  // --- Funds ---
  Future<List<Fund>> getFunds() async {
    return _fundBox!.values.toList();
  }

  Future<void> createFund(Fund fund) async {
    await _fundBox!.put(fund.code, fund);
  }

  Future<void> updateFund(Fund fund) async {
    await fund.save();
  }

  Future<void> deleteFund(String code) async {
    await _fundBox!.delete(code);
  }

  // --- Transactions ---
  Future<List<Transaction>> getTransactions(String userId) async {
    return _transactionBox!.values.where((t) => t.userId == userId).toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactionBox!.add(transaction);
  }
}
