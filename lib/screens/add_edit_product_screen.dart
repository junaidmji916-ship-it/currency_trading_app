// File: lib/screens/add_edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productCodeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _productCodeController.text = widget.product!.productCode;
      _productNameController.text = widget.product!.productName;
      _descriptionController.text = widget.product!.description ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    final isEdit = widget.product != null;
    final title = isEdit ? 'Edit Product' : 'Add Product';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Dark blue
        foregroundColor: Colors.white,
        title: Text(title),
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
                'Add Currency/Product',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0), // Dark blue text
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add currencies or products you want to trade',
                style: TextStyle(
                  color: Color(0xFF1976D2).withOpacity(0.8),
                ), // Medium blue text
              ),
              const SizedBox(height: 30),

              // Product Code
              TextFormField(
                controller: _productCodeController,
                decoration: InputDecoration(
                  labelText: 'Product Code*',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  hintText: 'e.g., USD, EUR, INR, BTC',
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
                    Icons.code,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Product Name
              TextFormField(
                controller: _productNameController,
                decoration: InputDecoration(
                  labelText: 'Product Name*',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  hintText: 'e.g., US Dollar, Euro, Bitcoin',
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  hintText: 'Additional details about this product',
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
                    Icons.description,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
                ),
                maxLines: 3,
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

                          bool success;
                          if (isEdit) {
                            success = await productProvider.updateProduct(
                              productId: widget.product!.id,
                              productCode: _productCodeController.text,
                              productName: _productNameController.text,
                              description: _descriptionController.text,
                            );
                          } else {
                            success = await productProvider.addProduct(
                              productCode: _productCodeController.text,
                              productName: _productNameController.text,
                              description: _descriptionController.text,
                              createdBy: authProvider.user!.uid,
                            );
                          }

                          setState(() => _isLoading = false);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Product updated successfully!'
                                      : 'Product added successfully!',
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
                                content: Text(
                                  isEdit
                                      ? 'Failed to update product'
                                      : 'Failed to add product',
                                ),
                                backgroundColor: Color(
                                  0xFF1565C0,
                                ), // Dark blue for error
                              ),
                            );
                          }
                        },
                        child: Text(
                          isEdit ? 'Update Product' : 'Add Product',
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

  @override
  void dispose() {
    _productCodeController.dispose();
    _productNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
