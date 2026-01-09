import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hive_models.dart';
import 'database_service.dart';

// --- STATE MANAGEMENT ---
class AppManager extends ChangeNotifier {
  static final AppManager _instance = AppManager._internal();
  factory AppManager() => _instance;
  AppManager._internal();

  final DatabaseService _db = DatabaseService();

  bool isLoggedIn = false;
  bool isAdmin = false;
  User? currentUser;

  List<String> categories = [];

  List<Product> _products = [];
  List<Fund> _funds = [];
  List<Transaction> _transactions = [];

  Map<String, int> get cart => currentUser?.cart ?? {};
  Map<String, double> get portfolio => currentUser?.portfolio ?? {};
  Map<String, double> get investmentSettings =>
      currentUser?.investmentSettings ?? {};

  List<Product> get products => _products;
  List<Fund> get funds => _funds;
  List<Transaction> get transactions => _transactions;

  Future<void> init() async {
    categories = ["Tişört", "Pantolon", "Ayakkabı", "Saat", "Gözlük", "Çanta"];

    await _fetchData();

    // Otomatik giriş kontrolü
    await _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      final user = await _db.getUser(email);
      if (user != null) {
        _setCurrentUser(user);
        print("Otomatik giriş yapıldı: $email");
      }
    }
  }

  Future<void> _fetchData() async {
    _products = await _db.getProducts();
    _funds = await _db.getFunds();
    if (currentUser != null) {
      _transactions = await _db.getTransactions(currentUser!.id);
    }
    notifyListeners();
  }

  // Actions
  void addCategory(String category) {
    if (!categories.contains(category)) {
      categories.add(category);
      notifyListeners();
    }
  }

  void removeCategory(String category) {
    categories.remove(category);
    notifyListeners();
  }

  // --- Admin CRUD Operations ---

  Future<void> addProduct(Product product) async {
    await _db.createProduct(product);
    await _fetchData(); // Listeyi yenile
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    await _fetchData();
  }

  Future<void> removeProduct(String productId) async {
    await _db.deleteProduct(productId);
    await _fetchData();
  }

  Future<void> addFund(Fund fund) async {
    await _db.createFund(fund);
    await _fetchData();
  }

  Future<void> updateFund(Fund fund) async {
    await _db.updateFund(fund);
    await _fetchData();
  }

  Future<void> removeFund(String fundCode) async {
    await _db.deleteFund(fundCode);
    await _fetchData();
  }

  Future<bool> register(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    User? existingUser = await _db.getUser(cleanEmail);
    if (existingUser != null) {
      return false; // Kullanıcı zaten var
    }

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: cleanEmail.split('@')[0],
      email: cleanEmail,
      password: password,
      role: 'Kullanıcı',
      status: 'Aktif',
      registrationDate: DateTime.now(),
    );

    await _db.createUser(newUser, password);

    // Kayıt sonrası otomatik giriş için kaydedelim mi?
    // AuthScreen'de kayıt sonrası login çağrıldığı için orada kaydederiz.

    notifyListeners();
    return true;
  }

  void _setCurrentUser(User user) {
    currentUser = user;
    isLoggedIn = true;
    isAdmin = user.role == 'Yönetici';

    // Kullanıcının yatırım ayarları boşsa, varsayılanı ata
    if (user.investmentSettings.isEmpty && funds.isNotEmpty) {
      for (var fund in funds) {
        user.investmentSettings[fund.code] = 0.0;
      }
      user.investmentSettings[funds.first.code] = 100.0;
    }

    _fetchData(); // Kullanıcıya özel transactionları çek
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail == "admin" && password == "admin") {
      User? adminUser = await _db.getUser('admin');
      if (adminUser != null) {
        _setCurrentUser(adminUser);
        // Admin için de kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', 'admin');
        return true;
      }
    }

    User? user = await _db.getUser(cleanEmail);
    if (user != null) {
      String? dbPassword = await _db.getPassword(cleanEmail);
      if (dbPassword == password) {
        _setCurrentUser(user);

        // Başarılı girişte kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', cleanEmail);

        return true;
      }
    }
    return false;
  }

  Future<void> updateProfile(String name, String picUrl) async {
    if (currentUser != null) {
      currentUser!.name = name;
      // picUrl şimdilik saklanmıyor
      await _db.updateUser(currentUser!);
      notifyListeners();
    }
  }

  String get currentUserName => currentUser?.name ?? "Misafir";
  String get currentUserProfilePic => "https://picsum.photos/200";

  void logout() async {
    isLoggedIn = false;
    isAdmin = false;
    currentUser = null;
    _transactions = [];

    // Çıkış yapınca sil
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');

    notifyListeners();
  }

  Future<void> addToCart(Product product) async {
    if (currentUser == null) return;
    if (currentUser!.cart.containsKey(product.id)) {
      currentUser!.cart[product.id] = currentUser!.cart[product.id]! + 1;
    } else {
      currentUser!.cart[product.id] = 1;
    }
    await _db.updateUser(currentUser!);
    notifyListeners();
  }

  Future<void> removeFromCart(Product product) async {
    if (currentUser == null) return;
    if (currentUser!.cart.containsKey(product.id) &&
        currentUser!.cart[product.id]! > 1) {
      currentUser!.cart[product.id] = currentUser!.cart[product.id]! - 1;
    } else {
      currentUser!.cart.remove(product.id);
    }
    await _db.updateUser(currentUser!);
    notifyListeners();
  }

  Future<void> deleteProductFromCart(Product product) async {
    if (currentUser == null) return;
    currentUser!.cart.remove(product.id);
    await _db.updateUser(currentUser!);
    notifyListeners();
  }

  double getCartTotal() {
    if (currentUser == null) return 0.0;
    double total = 0;
    currentUser!.cart.forEach((key, quantity) {
      try {
        Product p = products.firstWhere((element) => element.id == key);
        total += p.price * quantity;
      } catch (e) {
        // Ürün silinmiş olabilir
      }
    });
    return total;
  }

  Future<String> checkout() async {
    if (currentUser == null || currentUser!.cart.isEmpty) return "Sepet boş!";

    double cartTotal = getCartTotal();
    double investmentAmount = cartTotal;

    double totalWeight = 0;
    currentUser!.investmentSettings
        .forEach((key, value) => totalWeight += value);

    if (totalWeight.round() != 100 && funds.isNotEmpty) {
      currentUser!.investmentSettings.clear();
      for (var f in funds) {
        currentUser!.investmentSettings[f.code] = 0.0;
      }
      currentUser!.investmentSettings[funds.first.code] = 100.0;
      totalWeight = 100.0;
    }

    if (funds.isNotEmpty && totalWeight > 0) {
      currentUser!.investmentSettings.forEach((fundCode, percentage) {
        if (percentage > 0) {
          double amountForThisFund =
              (investmentAmount * percentage) / totalWeight;
          try {
            Fund fund = funds.firstWhere((f) => f.code == fundCode);
            double unitsToBuy = amountForThisFund / fund.price;

            if (currentUser!.portfolio.containsKey(fundCode)) {
              currentUser!.portfolio[fundCode] =
                  currentUser!.portfolio[fundCode]! + unitsToBuy;
            } else {
              currentUser!.portfolio[fundCode] = unitsToBuy;
            }
          } catch (e) {
            print("Fon bulunamadı: $fundCode");
          }
        }
      });
    }

    await _db.addTransaction(Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser!.id,
      type: 'Alışveriş',
      description: '${currentUser!.cart.length} adet ürün satın alındı',
      amount: -cartTotal,
      date: DateTime.now(),
    ));

    await _db.addTransaction(Transaction(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      userId: currentUser!.id,
      type: 'Yatırım',
      description: 'Fon alımı',
      amount: investmentAmount,
      date: DateTime.now(),
    ));

    // Transactionları güncelle
    _transactions = await _db.getTransactions(currentUser!.id);

    currentUser!.cart.clear();
    await _db.updateUser(currentUser!);
    notifyListeners();
    return "Sipariş alındı! ${investmentAmount.toStringAsFixed(2)} TL değerinde fon yatırımı yapıldı.";
  }

  Future<void> updateInvestmentSettings(Map<String, double> newSettings) async {
    if (currentUser == null) return;
    currentUser!.investmentSettings = newSettings;
    await _db.updateUser(currentUser!);
    notifyListeners();
  }
}
