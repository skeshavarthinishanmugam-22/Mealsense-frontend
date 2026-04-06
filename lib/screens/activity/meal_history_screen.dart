import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  late Future<Map<String, dynamic>> _historyFuture;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadHistory();
  }

  void _loadHistory() {
    final dateStr = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null;
    setState(() {
      _historyFuture = ApiService.getMealHistory(
        startDate: dateStr,
        endDate: dateStr,
      );
    });
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date Picker
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDate != null
                    ? DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)
                    : 'Select Date',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              ElevatedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: const Text('Change Date'),
              ),
            ],
          ),
        ),
        // History Content
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final data = snapshot.data ?? {};
              final history = (data['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final totalCalories = data['totalCalories'] ?? 0;
              final totalProtein = (data['totalProtein'] as num?)?.toDouble() ?? 0.0;

              if (history.isEmpty) {
                return const Center(
                  child: Text('No meals logged for this date'),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Summary Card
                    _buildSummaryCard(totalCalories, totalProtein),
                    const SizedBox(height: 16),
                    // Meals List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final meal = history[index];
                        return _buildMealLogCard(meal);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(int calories, double protein) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Total Calories', calories.toString(), 'cal'),
                ),
                Expanded(
                  child: _buildSummaryItem('Total Protein', '${protein.toStringAsFixed(1)}g', 'protein'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMealLogCard(Map<String, dynamic> meal) {
    final mealName = meal['mealName'] ?? 'Unknown';
    final category = meal['mealCategory'] ?? 'SNACK';
    final calories = meal['calories'] ?? 0;
    final protein = (meal['proteinGrams'] as num?)?.toDouble() ?? 0.0;
    final carbs = (meal['carbsGrams'] as num?)?.toDouble() ?? 0.0;
    final fat = (meal['fatGrams'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(category),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroTag('$calories', 'cal', Colors.orange),
                _buildMacroTag('${protein.toStringAsFixed(1)}g', 'protein', Colors.red),
                _buildMacroTag('${carbs.toStringAsFixed(1)}g', 'carbs', Colors.blue),
                _buildMacroTag('${fat.toStringAsFixed(1)}g', 'fat', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroTag(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
