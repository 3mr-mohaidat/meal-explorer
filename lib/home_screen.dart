import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'search_screen.dart';
import 'meal_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteMeals;
  final bool Function(String id) isFavorite;
  final void Function(Map<String, dynamic> meal) toggleFavorite;

  const HomeScreen({
    super.key,
    required this.favoriteMeals,
    required this.isFavorite,
    required this.toggleFavorite,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> categories = ['All'];
  String selectedCategory = 'All';
  List<dynamic> meals = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadMeals();
  }

  Future<void> loadCategories() async {
    final url = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/list.php?c=list',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['meals'] as List;
      setState(() {
        categories = ['All', ...list.map((m) => m['strCategory'] as String)];
      });
    }
  }

  Future<void> loadMeals() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final url = selectedCategory == 'All'
        ? Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s=')
        : Uri.parse(
            'https://www.themealdb.com/api/json/v1/1/filter.php?c=$selectedCategory',
          );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          meals = data['meals'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load meals';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Something went wrong';
        isLoading = false;
      });
    }
  }

  void selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
    loadMeals();
  }

  void openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          favoriteMeals: widget.favoriteMeals,
          isFavorite: widget.isFavorite,
          toggleFavorite: widget.toggleFavorite,
        ),
      ),
    );
  }

  void openDetail(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealDetailScreen(
          mealId: id,
          isFavorite: widget.isFavorite,
          toggleFavorite: widget.toggleFavorite,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meal Explorer',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text('What are you craving?'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: openSearch,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Search meals', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = category == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) => selectCategory(category),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                  ? Center(child: Text(errorMessage))
                  : meals.isEmpty
                  ? const Center(child: Text('No meals found'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        final meal = meals[index];
                        return GestureDetector(
                          onTap: () => openDetail(meal['idMeal']),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.network(
                                          meal['strMealThumb'],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () =>
                                              widget.toggleFavorite(meal),
                                          child: CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Colors.white,
                                            child: Icon(
                                              widget.isFavorite(
                                                    meal['idMeal'],
                                                  )
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    meal['strMeal'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
