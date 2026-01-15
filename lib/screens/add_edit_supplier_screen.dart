// File: lib/screens/add_edit_supplier_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/auth_provider.dart';
import '../models/supplier_model.dart';

class AddEditSupplierScreen extends StatefulWidget {
  final Supplier? supplier;

  const AddEditSupplierScreen({super.key, this.supplier});

  @override
  _AddEditSupplierScreenState createState() => _AddEditSupplierScreenState();
}

class _AddEditSupplierScreenState extends State<AddEditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!.name;
      _addressController.text = widget.supplier!.address;
      _phoneController.text = widget.supplier!.phone ?? '';
      _emailController.text = widget.supplier!.email ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final supplierProvider = Provider.of<SupplierProvider>(
      context,
      listen: false,
    );

    final isEdit = widget.supplier != null;
    final title = isEdit ? 'Edit Supplier' : 'Add Supplier';

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
                'Supplier Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0), // Dark blue text
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add supplier information for buy orders',
                style: TextStyle(
                  color: Color(0xFF1976D2).withOpacity(0.8),
                ), // Medium blue text
              ),
              const SizedBox(height: 30),

              // Supplier Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Supplier Name*',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  hintText: 'e.g., John Traders, ABC Corp',
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
                    return 'Please enter supplier name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Address field - increased maxLines from 3 to 5
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address*',
                  labelStyle: TextStyle(color: Color(0xFF1976D2)),
                  hintText: 'Full address of supplier',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFBBDEFB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFF1976D2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFBBDEFB)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF1976D2)),
                ),
                maxLines: 10, // Changed from 3 to 5
                minLines: 3, // Optional: Set minimum lines
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone (Optional)',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  hintText: 'e.g., +971 50*******',
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
                    Icons.phone,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  labelStyle: TextStyle(
                    color: Color(0xFF1976D2),
                  ), // Medium blue
                  hintText: 'e.g., supplier@example.com',
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
                    Icons.email,
                    color: Color(0xFF1976D2),
                  ), // Medium blue icon
                ),
                keyboardType: TextInputType.emailAddress,
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
                            success = await supplierProvider.updateSupplier(
                              supplierId: widget.supplier!.id,
                              name: _nameController.text,
                              address: _addressController.text,
                              phone: _phoneController.text.isNotEmpty
                                  ? _phoneController.text
                                  : null,
                              email: _emailController.text.isNotEmpty
                                  ? _emailController.text
                                  : null,
                            );
                          } else {
                            success = await supplierProvider.addSupplier(
                              name: _nameController.text,
                              address: _addressController.text,
                              phone: _phoneController.text.isNotEmpty
                                  ? _phoneController.text
                                  : null,
                              email: _emailController.text.isNotEmpty
                                  ? _emailController.text
                                  : null,
                              createdBy: authProvider.user!.uid,
                            );
                          }

                          setState(() => _isLoading = false);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Supplier updated successfully!'
                                      : 'Supplier added successfully!',
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
                                      ? 'Failed to update supplier'
                                      : 'Failed to add supplier',
                                ),
                                backgroundColor: Color(
                                  0xFF1565C0,
                                ), // Dark blue for error
                              ),
                            );
                          }
                        },
                        child: Text(
                          isEdit ? 'Update Supplier' : 'Add Supplier',
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
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
