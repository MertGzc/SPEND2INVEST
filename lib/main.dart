import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/admin_panel.dart';
import 'services/app_manager.dart';
import 'services/database_service.dart';
import 'models/hive_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService().init();

  final appManager = AppManager();
  await appManager.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appManager),
      ],
      child: const TrendInvestApp(),
    ),
  );
}

const Color kPrimaryColor = Color(0xFFF27A1A); // Trendyol Orange
const Color kSecondaryColor = Color(0xFF333333); // Dark Grey
const Color kBackgroundColor = Color(0xFFFAFAFA); // Light Background

class TrendInvestApp extends StatelessWidget {
  const TrendInvestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spend2Invest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: kPrimaryColor,
          secondary: kPrimaryColor,
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kSecondaryColor,
          elevation: 0, // No elevation for modern look
          iconTheme: IconThemeData(color: kSecondaryColor),
          titleTextStyle: TextStyle(
              fontFamily: 'Poppins',
              color: kPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const RootHandler(),
    );
  }
}

class RootHandler extends StatefulWidget {
  const RootHandler({super.key});
  @override
  State<RootHandler> createState() => _RootHandlerState();
}

class _RootHandlerState extends State<RootHandler> {
  @override
  void initState() {
    super.initState();
    AppManager().addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final manager = AppManager();
    if (!manager.isLoggedIn) return const AuthScreen();
    // Admin ise yeni AdminPanel'i göster
    return manager.isAdmin ? const AdminPanel() : const MainScreen();
  }
}

// --- AUTH SCREEN ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    bool success = false;
    if (_tabController.index == 0) {
      // Giriş Yap
      success = await AppManager().login(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      // Üye Ol
      success = await AppManager().register(
        _emailController.text,
        _passwordController.text,
      );
      if (success) {
        // Kullanıcı zaten AppManager.register içinde Database'e ekleniyor
        // Otomatik giriş yap
        await AppManager().login(
          _emailController.text,
          _passwordController.text,
        );
      }
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tabController.index == 0
                ? "Giriş başarısız. Bilgilerinizi kontrol edin."
                : "Bu e-posta adresi zaten kayıtlı.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Spend2",
                  style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1)),
              const Text("invest",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w300)),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: kPrimaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  tabs: const [Tab(text: "Giriş Yap"), Tab(text: "Üye Ol")],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildForm("Giriş Yap"),
                    _buildForm("Üye Ol"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(String buttonText) {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: "E-Posta",
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Şifre",
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _submit,
            child: Text(buttonText),
          ),
        )
      ],
    );
  }
}

