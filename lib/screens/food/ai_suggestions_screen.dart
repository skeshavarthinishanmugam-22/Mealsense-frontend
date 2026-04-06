import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/session_manager.dart';

class AiSuggestionsScreen extends StatefulWidget {
  final String mealType;

  const AiSuggestionsScreen({
    super.key,
    this.mealType = 'breakfast',
  });

  @override
  State<AiSuggestionsScreen> createState() => _AiSuggestionsScreenState();
}

class _AiSuggestionsScreenState extends State<AiSuggestionsScreen> {
  late Future<Map<String, dynamic>> _suggestionsFuture;
  String _selectedMealType = 'breakfast';
  int _targetCalories = 430;
  int _targetProtein = 35;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.mealType;
    _loadSuggestions();
  }

  void _loadSuggestions() {
    setState(() {
      _suggestionsFuture = ApiService.getAiSuggestions(
        mealType: _selectedMealType,
        targetCalories: _targetCalories,
        targetProtein: _targetProtein,
      );
    });
  }

  void _onMealTypeChanged(String? value) {
    if (value != null) {
      setState(() => _selectedMealType = value);
      _loadSuggestions();
    }
  }

  void _showAddMealDialog(Map<String, dynamic> suggestion) {
    showDialog(
      context: context,
      builder: (context) => AddMealDialog(suggestion: suggestion),
    ).then((_) {
      // Refresh suggestions after adding
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal added to favorites!')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Meal Type Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedMealType,
              items: ['breakfast', 'lunch', 'dinner', 'snack']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                  .toList(),
              onChanged: _onMealTypeChanged,
              isExpanded: true,
            ),
          ),
          // Suggestions List
          FutureBuilder<Map<String, dynamic>>(
            future: _suggestionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final data = snapshot.data ?? {};
              final suggestions = (data['suggestions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

              if (suggestions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No suggestions available'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final food = suggestions[index];
                  return _buildFoodCard(food);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    food['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddMealDialog(food),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNutritionGrid(food),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionGrid(Map<String, dynamic> food) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.0,
      children: [
        _buildNutritionItem('Calories', '${food['calories'] ?? 0}', 'cal'),
        _buildNutritionItem('Protein', '${food['protein'] ?? 0}', 'g'),
        _buildNutritionItem('Carbs', '${food['carbs'] ?? 0}', 'g'),
        _buildNutritionItem('Fat', '${food['fat'] ?? 0}', 'g'),
      ],
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class AddMealDialog extends StatefulWidget {
  final Map<String, dynamic> suggestion;

  const AddMealDialog({super.key, required this.suggestion});

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  late TextEditingController _mealNameController;
  late TextEditingController _descriptionController;
  String _selectedCategory = 'BREAKFAST';

  @override
  void initState() {
    super.initState();
    _mealNameController = TextEditingController(text: widget.suggestion['name'] ?? '');
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addMeal() async {
    try {
      final response = await ApiService.addCustomMeal(
        mealName: _mealNameController.text,
        description: _descriptionController.text,
        calories: (widget.suggestion['calories'] as num?)?.toInt() ?? 0,
        proteinGrams: (widget.suggestion['protein'] as num?)?.toDouble() ?? 0.0,
        carbsGrams: (widget.suggestion['carbs'] as num?)?.toDouble() ?? 0.0,
        fatGrams: (widget.suggestion['fat'] as num?)?.toDouble() ?? 0.0,
        fiberGrams: (widget.suggestion['fiber'] as num?)?.toDouble() ?? 0.0,
        mealCategory: _selectedCategory,
      );

      if (response['statusCode'] == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Meal saved to favorites!')),
          );
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to add meal');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save to Favorites'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _mealNameController,
              decoration: const InputDecoration(labelText: 'Meal Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value ?? 'BREAKFAST'),
              decoration: const InputDecoration(labelText: 'Meal Category'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addMeal,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
