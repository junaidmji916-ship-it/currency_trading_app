// File: lib/main.dart - CORRECTED
import 'package:currency_trading_app/providers/reports_provider.dart';
import 'package:currency_trading_app/screens/add_edit_product_screen.dart';
import 'package:currency_trading_app/screens/buy_orders_screen.dart';
import 'package:currency_trading_app/screens/create_buy_order_screen.dart';
import 'package:currency_trading_app/screens/create_sell_order_screen.dart';
import 'package:currency_trading_app/screens/products_screen.dart';
import 'package:currency_trading_app/screens/reports_screen.dart';
import 'package:currency_trading_app/screens/sell_orders_screen.dart';
import 'package:currency_trading_app/screens/suppliers_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/sell_order_provider.dart';
import 'providers/buy_order_provider.dart'; // KEEP ONLY THIS ONE - lowercase
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(MyApp());
}

// File: lib/main.dart - Add ReportsProvider
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ProductProvider()),
        ChangeNotifierProvider(create: (context) => SupplierProvider()),
        ChangeNotifierProvider(create: (context) => SellOrderProvider()),
        ChangeNotifierProvider(create: (context) => BuyOrderProvider()),
        ChangeNotifierProvider(create: (context) => ReportsProvider()),
      ],
      child: MaterialApp(
        title: 'Currency Trade App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
          '/dashboard': (context) => DashboardScreen(),
          '/products': (context) => ProductsScreen(),
          '/sell_orders': (context) => SellOrdersScreen(),
          '/buy_orders': (context) => BuyOrdersScreen(),
          '/suppliers': (context) => SuppliersScreen(),
          '/reports': (context) => ReportsScreen(),
          '/add_product': (context) => AddEditProductScreen(),
          '/create_sell': (context) => CreateSellOrderScreen(),
          '/create_buy': (context) => CreateBuyOrderScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoggedIn) {
      return DashboardScreen();
    } else {
      return LoginScreen();
    }
  }
}
