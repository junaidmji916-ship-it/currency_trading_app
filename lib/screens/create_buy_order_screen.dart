// File: lib/screens/create_buy_order_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/buy_order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/supplier_provider.dart';
import '../models/product_model.dart';
import '../models/supplier_model.dart';
import '../utils/currency_helper.dart';

class CreateBuyOrderScreen extends StatefulWidget {
  const CreateBuyOrderScreen({super.key});

  @override
  _CreateBuyOrderScreenState createState() => _CreateBuyOrderScreenState();
}

class _CreateBuyOrderScreenState extends State<CreateBuyOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Product? _selectedProduct;
  Supplier? _selectedSupplier;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final buyOrderProvider = Provider.of<BuyOrderProvider>(
      context,
      listen: false,
    );
    final productProvider = Provider.of<ProductProvider>(context);
    final supplierProvider = Provider.of<SupplierProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Dark blue
        foregroundColor: Colors.white,
        title: const Text('Create Buy Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buy Order Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0), // Dark blue text
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Create a new buy order from supplier',
                style: TextStyle(
                  color: Color(0xFF1976D2).withOpacity(0.8),
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

              // Supplier Selection
              DropdownButtonFormField<Supplier>(
                decoration: InputDecoration(
                  labelText: 'Supplier*',
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
                dropdownColor: Colors.white,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF1976D2),
                ), // Medium blue icon
                borderRadius: BorderRadius.circular(8),
                style: TextStyle(color: Color(0xFF1565C0)), // Dark blue text
                initialValue: _selectedSupplier,
                items: supplierProvider.suppliers.map((Supplier supplier) {
                  return DropdownMenuItem<Supplier>(
                    value: supplier,
                    child: Text(
                      '${supplier.name} - ${supplier.address}',
                      style: TextStyle(
                        color: Color(0xFF1565C0),
                      ), // Dark blue text
                    ),
                  );
                }).toList(),
                onChanged: (Supplier? newValue) {
                  setState(() {
                    _selectedSupplier = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a supplier';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Product Selection
              DropdownButtonFormField<Product>(
                decoration: InputDecoration(
                  labelText: 'Product/Currency*',
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
                dropdownColor: Colors.white,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF1976D2),
                ), // Medium blue icon
                borderRadius: BorderRadius.circular(8),
                style: TextStyle(color: Color(0xFF1565C0)), // Dark blue text
                initialValue: _selectedProduct,
                items: productProvider.products.map((Product product) {
                  return DropdownMenuItem<Product>(
                    value: product,
                    child: Text(
                      '${product.productName} (${product.productCode})',
                      style: TextStyle(
                        color: Color(0xFF1565C0),
                      ), // Dark blue text
                    ),
                  );
                }).toList(),
                onChanged: (Product? newValue) {
                  setState(() {
                    _selectedProduct = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a product';
                  }
                  return null;
                },
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
                        hintText: 'e.g., 1000',
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
                        hintText: 'e.g., 75.5',
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
              if (_quantityController.text.isNotEmpty &&
                  _rateController.text.isNotEmpty)
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

              // Status info
              Card(
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
                    children: [
                      Icon(
                        Icons.info,
                        color: Color(0xFF1976D2),
                      ), // Medium blue icon
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Order will be created with Pending status. '
                          'You can mark as Paid later to complete the order.',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                          ), // Medium blue text
                        ),
                      ),
                    ],
                  ),
                ),
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
                          if (_selectedProduct == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please select a product'),
                                backgroundColor: Color(
                                  0xFF1976D2,
                                ), // Medium blue
                              ),
                            );
                            return;
                          }
                          if (_selectedSupplier == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please select a supplier'),
                                backgroundColor: Color(
                                  0xFF1976D2,
                                ), // Medium blue
                              ),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);

                          bool success = await buyOrderProvider.addBuyOrder(
                            date: _selectedDate,
                            supplierName: _selectedSupplier!.name,
                            supplierAddress: _selectedSupplier!.address,
                            productId: _selectedProduct!.id,
                            productName: _selectedProduct!.productName,
                            productCode: _selectedProduct!.productCode,
                            quantity: double.parse(_quantityController.text),
                            rate: double.parse(_rateController.text),
                            createdBy: authProvider.user!.uid,
                          );

                          setState(() => _isLoading = false);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Buy order created successfully!',
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
                                  'Failed to create buy order',
                                ),
                                backgroundColor: Color(
                                  0xFF1565C0,
                                ), // Dark blue for error
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Create Buy Order',
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

  @override
  void dispose() {
    _quantityController.dispose();
    _rateController.dispose();
    super.dispose();
  }
}
