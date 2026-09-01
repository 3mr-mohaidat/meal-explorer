import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meal Explorer',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFFF6B35),
        useMaterial3: true,
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;

  // favorites kept here so all tabs share the same list (in-memory only)
  List<Map<String, dynamic>> favoriteMeals = [];

  bool isFavorite(String id) {
    return favoriteMeals.any((m) => m['idMeal'] == id);
  }

  void toggleFavorite(Map<String, dynamic> meal) {
    setState(() {
      if (isFavorite(meal['idMeal'])) {
        favoriteMeals.removeWhere((m) => m['idMeal'] == meal['idMeal']);
      } else {
        favoriteMeals.add(meal);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        favoriteMeals: favoriteMeals,
        isFavorite: isFavorite,
        toggleFavorite: toggleFavorite,
      ),
      CategoriesScreen(
        favoriteMeals: favoriteMeals,
        isFavorite: isFavorite,
        toggleFavorite: toggleFavorite,
      ),
      FavoritesScreen(
        favoriteMeals: favoriteMeals,
        isFavorite: isFavorite,
        toggleFavorite: toggleFavorite,
      ),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
