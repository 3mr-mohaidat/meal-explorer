import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'meal_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteMeals;
  final bool Function(String id) isFavorite;
  final void Function(Map<String, dynamic> meal) toggleFavorite;
  final String? initialCategory;

  const SearchScreen({
    super.key,
    required this.favoriteMeals,
    required this.isFavorite,
    required this.toggleFavorite,
    this.initialCategory,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController();
  List<dynamic> allResults = [];
  List<dynamic> filteredResults = [];
  Set<String> selectedCategories = {};
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      selectedCategories.add(widget.initialCategory!);
    }
    search('');
  }

  Future<void> search(String query) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final url = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/search.php?s=$query',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          allResults = data['meals'] ?? [];
          isLoading = false;
        });
        applyFilter();
      } else {
        setState(() {
          errorMessage = 'Failed to search';
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

  void applyFilter() {
    setState(() {
      if (selectedCategories.isEmpty) {
        filteredResults = allResults;
      } else {
        filteredResults = allResults
            .where((meal) => selectedCategories.contains(meal['strCategory']))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const categoryOptions = [
      'Seafood',
      'Chicken',
      'Vegetarian',
      'Pasta',
      'Dessert',
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search meals',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: search,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : filteredResults.isEmpty
                ? const Center(child: Text('No results'))
                : ListView.builder(
                    itemCount: filteredResults.length,
                    itemBuilder: (context, index) {
                      final meal = filteredResults[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            meal['strMealThumb'],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(meal['strMeal']),
                        subtitle: Text(meal['strCategory'] ?? ''),
                        trailing: IconButton(
                          icon: Icon(
                            widget.isFavorite(meal['idMeal'])
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () => widget.toggleFavorite(meal),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MealDetailScreen(
                                mealId: meal['idMeal'],
                                isFavorite: widget.isFavorite,
                                toggleFavorite: widget.toggleFavorite,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Filter by category'),
                ),
                Wrap(
                  spacing: 8,
                  children: categoryOptions.map((category) {
                    final selected = selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            selectedCategories.add(category);
                          } else {
                            selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: applyFilter,
                    child: const Text('Apply filter'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
