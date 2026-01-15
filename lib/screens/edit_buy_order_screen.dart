// File: lib/screens/edit_buy_order_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/buy_order_provider.dart';
import '../providers/product_provider.dart';
import '../models/buy_order_model.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../utils/currency_helper.dart';

class EditBuyOrderScreen extends StatefulWidget {
  final BuyOrder order;

  const EditBuyOrderScreen({super.key, required this.order});

  @override
  _EditBuyOrderScreenState createState() => _EditBuyOrderScreenState();
}

class _EditBuyOrderScreenState extends State<EditBuyOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierNameController = TextEditingController();
  final _supplierAddressController = TextEditingController();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Product? _selectedProduct;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final order = widget.order;

    _supplierNameController.text = order.supplierName;
    _supplierAddressController.text = order.supplierAddress;
    _quantityController.text = order.quantity.toStringAsFixed(2);
    _rateController.text = order.rate.toStringAsFixed(5);
    _selectedDate = order.date;
  }

  @override
  Widget build(BuildContext context) {
    final buyOrderProvider = Provider.of<BuyOrderProvider>(
      context,
      listen: false,
    );
    final productProvider = Provider.of<ProductProvider>(context);

    // Find the product for this order
    if (_selectedProduct == null) {
      final product = productProvider.products.firstWhere(
        (p) => p.id == widget.order.productId,
        orElse: () => Product(
          id: widget.order.productId,
          productCode: widget.order.productCode,
          productName: widget.order.productName,
          description: '',
          createdAt: DateTime.now(),
          createdBy: '',
        ),
      );
      _selectedProduct = product;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Dark blue
        foregroundColor: Colors.white,
        title: const Text('Edit Buy Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _showDeleteDialog(context, buyOrderProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Buy Order',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0), // Dark blue text
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'ID: ${widget.order.id.substring(0, 8)}...',
                style: TextStyle(
                  color: Color(0xFF1976D2).withOpacity(0.8),
                  fontSize: 12,
                ), // Medium blue text
              ),
              const SizedBox(height: 30),

              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date*',
                    labelStyle: TextStyle(
                      color: Color(0xFF1976D2),
                    ), // Medium blue
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Color(0xFFBBDEFB),
                      ), // Light blue border
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Color(0xFF1976D2),
                      ), // Medium blue when focused
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Color(0xFFBBDEFB),
                      ), // Light blue border
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: Color(0xFF1976D2),
                    ), // Medium blue icon
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(_selectedDate)),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF1976D2),
                      ), // Medium blue icon
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Supplier Name
              TextFormField(
                controller: _supplierNameController,
                decoration: InputDecoration(
                  labelText: 'Supplier Name*',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFF1976D2),
                    ), // Medium blue when focused
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.people,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter supplier name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Supplier Address
              TextFormField(
                controller: _supplierAddressController,
                decoration: InputDecoration(
                  labelText: 'Supplier Address*',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFF1976D2),
                    ), // Medium blue when focused
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter supplier address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Product Selection (Read-only)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Product/Currency',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFF1976D2),
                    ), // Medium blue when focused
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFBBDEFB),
                    ), // Light blue border
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.currency_exchange,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedProduct?.productName} (${_selectedProduct?.productCode})',
                      style: TextStyle(
                        color: Color(0xFF1565C0),
                      ), // Dark blue text
                    ),
                    Icon(
                      Icons.lock,
                      size: 16,
                      color: Color(0xFF1976D2),
                    ), // Medium blue icon
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Note: Product cannot be changed for existing orders',
                style: TextStyle(
                  color: Color(0xFF1976D2).withOpacity(0.8),
                  fontSize: 12,
                ), // Medium blue text
              ),
              const SizedBox(height: 20),

              // Quantity and Rate in row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity*',
                        labelStyle: TextStyle(
                          color: Color(0xFF1976D2),
                        ), // Medium blue
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFFBBDEFB),
                          ), // Light blue border
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFF1976D2),
                          ), // Medium blue when focused
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFFBBDEFB),
                          ), // Light blue border
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(
                          Icons.format_list_numbered,
                          color: Color(0xFF1976D2),
                        ), // Medium blue icon
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Quantity must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      decoration: InputDecoration(
                        labelText: 'Rate*',
                        labelStyle: TextStyle(
                          color: Color(0xFF1976D2),
                        ), // Medium blue
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFFBBDEFB),
                          ), // Light blue border
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFF1976D2),
                          ), // Medium blue when focused
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFFBBDEFB),
                          ), // Light blue border
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: Color(0xFF1976D2),
                        ), // Medium blue icon
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Rate must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Calculate and show total
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final userCurrency =
                      authProvider.userData?['transactionCurrency'] ?? 'USD';

                  return Card(
                    color: Color(0xFFE3F2FD), // Light blue background
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Color(0xFFBBDEFB),
                      ), // Light blue border
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0), // Dark blue text
                            ),
                          ),
                          Text(
                            CurrencyHelper.formatAmount(
                              _calculateTotal(),
                              userCurrency,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2), // Medium blue text
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Submit Button
              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1976D2),
                        ), // Medium blue progress
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(
                            0xFF1976D2,
                          ), // Medium blue background
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          setState(() => _isLoading = true);

                          bool success = await buyOrderProvider.updateBuyOrder(
                            orderId: widget.order.id,
                            date: _selectedDate,
                            supplierName: _supplierNameController.text,
                            supplierAddress: _supplierAddressController.text,
                            productId: widget.order.productId,
                            productName: widget.order.productName,
                            productCode: widget.order.productCode,
                            quantity: double.parse(_quantityController.text),
                            rate: double.parse(_rateController.text),
                          );

                          setState(() => _isLoading = false);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Buy order updated successfully!',
                                ),
                                backgroundColor: Color(
                                  0xFF1976D2,
                                ), // Medium blue
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Failed to update buy order',
                                ),
                                backgroundColor: Color(
                                  0xFF1565C0,
                                ), // Dark blue for error
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Update Buy Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF1976D2), // Medium blue for date picker
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  double _calculateTotal() {
    try {
      double quantity = double.tryParse(_quantityController.text) ?? 0;
      double rate = double.tryParse(_rateController.text) ?? 0;
      return quantity * rate;
    } catch (e) {
      return 0;
    }
  }

  void _showDeleteDialog(BuildContext context, BuyOrderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Buy Order',
          style: TextStyle(color: Color(0xFF1565C0)), // Dark blue text
        ),
        content: Text(
          'Are you sure you want to delete this buy order? This action cannot be undone.',
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

              setState(() => _isLoading = true);
              bool success = await provider.deleteBuyOrder(widget.order.id);
              setState(() => _isLoading = false);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Buy order deleted successfully'),
                    backgroundColor: Color(0xFF1976D2), // Medium blue
                  ),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to delete buy order'),
                    backgroundColor: Color(0xFF1565C0), // Dark blue for error
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

  @override
  void dispose() {
    _supplierNameController.dispose();
    _supplierAddressController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    super.dispose();
  }
}
