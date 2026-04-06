import 'package:flutter/material.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../reminders/reminders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;

  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with empty values, will be populated when profile loads
    _nameCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = UserProvider.of(context);
    final user = notifier.user;
    
    // Update text field values from current user data
    _nameCtrl.text = user?.name ?? '';
    _ageCtrl.text = '${user?.age ?? ''}';
    _weightCtrl.text = '${user?.weightKg ?? ''}';
    _heightCtrl.text = '${user?.heightCm ?? ''}';
    
    // Load profile only once and cache it for the session
    if (!_profileLoaded) {
      _profileLoaded = true;
      print('[Profile] First load, fetching profile from provider...');
      notifier.loadProfile();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEdits(AppUser user) async {
    final notifier = UserProvider.of(context);
    final name = _nameCtrl.text.trim().isEmpty ? user.name : _nameCtrl.text.trim();
    // Call backend to update display name, then refresh profile cache
    await ApiService.updateProfile(displayName: name);
    print('[Profile] Profile update, refreshing cache...');
    await notifier.refreshProfile();
    setState(() => _editing = false);
  }

  void _showChangeGoalDialog(BuildContext context) {
    final goals = [
      ('LOSE_WEIGHT', '🏃 Lose Weight'),
      ('GAIN_MUSCLE', '💪 Gain Muscle'),
      ('MAINTAIN', '⚖️ Maintain Weight'),
    ];
    
    String selectedGoal = UserProvider.of(context).user?.goal ?? 'LOSE_WEIGHT';
    final currentUser = UserProvider.of(context).user;

    print('[Profile] Change Goal dialog opened');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Goal'),
        content: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: goals.map((goal) {
                final isSelected = selectedGoal == goal.$1;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                  child: ListTile(
                    onTap: () {
                      setState(() => selectedGoal = goal.$1);
                    },
                    title: Text(
                      goal.$2,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF00C853) : Colors.black,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFF00C853))
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              print('[Profile] Change Goal dialog cancelled');
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final goalLabel = goals.firstWhere((g) => g.$1 == selectedGoal).$2;
              print('[Profile] Goal submitted: $selectedGoal');
              
              if (currentUser == null) {
                print('[Profile] User not found');
                if (context.mounted) Navigator.pop(context);
                return;
              }
              
              try {
                print('[Profile] Calling API to update fitness goal with recalculation...');
                final response = await ApiService.updateFitnessGoal(goal: selectedGoal);
                print('[Profile] API Response: ${response['statusCode']}');
                print('[Profile] New calorie target: ${response['dailyCalorieTarget']}');
                print('[Profile] New protein target: ${response['dailyProteinTarget']}');
                
                if (!context.mounted) {
                  print('[Profile] Context unmounted after API call');
                  return;
                }
                
                // Refresh profile cache to reflect changes
                print('[Profile] Goal updated, refreshing profile cache...');
                final notifier = UserProvider.of(context);
                await notifier.refreshProfile();
                
                if (!context.mounted) {
                  print('[Profile] Context unmounted after profile reload');
                  return;
                }
                
                print('[Profile] Goal update successful, closing dialog');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Goal updated to: $goalLabel\nCalories: ${response['dailyCalorieTarget']} | Protein: ${response['dailyProteinTarget']}g'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: const Color(0xFF00C853),
                  ),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e, st) {
                print('[Profile] Error updating goal: $e');
                print('[Profile] Stack trace: $st');
                
                if (!context.mounted) {
                  print('[Profile] Context unmounted, skipping error UI');
                  return;
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showFeedback(BuildContext context, String label) {
    print('[Profile] $label tapped');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label feature coming soon'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.grey[700],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    print('[Profile] About MealSense dialog opened');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About MealSense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant, color: Color(0xFF00C853), size: 48),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'MealSense',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00C853)),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your intelligent meal planning companion. MealSense helps you make healthier food choices based on your personal goals and nutritional requirements.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '© 2026 MealSense\nAll rights reserved',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                print('[Profile] About MealSense dialog closed');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = UserProvider.of(context);
    final user = notifier.user;

    if (user == null) {
      return const Center(child: Text('No profile data found.\nPlease complete onboarding.', textAlign: TextAlign.center));
    }

    final bmi = user.bmi;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () {
                    if (_editing) {
                      _saveEdits(user);
                    } else {
                      setState(() => _editing = true);
                    }
                  },
                  icon: Icon(_editing ? Icons.check_circle : Icons.edit_outlined, color: const Color(0xFF00C853)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Avatar + Name
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF00C853)),
                  ),
                ),
                if (_editing)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFF00C853), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!_editing) ...[
              Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${user.goalEmoji} ${user.goalDisplay}',
                    style: const TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              const SizedBox(height: 4),
              Text(user.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
            const SizedBox(height: 20),

            // Stats Row
            _StatsRow(user: user),
            const SizedBox(height: 16),

            // BMI Card
            _BmiCard(bmi: bmi, category: user.bmiCategory),
            const SizedBox(height: 16),

            // Nutrition Targets
            _NutritionCard(user: user),
            const SizedBox(height: 16),

            // Personal Info Card
            _InfoCard(user: user),
            const SizedBox(height: 16),

            // Edit Form — only name is editable via backend
            if (_editing) ...[
              _SectionTitle('Edit Profile'),
              const SizedBox(height: 12),
              _EditField(controller: _nameCtrl, label: 'Display Name', icon: Icons.person_outline),
              const SizedBox(height: 8),
              Text('To update body metrics, please redo onboarding.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 20),
            ],

            // Settings
            _SectionTitle('Settings'),
            const SizedBox(height: 12),
            _SettingsTile(icon: Icons.notifications_outlined, label: 'Reminders', color: const Color(0xFF1E88E5),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()))),
            _SettingsTile(icon: Icons.flag_outlined, label: 'Change Goal', color: const Color(0xFF00C853), 
              onTap: () => _showChangeGoalDialog(context)),
            _SettingsTile(icon: Icons.lock_outline, label: 'Privacy & Security', color: const Color(0xFF8E24AA), 
              onTap: () => _showFeedback(context, 'Privacy & Security')),
            _SettingsTile(icon: Icons.help_outline, label: 'Help & Support', color: const Color(0xFFFF9800), 
              onTap: () => _showFeedback(context, 'Help & Support')),
            _SettingsTile(icon: Icons.info_outline, label: 'About MealSense', color: Colors.grey, 
              onTap: () => _showAboutDialog(context)),
            const SizedBox(height: 12),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await UserProvider.of(context).logout();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final AppUser user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Weight', value: '${user.weightKg} kg'),
          _VDivider(),
          _StatItem(label: 'Height', value: '${user.heightCm} cm'),
          _VDivider(),
          _StatItem(label: 'Age', value: '${user.age} yrs'),
          _VDivider(),
          _StatItem(label: 'Gender', value: user.gender),
        ],
      ),
    );
  }
}

