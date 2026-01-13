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
      appBar: AppBar(
        title: Text('Create Buy Order'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Create a new buy order from supplier',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 30),

              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(_selectedDate)),
                      Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Supplier Selection
              DropdownButtonFormField<Supplier>(
                decoration: InputDecoration(
                  labelText: 'Supplier*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                initialValue: _selectedSupplier,
                items: supplierProvider.suppliers.map((Supplier supplier) {
                  return DropdownMenuItem<Supplier>(
                    value: supplier,
                    child: Text('${supplier.name} - ${supplier.address}'),
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
              SizedBox(height: 20),

              // Product Selection
              DropdownButtonFormField<Product>(
                decoration: InputDecoration(
                  labelText: 'Product/Currency*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                initialValue: _selectedProduct,
                items: productProvider.products.map((Product product) {
                  return DropdownMenuItem<Product>(
                    value: product,
                    child: Text(
                      '${product.productName} (${product.productCode})',
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
              SizedBox(height: 20),

              // Quantity and Rate in row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity*',
                        hintText: 'e.g., 1000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_numbered),
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
                  SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      decoration: InputDecoration(
                        labelText: 'Rate*',
                        hintText: 'e.g., 75.5',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
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

              SizedBox(height: 10),

              // Calculate and show total
              if (_quantityController.text.isNotEmpty &&
                  _rateController.text.isNotEmpty)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final userCurrency =
                        authProvider.userData?['transactionCurrency'] ?? 'USD';

                    return Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              CurrencyHelper.formatAmount(
                                _calculateTotal(),
                                userCurrency,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              SizedBox(height: 30),

              // Status info
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Order will be created with Pending status. '
                          'You can mark as Paid later to complete the order.',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Submit Button
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          if (_selectedProduct == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select a product'),
                              ),
                            );
                            return;
                          }
                          if (_selectedSupplier == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select a supplier'),
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
                                content: Text(
                                  'Buy order created successfully!',
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to create buy order'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Create Buy Order',
                          style: TextStyle(fontSize: 16),
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
