// File: lib/screens/create_sell_order_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sell_order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';
import '../utils/currency_helper.dart';

class CreateSellOrderScreen extends StatefulWidget {
  const CreateSellOrderScreen({super.key});

  @override
  _CreateSellOrderScreenState createState() => _CreateSellOrderScreenState();
}

class _CreateSellOrderScreenState extends State<CreateSellOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Product? _selectedProduct;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sellOrderProvider = Provider.of<SellOrderProvider>(
      context,
      listen: false,
    );
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Dark blue
        foregroundColor: Colors.white,
        title: const Text('Create Sell Order'),
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
                'Sell Order Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0), // Dark blue text
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Create a new sell order for currency/product',
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
                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF1976D2),
                      ), // Medium blue icon
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Customer Name
              TextFormField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name*',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  hintText: 'Enter customer name',
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
                    Icons.person,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Customer Address
              TextFormField(
                controller: _customerAddressController,
                decoration: InputDecoration(
                  labelText: 'Customer Address*',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  hintText: 'Enter customer address',
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
                    return 'Please enter customer address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

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
              const SizedBox(height: 10),

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
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final userCurrency =
                      authProvider.userData?['transactionCurrency'] ?? 'USD';
                  final currencySymbol = CurrencyHelper.getSymbol(userCurrency);

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
                            '$currencySymbol${_calculateTotal().toStringAsFixed(2)}',
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

              const SizedBox(height: 10),

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

                          setState(() => _isLoading = true);

                          bool success = await sellOrderProvider.addSellOrder(
                            date: _selectedDate,
                            customerName: _customerNameController.text,
                            customerAddress: _customerAddressController.text,
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
                                  'Sell order created successfully!',
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
                                  'Failed to create sell order',
                                ),
                                backgroundColor: Color(
                                  0xFF1565C0,
                                ), // Dark blue for error
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Create Sell Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 10),

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
                          'You can mark as Paid and Delivered later.',
                          style: TextStyle(
                            color: Color.fromARGB(255, 223, 133, 16),
                          ), // Medium blue text
                        ),
                      ),
                    ],
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
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    super.dispose();
  }
}