// ── BMI Card ───────────────────────────────────────────────────────────────────

class _BmiCard extends StatelessWidget {
  final double bmi;
  final String category;
  const _BmiCard({required this.bmi, required this.category});

  Color get _color {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return const Color(0xFF00C853);
    if (bmi < 30.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(Icons.monitor_heart_outlined, color: _color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Body Mass Index (BMI)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Row(children: [
                Text(bmi.toStringAsFixed(1),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _color)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(category, style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Nutrition Targets Card ─────────────────────────────────────────────────────

class _NutritionCard extends StatelessWidget {
  final AppUser user;
  const _NutritionCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.local_fire_department, color: Color(0xFF00C853), size: 18),
            const SizedBox(width: 6),
            const Text('Daily Nutrition Targets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _MacroChip(label: 'Calories', value: '${user.dailyCalorieTarget}', unit: 'kcal', color: const Color(0xFFFF6B35)),
            const SizedBox(width: 8),
            _MacroChip(label: 'Protein', value: '${user.dailyProteinTarget}', unit: 'g', color: const Color(0xFF1E88E5)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _MacroChip(label: 'Carbs', value: '${user.dailyCarbsTarget}', unit: 'g', color: const Color(0xFFFFB300)),
            const SizedBox(width: 8),
            _MacroChip(label: 'Fat', value: '${user.dailyFatTarget}', unit: 'g', color: const Color(0xFF8E24AA)),
          ]),

        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _MacroChip({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const Spacer(),
          Text('$value $unit', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
    return Expanded(child: child);
  }
}

// ── Personal Info Card ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final AppUser user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.person_outline, color: Color(0xFF00C853), size: 18),
            const SizedBox(width: 6),
            const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
          _InfoRow(icon: Icons.directions_run, label: 'Activity', value: user.activityDisplay),
          if (user.medicalConditions.isNotEmpty && user.medicalConditions.first != 'None')
            _InfoRow(
              icon: Icons.medical_services_outlined,
              label: 'Medical',
              value: user.medicalConditions.join(', '),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 10),
        Text('$label:', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00C853))),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ]);
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: Colors.green.shade200);
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  const _EditField({required this.controller, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
