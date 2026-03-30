class UserModel {
  final String name;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String goal;
  final String activityLevel;
  final List<String> medicalConditions;
  final int dailyCalorieTarget;
  final int waterTargetMl;

  const UserModel({
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activityLevel,
    required this.medicalConditions,
    required this.dailyCalorieTarget,
    required this.waterTargetMl,
  });
}

final dummyUser = UserModel(
  name: 'Keshav',
  age: 22,
  gender: 'Male',
  heightCm: 175,
  weightKg: 70,
  goal: 'Weight Loss',
  activityLevel: 'Moderate',
  medicalConditions: [],
  dailyCalorieTarget: 1800,
  waterTargetMl: 2500,
);
