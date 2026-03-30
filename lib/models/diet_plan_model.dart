class MealEntry {
  final String name;
  final int calories;
  const MealEntry(this.name, this.calories);
}

class DietPlanModel {
  final String title;
  final String description;
  final int color;
  final String icon;
  final int totalCalories;
  final List<MealEntry> breakfast;
  final List<MealEntry> lunch;
  final List<MealEntry> dinner;

  const DietPlanModel({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.totalCalories,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });
}

final List<DietPlanModel> dummyPlans = [
  DietPlanModel(
    title: 'Weight Loss',
    description: 'Calorie deficit with high protein',
    color: 0xFF4CAF50,
    icon: '🥗',
    totalCalories: 1500,
    breakfast: [MealEntry('Oats with milk', 200), MealEntry('Boiled egg', 78)],
    lunch: [MealEntry('Dal + Brown Rice', 350), MealEntry('Salad', 50)],
    dinner: [MealEntry('Grilled Chicken', 200), MealEntry('Stir-fried veggies', 100)],
  ),
  DietPlanModel(
    title: 'Muscle Gain',
    description: 'High protein calorie surplus',
    color: 0xFF2196F3,
    icon: '💪',
    totalCalories: 2500,
    breakfast: [MealEntry('Eggs x4', 312), MealEntry('Whole wheat toast', 140)],
    lunch: [MealEntry('Chicken Breast + Rice', 500), MealEntry('Protein shake', 150)],
    dinner: [MealEntry('Paneer curry', 350), MealEntry('Roti x2', 200)],
  ),
  DietPlanModel(
    title: 'Keto',
    description: 'Low carb, high fat diet',
    color: 0xFFFF9800,
    icon: '🥑',
    totalCalories: 1800,
    breakfast: [MealEntry('Avocado + Eggs', 350), MealEntry('Black coffee', 5)],
    lunch: [MealEntry('Grilled salmon', 400), MealEntry('Spinach salad', 80)],
    dinner: [MealEntry('Butter chicken (no rice)', 450), MealEntry('Cheese', 100)],
  ),
  DietPlanModel(
    title: 'Vegan',
    description: 'Plant-based balanced diet',
    color: 0xFF9C27B0,
    icon: '🌱',
    totalCalories: 1700,
    breakfast: [MealEntry('Smoothie bowl', 280), MealEntry('Chia seeds', 60)],
    lunch: [MealEntry('Chickpea curry + Rice', 420), MealEntry('Fruit salad', 80)],
    dinner: [MealEntry('Tofu stir fry', 300), MealEntry('Quinoa', 180)],
  ),
];
