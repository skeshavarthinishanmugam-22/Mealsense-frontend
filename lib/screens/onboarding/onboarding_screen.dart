import 'package:flutter/material.dart';
import '../../providers/user_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  bool _isLoading = false;

  // Collected data
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String? _gender;
  String? _goal;
  String? _activity;
  final List<String> _allergies = [];

  // 4 steps matching exactly what backend needs
  final _steps = ['Body Metrics', 'Fitness Goal', 'Activity Level', 'Allergies'];

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        if (_ageCtrl.text.trim().isEmpty ||
            _heightCtrl.text.trim().isEmpty ||
            _weightCtrl.text.trim().isEmpty ||
            _gender == null) {
          _showError('Please fill all fields and select gender');
          return false;
        }
        final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
        final height = double.tryParse(_heightCtrl.text.trim()) ?? 0;
        final weight = double.tryParse(_weightCtrl.text.trim()) ?? 0;
        if (age < 10 || age > 100) { _showError('Enter valid age (10–100)'); return false; }
        if (height < 100 || height > 250) { _showError('Enter valid height (100–250 cm)'); return false; }
        if (weight < 20 || weight > 300) { _showError('Enter valid weight (20–300 kg)'); return false; }
        return true;
      case 1:
        if (_goal == null) { _showError('Please select your fitness goal'); return false; }
        return true;
      case 2:
        if (_activity == null) { _showError('Please select your activity level'); return false; }
        return true;
      default:
        return true;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _next() async {
    if (!_validateCurrentStep()) return;

    if (_step < _steps.length - 1) {
      setState(() => _step++);
      return;
    }

    // Last step — submit to backend
    setState(() => _isLoading = true);

    // Map frontend labels → backend enum values
    final backendGender = _gender!.toUpperCase() == 'FEMALE' ? 'FEMALE' : 'MALE';
    final backendGoal = switch (_goal!) {
      'Lose Weight'  => 'LOSE_WEIGHT',
      'Gain Muscle'  => 'GAIN_MUSCLE',
      _              => 'MAINTAIN',
    };
    final backendActivity = switch (_activity!) {
      'Sedentary'  => 'SEDENTARY',
      'Light'      => 'LIGHT',
      'Active'     => 'ACTIVE',
      'Very Active' => 'VERY_ACTIVE',
      _            => 'MODERATE',
    };

    final error = await UserProvider.of(context).completeOnboarding(
      age: int.parse(_ageCtrl.text.trim()),
      weightKg: double.parse(_weightCtrl.text.trim()),
      heightCm: double.parse(_heightCtrl.text.trim()),
      gender: backendGender,
      goal: backendGoal,
      activityLevel: backendActivity,
      allergies: List<String>.from(_allergies)..remove('None'),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
      return;
    }

    // Refresh full profile so dashboard has all backend-calculated targets
    await UserProvider.of(context).loadProfile();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Row(
                children: List.generate(_steps.length, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _step ? const Color(0xFF00C853) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 8),
              Text(
                'Step ${_step + 1} of ${_steps.length}: ${_steps[_step]}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Expanded(child: _buildStep()),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => setState(() => _step--),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(_step == _steps.length - 1
                              ? 'Get Started 🚀'
                              : 'Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _StepMetrics(
          ageCtrl: _ageCtrl,
          heightCtrl: _heightCtrl,
          weightCtrl: _weightCtrl,
          gender: _gender,
          onGenderSelect: (v) => setState(() => _gender = v),
        );
      case 1: return _StepGoal(
          selected: _goal,
          onSelect: (v) => setState(() => _goal = v),
        );
      case 2: return _StepActivity(
          selected: _activity,
          onSelect: (v) => setState(() => _activity = v),
        );
      case 3: return _StepAllergies(
          selected: _allergies,
          onToggle: () => setState(() {}),
        );
      default: return const SizedBox();
    }
  }
}

// ── Step 1: Body Metrics ───────────────────────────────────────────────────────

