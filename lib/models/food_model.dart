class FoodModel {
  final String id;
  final String name;
  final String category; // BREAKFAST | LUNCH | DINNER | SNACK | PROTEIN
  final String? subCategory;
  final String portionDescription;
  final int calorieRangeMin;
  final int calorieRangeMax;
  final String calorieRangeLabel;
  final String proteinLevel; // LOW | MEDIUM | HIGH
  final int healthScore;
  final String trafficLight; // GREEN | YELLOW | RED
  final String trafficLightMessage;
  final bool isVegetarian;
  final bool isVegan;
  final bool containsGluten;
  final bool containsDairy;
  final bool containsNuts;
  final bool containsEggs;
  final String? substitutes;

  const FoodModel({
    required this.id,
    required this.name,
    required this.category,
    this.subCategory,
    required this.portionDescription,
    required this.calorieRangeMin,
    required this.calorieRangeMax,
    required this.calorieRangeLabel,
    required this.proteinLevel,
    required this.healthScore,
    required this.trafficLight,
    required this.trafficLightMessage,
    required this.isVegetarian,
    required this.isVegan,
    required this.containsGluten,
    required this.containsDairy,
    required this.containsNuts,
    required this.containsEggs,
    this.substitutes,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) => FoodModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        subCategory: json['subCategory'] as String?,
        portionDescription: json['portionDescription'] as String? ?? '',
        calorieRangeMin: json['calorieRangeMin'] as int? ?? 0,
        calorieRangeMax: json['calorieRangeMax'] as int? ?? 0,
        calorieRangeLabel: json['calorieRangeLabel'] as String? ?? '',
        proteinLevel: json['proteinLevel'] as String? ?? 'LOW',
        healthScore: json['healthScore'] as int? ?? 0,
        trafficLight: json['trafficLight'] as String? ?? 'GREEN',
        trafficLightMessage: json['trafficLightMessage'] as String? ?? '',
        isVegetarian: json['isVegetarian'] as bool? ?? false,
        isVegan: json['isVegan'] as bool? ?? false,
        containsGluten: json['containsGluten'] as bool? ?? false,
        containsDairy: json['containsDairy'] as bool? ?? false,
        containsNuts: json['containsNuts'] as bool? ?? false,
        containsEggs: json['containsEggs'] as bool? ?? false,
        substitutes: json['substitutes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'subCategory': subCategory,
        'portionDescription': portionDescription,
        'calorieRangeMin': calorieRangeMin,
        'calorieRangeMax': calorieRangeMax,
        'calorieRangeLabel': calorieRangeLabel,
        'proteinLevel': proteinLevel,
        'healthScore': healthScore,
        'trafficLight': trafficLight,
        'trafficLightMessage': trafficLightMessage,
        'isVegetarian': isVegetarian,
        'isVegan': isVegan,
        'containsGluten': containsGluten,
        'containsDairy': containsDairy,
        'containsNuts': containsNuts,
        'containsEggs': containsEggs,
        'substitutes': substitutes,
      };

  String get emoji {
    switch (category) {
      case 'BREAKFAST': return '🍳';
      case 'LUNCH':     return '🍱';
      case 'DINNER':    return '🍛';
      case 'SNACK':     return '🥪';
      case 'PROTEIN':   return '💪';
      default:          return '🥗';
    }
  }

  String get categoryLabel =>
      category[0] + category.substring(1).toLowerCase();
}
