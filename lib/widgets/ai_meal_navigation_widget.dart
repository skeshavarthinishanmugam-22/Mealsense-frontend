import 'package:flutter/material.dart';
import '../screens/food/ai_suggestions_screen.dart';
import '../screens/activity/meal_history_screen.dart';

class AiMealNavigationWidget extends StatelessWidget {
  const AiMealNavigationWidget({super.key});

  void _showMealTypeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Get AI Suggestions For',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMealTypeButton(
              context,
              'breakfast',
              Icons.breakfast_dining,
              Colors.orange,
            ),
            _buildMealTypeButton(
              context,
              'lunch',
              Icons.lunch_dining,
              Colors.green,
            ),
            _buildMealTypeButton(
              context,
              'dinner',
              Icons.dinner_dining,
              Colors.blue,
            ),
            _buildMealTypeButton(
              context,
              'snack',
              Icons.fastfood,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeButton(
    BuildContext context,
    String mealType,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          mealType.toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        tileColor: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text('${mealType.toUpperCase()} Suggestions'),
                ),
                body: AiSuggestionsScreen(mealType: mealType),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showMealTypeBottomSheet(context),
              icon: const Icon(Icons.stars),
              label: const Text('AI Suggestions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Meal History')),
                      body: const MealHistoryScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
