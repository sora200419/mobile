// lib/tabs/marketplace_tab.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/features/marketplace/models/product_model.dart';
import 'package:mobiletesting/features/marketplace/services/marketplace_service.dart';
import 'package:mobiletesting/features/marketplace/services/chat_service.dart';
import 'package:mobiletesting/features/marketplace/views/add_product_screen.dart';
import 'package:mobiletesting/features/marketplace/views/my_transactions_screen.dart';
import 'package:mobiletesting/features/marketplace/widgets/product_card.dart';

class MarketplaceTab extends StatefulWidget {
  const MarketplaceTab({Key? key}) : super(key: key);

  @override
  State<MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends State<MarketplaceTab>
    with SingleTickerProviderStateMixin {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showFilters = false;
  RangeValues _priceRange = const RangeValues(0, 50000);
  String _selectedCondition = 'All';
  String _sortBy = 'Newest';

  final List<String> _categories = [
    'All',
    'Books',
    'Electronics',
    'Furniture',
    'Clothing',
    'Other',
  ];

  final List<String> _conditions = [
    'All',
    Product.CONDITION_NEW,
    Product.CONDITION_LIKE_NEW,
    Product.CONDITION_GOOD,
    Product.CONDITION_FAIR,
    Product.CONDITION_POOR,
  ];

  final List<String> _sortOptions = [
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
          // Force refresh after adding a product and switch to "My Listings" tab
          setState(() {
            _tabController.animateTo(1); // Index 1 is the "My Listings" tab
          });
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search and filter bar
          _buildSearchBar(),

          // Category selection
          _buildCategoryChips(),

          // Filter section (expandable)
          if (_showFilters) _buildFilterSection(),

          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: [
              const Tab(text: "Browse"),
              const Tab(text: "My Listings"),
              const Tab(text: "Favorites"),
              StreamBuilder<int>(
                stream: _chatService.getTotalUnreadCount(),
                builder: (context, snapshot) {
                  int count = snapshot.data ?? 0;
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Orders"),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Browse Tab
                _buildBrowseTab(),

                // My Listings Tab
                _buildProductGrid(_marketplaceService.getMyProducts()),

                // Favorites Tab
                _buildProductGrid(_marketplaceService.getFavoriteProducts()),

                // Orders Tab
                MyTransactionsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search marketplace...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.tune,
              color: _showFilters ? Colors.deepPurple : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0),
            child: ChoiceChip(
              label: Text(_categories[index]),
              selected: _selectedCategory == _categories[index],
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = _categories[index];
                });
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.deepPurple.shade100,
              labelStyle: TextStyle(
                color:
                    _selectedCategory == _categories[index]
                        ? Colors.deepPurple
                        : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price Range Slider
          const Text(
            'Price Range (RM)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(
                'RM ${_priceRange.start.toInt()}',
                style: const TextStyle(fontSize: 12),
              ),
              Expanded(
                child: RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 50000,
                  divisions: 500,
                  labels: RangeLabels(
                    'RM ${_priceRange.start.toInt()}',
                    'RM ${_priceRange.end.toInt()}',
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _priceRange = values;
                    });
                  },
                ),
              ),
              Text(
                'RM ${_priceRange.end.toInt()}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),

          // Condition Dropdown
          Row(
            children: [
              const Text(
                'Condition:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedCondition,
                  isExpanded: true,
                  underline: Container(height: 1, color: Colors.grey.shade400),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCondition = newValue!;
                    });
                  },
                  items:
                      _conditions.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),

          // Sort By Dropdown
          Row(
            children: [
              const Text(
                'Sort By:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  underline: Container(height: 1, color: Colors.grey.shade400),
                  onChanged: (String? newValue) {
                    setState(() {
                      _sortBy = newValue!;
                    });
                  },
                  items:
                      _sortOptions.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),

          // Apply / Reset buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _priceRange = const RangeValues(0, 50000);
                    _selectedCondition = 'All';
                    _sortBy = 'Newest';
                    _selectedCategory = 'All';
                  });
                },
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Apply filters
                  setState(() {
                    _showFilters = false;
                  });
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseTab() {
    // If searching
    if (_searchQuery.isNotEmpty) {
      return _buildProductGrid(
        _marketplaceService.searchProducts(_searchQuery),
      );
    }

    // If category filter is applied
    if (_selectedCategory != 'All') {
      return _buildProductGrid(
        _marketplaceService.getProductsByCategory(_selectedCategory),
      );
    }

    // Default: all available products
    return _buildProductGrid(_marketplaceService.getAvailableProducts());
  }

  Widget _buildProductGrid(Stream<List<Product>> productsStream) {
    return StreamBuilder<List<Product>>(
      stream: productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<Product> products = snapshot.data ?? [];

        // Apply additional filters
        if (_selectedCondition != 'All') {
          products =
              products.where((p) => p.condition == _selectedCondition).toList();
        }

        products =
            products
                .where(
                  (p) =>
                      p.price >= _priceRange.start &&
                      p.price <= _priceRange.end,
                )
                .toList();

        // Apply sorting
        switch (_sortBy) {
          case 'Newest':
            products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
          case 'Price: Low to High':
            products.sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'Price: High to Low':
            products.sort((a, b) => b.price.compareTo(a.price));
            break;
        }

        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No items found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Try adjusting your filters',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            Product product = products[index];
            return FutureBuilder<bool>(
              future: _marketplaceService.isProductFavorite(product.id ?? ''),
              builder: (context, favoriteSnapshot) {
                final isFavorite = favoriteSnapshot.data ?? false;
                return ProductCard(
                  product: product,
                  isFavorite: isFavorite,
                  onToggleFavorite:
                      () => _toggleFavorite(product.id!, isFavorite),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _toggleFavorite(String productId, bool isFavorite) async {
    try {
      if (isFavorite) {
        await _marketplaceService.removeFromFavorites(productId);
      } else {
        await _marketplaceService.addToFavorites(productId);
      }
      // Force UI update
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating favorites: $e')));
    }
  }
}
