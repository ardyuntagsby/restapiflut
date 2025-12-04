import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

/// MODEL: Meal
class Meal {
  final String idMeal;
  final String strMeal;
  final String strMealThumb;

  Meal({
    required this.idMeal,
    required this.strMeal,
    required this.strMealThumb,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      idMeal: json['idMeal'],
      strMeal: json['strMeal'],
      strMealThumb: json['strMealThumb'],
    );
  }
}

/// SERVICE: ambil data dari REST API
class MealService {
  static const String _url =
      'https://www.themealdb.com/api/json/v1/1/filter.php?a=Canadian';

  Future<List<Meal>> fetchMeals() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final List mealsJson = decoded['meals'] as List;
      return mealsJson.map((e) => Meal.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load meals');
    }
  }
}

/// ROOT APP
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canadian Meals',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MealGridScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// SCREEN: Grid 2 kolom, scroll ke bawah
class MealGridScreen extends StatefulWidget {
  const MealGridScreen({super.key});

  @override
  State<MealGridScreen> createState() => _MealGridScreenState();
}

class _MealGridScreenState extends State<MealGridScreen> {
  final MealService _service = MealService();

  late Future<List<Meal>> _futureMeals;

  @override
  void initState() {
    super.initState();
    _futureMeals = _service.fetchMeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canadian Meals')),
      body: FutureBuilder<List<Meal>>(
        future: _futureMeals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error: ${snapshot.error ?? "No data"}'));
          }

          final meals = snapshot.data!;

          // GridView.builder sudah scrollable (seperti ListView)
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 item per row
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75, // atur tinggi-lebar card
            ),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];

              return MealCard(meal: meal);
            },
          );
        },
      ),
    );
  }
}

/// WIDGET: Card untuk tiap meal + Hero animation ke detail
class MealCard extends StatelessWidget {
  final Meal meal;

  const MealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero untuk animasi gambar
            Hero(
              tag: 'meal-image-${meal.idMeal}',
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  meal.strMealThumb,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stack) =>
                      const Center(child: Icon(Icons.error)),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Center(
                  child: Text(
                    meal.strMeal,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SCREEN: Detail dengan Hero animation
class MealDetailScreen extends StatelessWidget {
  final Meal meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(meal.strMeal)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: 'meal-image-${meal.idMeal}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(meal.strMealThumb, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            meal.strMeal,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Meal ID: ${meal.idMeal}', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Text(
            'Di endpoint ini hanya ada data basic (nama, gambar, id). '
            'Kalau mau detail bahan & instruksi, bisa panggil endpoint lookup by ID.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
