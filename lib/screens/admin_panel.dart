import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/hive_models.dart';
import '../services/app_manager.dart';
import '../services/database_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_widget.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _destinations = [
    {
      'icon': Icons.dashboard_outlined,
      'selectedIcon': Icons.dashboard,
      'label': 'Dashboard',
    },
    {
      'icon': Icons.people_outline,
      'selectedIcon': Icons.people,
      'label': 'Kullanıcılar',
    },
    {
      'icon': Icons.inventory_2_outlined,
      'selectedIcon': Icons.inventory_2,
      'label': 'Ürünler',
    },
    {
      'icon': Icons.category_outlined,
      'selectedIcon': Icons.category,
      'label': 'Kategoriler',
    },
    {
      'icon': Icons.pie_chart_outline,
      'selectedIcon': Icons.pie_chart,
      'label': 'Fonlar',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Yönetici Paneli',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Provider.of<AppManager>(context, listen: false).logout();
                },
              ),
            ],
          ),
          body: isMobile
              ? _buildBody()
              : Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (int index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      labelType: NavigationRailLabelType.all,
                      leading: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.admin_panel_settings,
                            size: 40, color: Colors.blue[800]),
                      ),
                      destinations: _destinations
                          .map(
                            (d) => NavigationRailDestination(
                              icon: Icon(d['icon']),
                              selectedIcon: Icon(d['selectedIcon']),
                              label: Text(d['label']),
                            ),
                          )
                          .toList(),
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(
                      child: _buildBody(),
                    ),
                  ],
                ),
          bottomNavigationBar: isMobile
              ? BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  type: BottomNavigationBarType.fixed,
                  items: _destinations
                      .map(
                        (d) => BottomNavigationBarItem(
                          icon: Icon(d['icon']),
                          activeIcon: Icon(d['selectedIcon']),
                          label: d['label'],
                        ),
                      )
                      .toList(),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardView();
      case 1:
        return const UsersView();
      case 2:
        return const ProductsView();
      case 3:
        return const CategoriesView();
      case 4:
        return const FundsView();
      default:
        return const Center(child: Text('Sayfa Bulunamadı'));
    }
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: DatabaseService().getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];
        final totalUsers = users.length;
        final activeUsers = users.where((u) => u.status == 'Aktif').length;
        final systemUsers = users.where((u) => u.role == 'Yönetici').length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final padding = isMobile ? 16.0 : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genel Bakış',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildStatCardWrapper(
                        constraints,
                        StatCard(
                          title: 'Toplam Kullanıcı',
                          value: totalUsers.toString(),
                          icon: Icons.group,
                          color: Colors.blue,
                        ),
                      ),
                      _buildStatCardWrapper(
                        constraints,
                        StatCard(
                          title: 'Aktif Kullanıcı',
                          value: activeUsers.toString(),
                          icon: Icons.person_add,
                          color: Colors.green,
                        ),
                      ),
                      _buildStatCardWrapper(
                        constraints,
                        StatCard(
                          title: 'Sistem Kullanıcısı',
                          value: systemUsers.toString(),
                          icon: Icons.computer,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
                  Text(
                    'Aylık Aktivite Grafiği',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: isMobile ? 300 : 400,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const ChartWidget(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCardWrapper(BoxConstraints constraints, Widget child) {
    double width;
    if (constraints.maxWidth > 800) {
      width =
          (constraints.maxWidth - 40 - 48) / 3; // 3 sütun (paddingler düşüldü)
    } else if (constraints.maxWidth > 500) {
      width = (constraints.maxWidth - 20 - 32) / 2; // 2 sütun
    } else {
      width = constraints.maxWidth; // 1 sütun
    }
    return SizedBox(width: width, child: child);
  }
}

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: DatabaseService().getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final padding = isMobile ? 16.0 : 24.0;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kullanıcı Listesi',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                user.name.isNotEmpty ? user.name[0] : '?',
                                style: TextStyle(color: Colors.blue.shade900),
                              ),
                            ),
                            title: Text(user.name,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                            subtitle:
                                Text(user.email, style: GoogleFonts.poppins()),
                            trailing: isMobile
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildStatusBadge(user.status,
                                          isMobile: true),
                                      const SizedBox(height: 4),
                                      Text(user.role,
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey)),
                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStatusBadge(user.status),
                                      const SizedBox(width: 8),
                                      Text(user.role,
                                          style: GoogleFonts.poppins(
                                              color: Colors.grey)),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, {bool isMobile = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'Aktif'
            ? Colors.green.shade100
            : status == 'Pasif'
                ? Colors.red.shade100
                : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: isMobile ? 10 : 12,
          color: status == 'Aktif'
              ? Colors.green.shade900
              : status == 'Pasif'
                  ? Colors.red.shade900
                  : Colors.orange.shade900,
        ),
      ),
    );
  }
}

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  void _showAddProductDialog(BuildContext context) {
    final manager = Provider.of<AppManager>(context, listen: false);
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final brandController = TextEditingController();
    final stockController = TextEditingController();
    final colorsController = TextEditingController();
    final imgController =
        TextEditingController(text: "https://picsum.photos/200/300");
    String selectedCategory =
        manager.categories.isNotEmpty ? manager.categories.first : "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Ürün Ekle"),
              scrollable: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Ürün Adı"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: brandController,
                    decoration: const InputDecoration(labelText: "Marka"),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: "Fiyat"),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          decoration: const InputDecoration(labelText: "Stok"),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: colorsController,
                    decoration: const InputDecoration(
                        labelText: "Renkler (Virgülle ayırın)"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: imgController,
                    decoration: const InputDecoration(labelText: "Görsel URL"),
                  ),
                  const SizedBox(height: 16),
                  if (manager.categories.isNotEmpty)
                    DropdownButton<String>(
                      value:
                          selectedCategory.isNotEmpty ? selectedCategory : null,
                      hint: const Text("Kategori Seç"),
                      isExpanded: true,
                      items: manager.categories
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCategory = val!),
                    )
                  else
                    const Text("Önce kategori eklemelisiniz."),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        priceController.text.isNotEmpty &&
                        selectedCategory.isNotEmpty) {
                      List<String> colors = colorsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      manager.addProduct(Product(
                        id: "prod_${DateTime.now().millisecondsSinceEpoch}",
                        name: nameController.text,
                        price: double.tryParse(priceController.text) ?? 0,
                        imageUrl: imgController.text,
                        brand: brandController.text,
                        category: selectedCategory,
                        stock: int.tryParse(stockController.text) ?? 0,
                        colors: colors,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Ekle"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final manager = Provider.of<AppManager>(context, listen: false);
    final nameController = TextEditingController(text: product.name);
    final priceController =
        TextEditingController(text: product.price.toString());
    final stockController =
        TextEditingController(text: product.stock.toString());
    final imgController = TextEditingController(text: product.imageUrl);
    final brandController = TextEditingController(text: product.brand);
    final colorsController =
        TextEditingController(text: product.colors.join(', '));
    String selectedCategory = product.category;

    if (!manager.categories.contains(selectedCategory) &&
        manager.categories.isNotEmpty) {
      selectedCategory = manager.categories.first;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("${product.name} Güncelle"),
              scrollable: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Ürün Adı"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: brandController,
                    decoration: const InputDecoration(labelText: "Marka"),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: "Fiyat"),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          decoration:
                              const InputDecoration(labelText: "Stok Adedi"),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: colorsController,
                    decoration: const InputDecoration(
                        labelText: "Renkler (Virgülle ayırın)"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: imgController,
                    decoration: const InputDecoration(labelText: "Görsel URL"),
                  ),
                  const SizedBox(height: 16),
                  if (manager.categories.isNotEmpty)
                    DropdownButton<String>(
                      value: selectedCategory,
                      hint: const Text("Kategori Seç"),
                      isExpanded: true,
                      items: manager.categories
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedCategory = val);
                        }
                      },
                    )
                  else
                    const Text("Önce kategori eklemelisiniz."),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    double? newPrice = double.tryParse(priceController.text);
                    int? newStock = int.tryParse(stockController.text);

                    if (nameController.text.isNotEmpty &&
                        newPrice != null &&
                        newStock != null &&
                        selectedCategory.isNotEmpty) {
                      List<String> colors = colorsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      product.name = nameController.text;
                      product.price = newPrice;
                      product.stock = newStock;
                      product.imageUrl = imgController.text;
                      product.brand = brandController.text;
                      product.category = selectedCategory;
                      product.colors = colors;

                      manager.updateProduct(product);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Güncelle"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<AppManager>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ürün Yönetimi',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (!isMobile)
                    ElevatedButton.icon(
                      onPressed: () => _showAddProductDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Yeni Ürün Ekle"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddProductDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Yeni Ürün Ekle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
              SizedBox(height: isMobile ? 16 : 24),
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    itemCount: manager.products.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final product = manager.products[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16, vertical: 8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              width: 50,
                              height: 50,
                              child: const Icon(Icons.image),
                            ),
                          ),
                        ),
                        title: Text(product.name,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 14 : 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${product.brand} - ${product.category}",
                                style: GoogleFonts.poppins(fontSize: 12)),
                            Text("Stok: ${product.stock}",
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: isMobile
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditProductDialog(context, product);
                                  } else if (value == 'delete') {
                                    manager.removeProduct(product.id);
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit,
                                              color: Colors.blue, size: 20),
                                          SizedBox(width: 8),
                                          Text('Düzenle'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              color: Colors.red, size: 20),
                                          SizedBox(width: 8),
                                          Text('Sil'),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("${product.price} TL",
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                    const Icon(Icons.more_vert),
                                  ],
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("${product.price} TL",
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _showEditProductDialog(
                                        context, product),
                                    tooltip: "Düzenle",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        manager.removeProduct(product.id),
                                    tooltip: "Sil",
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<AppManager>(context);
    final TextEditingController controller = TextEditingController();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori Yönetimi',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              if (isMobile) ...[
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: "Yeni Kategori Adı",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        manager.addCategory(controller.text);
                        controller.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Ekle"),
                  ),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: "Yeni Kategori Adı",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          manager.addCategory(controller.text);
                          controller.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                      ),
                      child: const Text("Ekle"),
                    )
                  ],
                ),
              SizedBox(height: isMobile ? 16 : 24),
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    itemCount: manager.categories.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final category = manager.categories[index];
                      return ListTile(
                        title: Text(category, style: GoogleFonts.poppins()),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => manager.removeCategory(category),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FundsView extends StatelessWidget {
  const FundsView({super.key});

  void _showAddFundDialog(BuildContext context) {
    final manager = Provider.of<AppManager>(context, listen: false);
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Fon Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration:
                  const InputDecoration(labelText: "Fon Kodu (Örn: AFT)"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Fon Adı"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Fiyat"),
              keyboardType: TextInputType.number,
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
              double? price = double.tryParse(priceController.text);
              if (codeController.text.isNotEmpty &&
                  nameController.text.isNotEmpty &&
                  price != null) {
                manager.addFund(Fund(
                  code: codeController.text.toUpperCase(),
                  name: nameController.text,
                  price: price,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text("Ekle"),
          ),
        ],
      ),
    );
  }

  void _showEditFundDialog(BuildContext context, Fund fund) {
    final manager = Provider.of<AppManager>(context, listen: false);
    final nameController = TextEditingController(text: fund.name);
    final priceController = TextEditingController(text: fund.price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${fund.code} Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Fon Adı"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Fiyat"),
              keyboardType: TextInputType.number,
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
              double? price = double.tryParse(priceController.text);
              if (nameController.text.isNotEmpty && price != null) {
                fund.name = nameController.text;
                fund.price = price;
                manager.updateFund(fund);
                Navigator.pop(context);
              }
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<AppManager>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fon Yönetimi',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (!isMobile)
                    ElevatedButton.icon(
                      onPressed: () => _showAddFundDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Yeni Fon Ekle"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddFundDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Yeni Fon Ekle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
              SizedBox(height: isMobile ? 16 : 24),
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    itemCount: manager.funds.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final fund = manager.funds[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            fund.code.substring(0, 1),
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text("${fund.code} - ${fund.name}",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 14 : 16)),
                        trailing: isMobile
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditFundDialog(context, fund);
                                  } else if (value == 'delete') {
                                    manager.removeFund(fund.code);
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit,
                                              color: Colors.blue, size: 20),
                                          SizedBox(width: 8),
                                          Text('Düzenle'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              color: Colors.red, size: 20),
                                          SizedBox(width: 8),
                                          Text('Sil'),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("${fund.price} TL",
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                    const Icon(Icons.more_vert),
                                  ],
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("${fund.price} TL",
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _showEditFundDialog(context, fund),
                                    tooltip: "Düzenle",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        manager.removeFund(fund.code),
                                    tooltip: "Sil",
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
