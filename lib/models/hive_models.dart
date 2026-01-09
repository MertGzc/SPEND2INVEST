import 'package:hive/hive.dart';

part 'hive_models.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String password; // Şifreyi de saklamamız gerekecek

  @HiveField(4)
  String role;

  @HiveField(5)
  String status;

  @HiveField(6)
  DateTime registrationDate;

  @HiveField(7)
  Map<String, int> cart;

  @HiveField(8)
  Map<String, double> portfolio;

  @HiveField(9)
  Map<String, double> investmentSettings;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'Kullanıcı',
    this.status = 'Aktif',
    required this.registrationDate,
    Map<String, int>? cart,
    Map<String, double>? portfolio,
    Map<String, double>? investmentSettings,
  })  : cart = cart ?? {},
        portfolio = portfolio ?? {},
        investmentSettings = investmentSettings ?? {};
}

@HiveType(typeId: 1)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  String imageUrl;

  @HiveField(4)
  String brand;

  @HiveField(5)
  String category;

  @HiveField(6)
  int stock;

  @HiveField(7)
  List<String> colors;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.brand,
    required this.category,
    this.stock = 0,
    this.colors = const [],
  });
}

@HiveType(typeId: 2)
class Fund extends HiveObject {
  @HiveField(0)
  String code;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  Fund({required this.code, required this.name, required this.price});
}

@HiveType(typeId: 3)
class Transaction extends HiveObject {
  @HiveField(0)
  String
      id; // Int yerine String ID kullanmak Hive ile daha uyumlu olabilir, uuid kullanırız.

  @HiveField(1)
  String userId;

  @HiveField(2)
  String type;

  @HiveField(3)
  String description;

  @HiveField(4)
  double amount;

  @HiveField(5)
  DateTime date;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
  });
}
