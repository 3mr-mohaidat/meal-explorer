import 'package:flutter/material.dart';
import 'meal_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favoriteMeals;
  final bool Function(String id) isFavorite;
  final void Function(Map<String, dynamic> meal) toggleFavorite;

  const FavoritesScreen({
    super.key,
    required this.favoriteMeals,
    required this.isFavorite,
    required this.toggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Favorites',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: favoriteMeals.isEmpty
                  ? const Center(child: Text('No favorites yet'))
                  : ListView.builder(
                      itemCount: favoriteMeals.length,
                      itemBuilder: (context, index) {
                        final meal = favoriteMeals[index];
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
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                            onPressed: () => toggleFavorite(meal),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MealDetailScreen(
                                  mealId: meal['idMeal'],
                                  isFavorite: isFavorite,
                                  toggleFavorite: toggleFavorite,
                                ),
                              ),
                            );
                          },
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
