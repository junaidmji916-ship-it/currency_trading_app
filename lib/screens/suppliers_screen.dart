// File: lib/screens/suppliers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier_model.dart';
import 'add_edit_supplier_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  _SuppliersScreenState createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Dark blue
        foregroundColor: Colors.white,
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditSupplierScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search suppliers...',
                hintStyle: TextStyle(color: Color(0xFF1976D2).withOpacity(0.6)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF1976D2),
                ), // Medium blue icon
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Color(0xFFBBDEFB),
                  ), // Light blue border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Color(0xFF1976D2),
                  ), // Medium blue when focused
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Color(0xFFBBDEFB),
                  ), // Light blue border
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 15,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Color(0xFF1976D2),
                        ), // Medium blue icon
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          Expanded(
            child: Consumer<SupplierProvider>(
              builder: (context, supplierProvider, child) {
                if (supplierProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1976D2),
                      ), // Medium blue progress
                    ),
                  );
                }

                List<Supplier> displayedSuppliers = _searchQuery.isEmpty
                    ? supplierProvider.suppliers
                    : supplierProvider.searchSuppliers(_searchQuery);

                if (displayedSuppliers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people,
                          size: 80,
                          color: Color(0xFFBBDEFB),
                        ), // Light blue icon
                        const SizedBox(height: 20),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No suppliers yet'
                              : 'No suppliers found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF1976D2), // Medium blue text
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_searchQuery.isEmpty)
                          Text(
                            'Tap + to add your first supplier',
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
                  itemCount: displayedSuppliers.length,
                  itemBuilder: (context, index) {
                    Supplier supplier = displayedSuppliers[index];
                    return SupplierCard(supplier: supplier);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierCard extends StatelessWidget {
  final Supplier supplier;

  const SupplierCard({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    final supplierProvider = Provider.of<SupplierProvider>(
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
            Icons.person,
            color: Color(0xFF1976D2),
          ), // Medium blue icon
        ),
        title: Text(
          supplier.name,
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
              supplier.address,
              style: TextStyle(color: Color(0xFF1976D2)), // Medium blue text
            ),
            if (supplier.phone != null && supplier.phone!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 14,
                      color: Color(0xFF1976D2),
                    ), // Medium blue icon
                    const SizedBox(width: 5),
                    Text(
                      supplier.phone!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1976D2),
                      ), // Medium blue text
                    ),
                  ],
                ),
              ),
            if (supplier.email != null && supplier.email!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 14,
                      color: Color(0xFF1976D2),
                    ), // Medium blue icon
                    const SizedBox(width: 5),
                    Text(
                      supplier.email!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1976D2),
                      ), // Medium blue text
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Added: ${_formatDate(supplier.createdAt)}',
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
                  builder: (context) =>
                      AddEditSupplierScreen(supplier: supplier),
                ),
              );
            } else if (value == 'delete') {
              _showDeleteDialog(context, supplier, supplierProvider);
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
    Supplier supplier,
    SupplierProvider supplierProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Supplier',
          style: TextStyle(color: Color(0xFF1565C0)), // Dark blue text
        ),
        content: Text(
          'Are you sure you want to delete "${supplier.name}"?',
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
              bool success = await supplierProvider.deleteSupplier(supplier.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Supplier deleted successfully'),
                    backgroundColor: Color(0xFF1976D2), // Medium blue
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to delete supplier'),
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