class _StepMetrics extends StatelessWidget {
  final TextEditingController ageCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;
  final String? gender;
  final ValueChanged<String> onGenderSelect;

  const _StepMetrics({
    required this.ageCtrl,
    required this.heightCtrl,
    required this.weightCtrl,
    required this.gender,
    required this.onGenderSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your body metrics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _Field(hint: 'Age', icon: Icons.cake_outlined,
              type: TextInputType.number, controller: ageCtrl),
          const SizedBox(height: 16),
          _Field(hint: 'Height (cm)', icon: Icons.height,
              type: const TextInputType.numberWithOptions(decimal: true),
              controller: heightCtrl),
          const SizedBox(height: 16),
          _Field(hint: 'Weight (kg)', icon: Icons.monitor_weight_outlined,
              type: const TextInputType.numberWithOptions(decimal: true),
              controller: weightCtrl),
          const SizedBox(height: 20),
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: ['Male', 'Female'].map((g) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onGenderSelect(g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: gender == g ? const Color(0xFF00C853) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: gender == g ? const Color(0xFF00C853) : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(g,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: gender == g ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Fitness Goal ───────────────────────────────────────────────────────

class _StepGoal extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _StepGoal({required this.selected, required this.onSelect});

  static const _goals = [
    ('🏃', 'Lose Weight', 'Burn fat and get lean'),
    ('💪', 'Gain Muscle', 'Build strength and mass'),
    ('⚖️', 'Maintain Weight', 'Stay healthy and fit'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("What's your goal?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ..._goals.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => onSelect(g.$2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected == g.$2 ? const Color(0xFFE8F5E9) : Colors.grey[100],
                border: Border.all(
                  color: selected == g.$2 ? const Color(0xFF00C853) : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Text(g.$1, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(g.$3, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                )),
                if (selected == g.$2)
                  const Icon(Icons.check_circle, color: Color(0xFF00C853)),
              ]),
            ),
          ),
        )),
      ],
    );
  }
}

// ── Step 3: Activity Level ─────────────────────────────────────────────────────

class _StepActivity extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _StepActivity({required this.selected, required this.onSelect});

  static const _levels = [
    ('🛋️', 'Sedentary', 'Little or no exercise'),
    ('🚶', 'Light', '1–3 days/week'),
    ('🏋️', 'Moderate', '3–5 days/week'),
    ('🏃', 'Active', '6–7 days/week'),
    ('⚡', 'Very Active', 'Intense daily exercise'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity Level',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ..._levels.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onSelect(l.$2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selected == l.$2 ? const Color(0xFFE8F5E9) : Colors.grey[100],
                border: Border.all(
                  color: selected == l.$2 ? const Color(0xFF00C853) : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Text(l.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(l.$3, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
                const Spacer(),
                if (selected == l.$2)
                  const Icon(Icons.check_circle, color: Color(0xFF00C853)),
              ]),
            ),
          ),
        )),
      ],
    );
  }
}

// ── Step 4: Allergies ──────────────────────────────────────────────────────────

class _StepAllergies extends StatelessWidget {
  final List<String> selected;
  final VoidCallback onToggle;
  const _StepAllergies({required this.selected, required this.onToggle});

  static const _options = [
    'Gluten', 'Dairy', 'Nuts', 'Eggs', 'None',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Any allergies?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Select all that apply (optional)',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _options.map((c) {
            final isSelected = selected.contains(c);
            return GestureDetector(
              onTap: () {
                if (c == 'None') {
                  selected.clear();
                  if (!isSelected) selected.add(c);
                } else {
                  selected.remove('None');
                  isSelected ? selected.remove(c) : selected.add(c);
                }
                onToggle();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00C853) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00C853) : Colors.grey.shade300,
                  ),
                ),
                child: Text(c,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Shared text field ──────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextInputType type;
  final TextEditingController controller;

  const _Field({
    required this.hint,
    required this.icon,
    required this.controller,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}
