import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealId;
  final bool Function(String id) isFavorite;
  final void Function(Map<String, dynamic> meal) toggleFavorite;

  const MealDetailScreen({
    super.key,
    required this.mealId,
    required this.isFavorite,
    required this.toggleFavorite,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  Map<String, dynamic>? meal;
  bool isLoading = true;
  String errorMessage = '';
  int servings = 4;

  @override
  void initState() {
    super.initState();
    loadMeal();
  }

  Future<void> loadMeal() async {
    final url = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/lookup.php?i=${widget.mealId}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'];
        setState(() {
          meal = meals == null ? null : meals[0];
          isLoading = false;
          if (meal == null) errorMessage = 'Meal not found';
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load meal';
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

  // returns list of {name, measure} scaled to the current servings
  List<Map<String, String>> getIngredients() {
    final ingredients = <Map<String, String>>[];
    for (var i = 1; i <= 20; i++) {
      final name = meal!['strIngredient$i'];
      final measure = meal!['strMeasure$i'];
      if (name == null || name.toString().trim().isEmpty) continue;
      ingredients.add({
        'name': name,
        'measure': scaleMeasure(measure ?? ''),
      });
    }
    return ingredients;
  }

  String scaleMeasure(String measure) {
    final match = RegExp(
      r'^(\d+\/\d+|\d+\.\d+|\d+)\s*(.*)$',
    ).firstMatch(measure.trim());
    if (match == null) return measure;

    final numberPart = match.group(1)!;
    final restPart = match.group(2) ?? '';
    double value;
    if (numberPart.contains('/')) {
      final parts = numberPart.split('/');
      value = double.parse(parts[0]) / double.parse(parts[1]);
    } else {
      value = double.parse(numberPart);
    }

    final scaled = value * servings / 4;
    var scaledText = scaled.toStringAsFixed(2);
    if (scaledText.endsWith('.00')) {
      scaledText = scaledText.substring(0, scaledText.length - 3);
    } else if (scaledText.endsWith('0')) {
      scaledText = scaledText.substring(0, scaledText.length - 1);
    }

    return '$scaledText $restPart'.trim();
  }

  void openVideo() async {
    final videoUrl = meal!['strYoutube'];
    if (videoUrl == null || videoUrl.toString().isEmpty) return;
    final uri = Uri.parse(videoUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage.isNotEmpty || meal == null) {
      return Scaffold(body: Center(child: Text(errorMessage)));
    }

    final ingredients = getIngredients();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  widget.isFavorite(meal!['idMeal'])
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: () => setState(() {
                  widget.toggleFavorite(meal!);
                }),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                meal!['strMealThumb'],
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  meal!['strMeal'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    if (meal!['strCategory'] != null)
                      Chip(label: Text(meal!['strCategory'])),
                    if (meal!['strArea'] != null)
                      Chip(label: Text(meal!['strArea'])),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Servings',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: servings > 1
                              ? () => setState(() => servings--)
                              : null,
                        ),
                        Text('$servings'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => servings++),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                const Text(
                  'Ingredients',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...ingredients.map(
                  (ingredient) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(ingredient['name']!)),
                        Text(ingredient['measure']!),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                const Text(
                  'Instructions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(meal!['strInstructions'] ?? ''),
                const SizedBox(height: 20),
                if (meal!['strYoutube'] != null &&
                    meal!['strYoutube'].toString().isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: openVideo,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Watch recipe'),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