// --- MAIN SCREEN (TABS) ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        const HomeScreen(),
        CartScreen(onStartShopping: () {
          setState(() {
            _currentIndex = 0;
          });
        }),
        const PortfolioScreen(),
        const SettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    int cartCount = AppManager().cart.length;

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Anasayfa'),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  if (cartCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(6)),
                        constraints:
                            const BoxConstraints(minWidth: 12, minHeight: 12),
                        child: Text('$cartCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 8),
                            textAlign: TextAlign.center),
                      ),
                    )
                ],
              ),
              activeIcon: const Icon(Icons.shopping_cart),
              label: 'Sepetim',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_outline),
                activeIcon: Icon(Icons.pie_chart),
                label: 'Portföyüm'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Ayarlar'),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = [
    "Tümü",
    "Tişört",
    "Pantolon",
    "Ayakkabı",
    "Saat",
    "Gözlük",
    "Çanta"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showProfileDialog(BuildContext context) {
    final nameController =
        TextEditingController(text: AppManager().currentUserName);
    final picController =
        TextEditingController(text: AppManager().currentUserProfilePic);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Profilim"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(picController.text),
              onBackgroundImageError: (_, __) =>
                  const Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Kullanıcı Adı"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: picController,
              decoration:
                  const InputDecoration(labelText: "Profil Fotoğrafı URL"),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  AppManager().logout();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Çıkış Yap",
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              AppManager()
                  .updateProfile(nameController.text, picController.text);
              Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          ),
        ],
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content:
            const Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // Dialog kapat
              AppManager().logout();
            },
            child: const Text("Çıkış Yap"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showSearch(
                                context: context,
                                delegate: ProductSearchDelegate());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.search, color: kPrimaryColor),
                                SizedBox(width: 10),
                                Text("Marka, ürün veya kategori ara",
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showProfileDialog(context),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              NetworkImage(AppManager().currentUserProfilePic),
                          onBackgroundImageError: (_, __) =>
                              const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.logout, color: kSecondaryColor),
                        tooltip: 'Çıkış Yap',
                        onPressed: () => _showLogoutConfirmDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage('img/kampanya${index + 1}.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: kPrimaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: kPrimaryColor,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: _categories
                        .map((String category) => Tab(text: category))
                        .toList(),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: _categories.map((String category) {
              final products = (category == "Tümü")
                  ? AppManager().products
                  : AppManager()
                      .products
                      .where((p) => p.category == category)
                      .toList();

              return GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(product: product);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: kBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Hero(
                  tag: 'product_image_${product.id}',
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey[400], size: 40),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: kPrimaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${product.price.toStringAsFixed(2)} TL",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black),
                        ),
                        Material(
                          color: kPrimaryColor,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              AppManager().addToCart(product);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text("${product.name} sepete eklendi"),
                                duration: const Duration(milliseconds: 800),
                                backgroundColor: kSecondaryColor,
                                behavior: SnackBarBehavior.floating,
                              ));
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(Icons.add,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border,
                  size: 18, color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }
}

