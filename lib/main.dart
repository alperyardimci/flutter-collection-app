import 'package:flutter/material.dart';
import 'data/banknote_store.dart';
import 'data/country_data.dart';
import 'screens/world_map_screen.dart';
import 'screens/country_detail_screen.dart';
import 'screens/add_banknote_screen.dart';
import 'screens/banknote_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BanknoteStore.init();
  // Load full country list (if present)
  await Countries.loadFromAsset();
  runApp(const BanknoteApp());
}

class BanknoteApp extends StatelessWidget {
  const BanknoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1220),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1A2438),
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: WorldMapScreen.routeName,
      routes: {
        WorldMapScreen.routeName: (_) => const WorldMapScreen(),
        CountryDetailScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as CountryDetailArgs;
          return CountryDetailScreen(args: args);
        },
        AddBanknoteScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as AddBanknoteArgs;
          return AddBanknoteScreen(args: args);
        },
        BanknoteDetailScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as BanknoteDetailArgs;
          return BanknoteDetailScreen(args: args);
        },
      },
    );
  }
}
