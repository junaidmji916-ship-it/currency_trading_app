// File: lib/screens/products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../screens/add_edit_product_screen.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Dark blue
        foregroundColor: Colors.white,
        title: const Text('Products/Currencies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditProductScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF1976D2),
                ), // Medium blue progress
              ),
            );
          }

          if (productProvider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.currency_exchange,
                    size: 80,
                    color: Color(0xFFBBDEFB),
                  ), // Light blue icon
                  const SizedBox(height: 20),
                  Text(
                    'No products/currencies yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF1976D2), // Medium blue text
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap + to add your first product',
                    style: TextStyle(
                      color: Color(0xFF1976D2).withOpacity(0.7),
                    ), // Medium blue text
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: productProvider.products.length,
            itemBuilder: (context, index) {
              Product product = productProvider.products[index];
              return ProductCard(product: product);
            },
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Color(0xFFE3F2FD)), // Light blue border
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFFE3F2FD), // Light blue background
          child: Icon(
            Icons.currency_exchange,
            color: Color(0xFF1976D2),
          ), // Medium blue icon
        ),
        title: Text(
          product.productName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0), // Dark blue text
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Code: ${product.productCode}',
              style: TextStyle(color: Color(0xFF1976D2)), // Medium blue text
            ),
            if (product.description != null && product.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  product.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1976D2),
                  ), // Medium blue text
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Added: ${_formatDate(product.createdAt)}',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF1976D2).withOpacity(0.7),
              ), // Medium blue text
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Color(0xFF1976D2),
          ), // Medium blue icon
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Color(0xFFE3F2FD)), // Light blue border
          ),
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditProductScreen(product: product),
                ),
              );
            } else if (value == 'delete') {
              _showDeleteDialog(context, product, productProvider);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ), // Medium blue icon
                  const SizedBox(width: 8),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                    ), // Dark blue text
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ), // Medium blue icon
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                    ), // Dark blue text
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteDialog(
    BuildContext context,
    Product product,
    ProductProvider productProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Product',
          style: TextStyle(color: Color(0xFF1565C0)), // Dark blue text
        ),
        content: Text(
          'Are you sure you want to delete "${product.productName}"?',
          style: TextStyle(color: Color(0xFF1976D2)), // Medium blue text
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Color(0xFFE3F2FD)), // Light blue border
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF1976D2)), // Medium blue text
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1976D2), // Medium blue background
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              bool success = await productProvider.deleteProduct(product.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Product deleted successfully'),
                    backgroundColor: Color(0xFF1976D2), // Medium blue
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to delete product'),
                    backgroundColor: Color(0xFF1565C0), // Dark blue
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