// --- CART SCREEN ---
class CartScreen extends StatefulWidget {
  final VoidCallback? onStartShopping;
  const CartScreen({super.key, this.onStartShopping});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _showCreditCardSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ödeme Bilgileri",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                labelText: "Kart Numarası",
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration:
                        InputDecoration(labelText: "Son Kul. Tar. (AA/YY)"),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: "CVV"),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  // Close sheet
                  Navigator.pop(context);

                  // Perform checkout
                  final manager = AppManager();
                  String result = await manager.checkout();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Sipariş Onaylandı"),
                        content: Text(result),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Tamam"))
                        ],
                      ),
                    );
                  }
                },
                child: const Text("Ödemeyi Tamamla"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<AppManager>(context);
    final cart = manager.cart;
    final total = manager.getCartTotal();

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sepetim")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_basket_outlined,
                    size: 60, color: kPrimaryColor),
              ),
              const SizedBox(height: 16),
              const Text("Sepetinizde ürün bulunmamaktadır.",
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onStartShopping,
                child: const Text("Alışverişe Başla"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Sepetim")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cart.length,
              itemBuilder: (context, index) {
                String productId = cart.keys.elementAt(index);
                int quantity = cart.values.elementAt(index);
                Product product =
                    manager.products.firstWhere((p) => p.id == productId);

                return Dismissible(
                  key: Key(product.id),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    manager.deleteProductFromCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${product.name} sepetten silindi"),
                        duration: const Duration(milliseconds: 1500),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: Image.network(product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    const Icon(Icons.image)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.brand,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold)),
                              Text(product.name,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text("${product.price} TL",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => manager.removeFromCart(product),
                                child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.remove,
                                        size: 16, color: kPrimaryColor)),
                              ),
                              Text("$quantity",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              InkWell(
                                onTap: () => manager.addToCart(product),
                                child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.add,
                                        size: 16, color: kPrimaryColor)),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Toplam Tutar:",
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text("${total.toStringAsFixed(2)} TL",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.savings_outlined,
                              color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text("Yatırıma Gidecek:",
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text("+${total.toStringAsFixed(2)} TL",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showCreditCardSheet,
                    child: const Text("Sepeti Onayla"),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- SETTINGS SCREEN (FUND ALLOCATION) ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, double> _tempSettings;
  final AppManager manager = AppManager();

  @override
  void initState() {
    super.initState();
    _tempSettings = Map.from(manager.investmentSettings);
  }

  void _saveSettings() {
    double total = 0;
    _tempSettings.forEach((key, value) => total += value);

    if (total.round() != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Toplam oran tam olarak %100 olmalıdır!")),
      );
      return;
    }

    manager.updateInvestmentSettings(_tempSettings);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yatırım tercihleri kaydedildi!")));
  }

  void _applyInvestmentProfile(String profile) {
    setState(() {
      _tempSettings.clear();
      for (var fund in manager.funds) {
        _tempSettings[fund.code] = 0.0;
      }

      switch (profile) {
        case 'Muhafazakar':
          // Genellikle daha az riskli, büyük fonlara yatırım
          _tempSettings[manager.funds[0].code] = 50.0;
          _tempSettings[manager.funds[1].code] = 30.0;
          _tempSettings[manager.funds[2].code] = 20.0;
          break;
        case 'Dengeli':
          // Çeşitlendirilmiş bir portföy
          _tempSettings[manager.funds[3].code] = 25.0;
          _tempSettings[manager.funds[4].code] = 25.0;
          _tempSettings[manager.funds[5].code] = 25.0;
          _tempSettings[manager.funds[6].code] = 25.0;
          break;
        case 'Risk Seven':
          // Daha küçük, potansiyel olarak daha değişken fonlara yatırım
          for (int i = 0; i < 10; i++) {
            _tempSettings[manager.funds[10 + i].code] = 10.0;
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double currentTotal = 0;
    _tempSettings.forEach((key, value) => currentTotal += value);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yatırım Ayarları"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.tonal(
              onPressed: _saveSettings,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryColor.withOpacity(0.1),
                foregroundColor: kPrimaryColor,
              ),
              child: const Text("KAYDET",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Total Allocation Indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Toplam Dağılım",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("%${currentTotal.toStringAsFixed(0)} / %100",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: currentTotal == 100
                                ? Colors.green
                                : Colors.red)),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: currentTotal / 100,
                  backgroundColor: Colors.grey[200],
                  color: currentTotal > 100 ? Colors.red : kPrimaryColor,
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 10,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Yatırımcı Profili Seçin:",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildProfileChip('Muhafazakar', Icons.shield_outlined),
                      const SizedBox(width: 8),
                      _buildProfileChip('Dengeli', Icons.balance),
                      const SizedBox(width: 8),
                      _buildProfileChip(
                          'Risk Seven', Icons.trending_up_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: manager.funds.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final fund = manager.funds[index];
                double val = _tempSettings[fund.code] ?? 0.0;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: val > 0
                            ? kPrimaryColor.withOpacity(0.5)
                            : Colors.transparent),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fund.code,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(fund.name,
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: val > 0
                                    ? kPrimaryColor.withOpacity(0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "%${val.toStringAsFixed(0)}",
                                style: TextStyle(
                                  color: val > 0 ? kPrimaryColor : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: kPrimaryColor,
                            inactiveTrackColor: Colors.grey[200],
                            thumbColor: kPrimaryColor,
                            overlayColor: kPrimaryColor.withOpacity(0.2),
                            trackHeight: 4.0,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8.0),
                          ),
                          child: Slider(
                            value: val,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: val.round().toString(),
                            onChanged: (newValue) {
                              setState(() {
                                double others = currentTotal - val;
                                if (others + newValue <= 100) {
                                  _tempSettings[fund.code] = newValue;
                                }
                              });
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: kSecondaryColor),
      label: Text(label),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey[300]!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => _applyInvestmentProfile(label),
    );
  }
}

// --- PORTFOLIO SCREEN ---
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  bool _showFinancialSummary = false;

  @override
  Widget build(BuildContext context) {
    final manager = AppManager();
    final portfolio = manager.portfolio;
    final transactions = manager.transactions.reversed.toList();

    double totalPortfolioValue = 0;
    portfolio.forEach((code, qty) {
      Fund f = manager.funds.firstWhere((element) => element.code == code);
      totalPortfolioValue += f.price * qty;
    });

    double totalSpending = transactions
        .where((t) => t.type == 'Alışveriş')
        .fold(0.0, (sum, item) => sum + item.amount.abs());
    double totalInvestment = transactions
        .where((t) => t.type == 'Yatırım')
        .fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(_showFinancialSummary ? "Finansal Özet" : "Portföyüm"),
        actions: [
          IconButton(
            icon: Icon(_showFinancialSummary
                ? Icons.pie_chart
                : Icons.bar_chart_outlined),
            onPressed: () {
              setState(() {
                _showFinancialSummary = !_showFinancialSummary;
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: kPrimaryColor,
            child: Column(
              children: [
                const Text("Toplam Varlık",
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 5),
                Text("${totalPortfolioValue.toStringAsFixed(2)} TL",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (_showFinancialSummary)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Finansal Analiz",
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryCard("Toplam Harcama",
                            totalSpending.toStringAsFixed(2), Colors.red),
                        _buildSummaryCard("Toplam Yatırım",
                            totalInvestment.toStringAsFixed(2), Colors.green),
                      ],
                    ),
                    const SizedBox(height: 30),
                    if (totalSpending > 0 || totalInvestment > 0)
                      SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: CustomPaint(
                                painter: PieChartPainter(
                                  spending: totalSpending,
                                  investment: totalInvestment,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLegendItem("Harcama", Colors.red),
                                  const SizedBox(height: 8),
                                  _buildLegendItem("Yatırım", Colors.green),
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    else
                      const Center(child: Text("Henüz veri yok.")),
                    const SizedBox(height: 30),
                    // AI Assistant Message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.blue),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Bugün harika gidiyorsun! Toplam ${totalSpending.toStringAsFixed(0)} TL harcaman karşılığında ${totalInvestment.toStringAsFixed(0)} TL yatırım yaptın. Geleceğin için bir adım daha!",
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: portfolio.isEmpty
                  ? const Center(
                      child: Text("Henüz yatırımınız bulunmuyor.",
                          style: TextStyle(color: Colors.grey, fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: portfolio.length,
                      itemBuilder: (context, index) {
                        final fundCode = portfolio.keys.elementAt(index);
                        final quantity = portfolio.values.elementAt(index);
                        final fund =
                            manager.funds.firstWhere((f) => f.code == fundCode);
                        final totalValue = quantity * fund.price;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      fund.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: kSecondaryColor,
                                      ),
                                    ),
                                    Text(
                                      "${totalValue.toStringAsFixed(2)} TL",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  fund.name,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInfoColumn(
                                        "Adet", quantity.toStringAsFixed(4)),
                                    _buildInfoColumn("Fiyat",
                                        "${fund.price.toStringAsFixed(2)} TL"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text("$value TL",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final double spending;
  final double investment;

  PieChartPainter({required this.spending, required this.investment});

  @override
  void paint(Canvas canvas, Size size) {
    double total = spending + investment;
    if (total == 0) return;

    double spendingAngle = (spending / total) * 2 * pi;
    double investmentAngle = (investment / total) * 2 * pi;

    Paint paint = Paint()..style = PaintingStyle.fill;
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw Spending Arc
    paint.color = Colors.red;
    canvas.drawArc(rect, -pi / 2, spendingAngle, true, paint);

    // Draw Investment Arc
    paint.color = Colors.green;
    canvas.drawArc(rect, -pi / 2 + spendingAngle, investmentAngle, true, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProductSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final allProducts = AppManager().products;
    final results = query.isEmpty
        ? []
        : allProducts.where((p) {
            final q = query.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.brand.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q);
          }).toList();

    if (query.isEmpty) {
      return const Center(child: Text("Aramak istediğiniz ürünü yazın"));
    }

    if (results.isEmpty) {
      return const Center(child: Text("Sonuç bulunamadı"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ProductCard(product: results[index]);
      },
    );
  }
}
