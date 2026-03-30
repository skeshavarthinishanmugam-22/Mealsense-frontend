import 'package:flutter/material.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _waterReminder = true;
  bool _breakfastReminder = true;
  bool _lunchReminder = false;
  bool _dinnerReminder = true;
  bool _whatsappReminder = false;

  static const _waterTimes = ['8:00 AM', '10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM', '8:00 PM'];
  static const _meals = [
    ('🌅', 'Breakfast', '8:00 AM'),
    ('☀️', 'Lunch', '1:00 PM'),
    ('🌙', 'Dinner', '8:00 PM'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Water Reminder Section
            _SectionHeader(title: '💧 Water Reminders', trailing: Switch(
              value: _waterReminder,
              onChanged: (v) => setState(() => _waterReminder = v),
              activeThumbColor: const Color(0xFF1E88E5),
            )),
            if (_waterReminder) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Remind me every 2 hours', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _waterTimes.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF1E88E5)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.water_drop, size: 14, color: Color(0xFF1E88E5)),
                          const SizedBox(width: 4),
                          Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFF1E88E5), fontWeight: FontWeight.w600)),
                        ]),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Meal Reminders Section
            const Text('🍽️ Meal Reminders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...[
              (_breakfastReminder, (v) => setState(() => _breakfastReminder = v), _meals[0]),
              (_lunchReminder,     (v) => setState(() => _lunchReminder = v),     _meals[1]),
              (_dinnerReminder,    (v) => setState(() => _dinnerReminder = v),     _meals[2]),
            ].map((entry) {
              final enabled = entry.$1;
              final onChanged = entry.$2;
              final meal = entry.$3;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
                child: ListTile(
                  leading: Text(meal.$1, style: const TextStyle(fontSize: 28)),
                  title: Text(meal.$2, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(meal.$3),
                  trailing: Switch(
                    value: enabled,
                    onChanged: onChanged,
                    activeThumbColor: const Color(0xFF00C853),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // WhatsApp Reminder Simulation
            const Text('📱 WhatsApp Reminders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Simulate WhatsApp-style reminders', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(children: [
                        Text('💬', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 8),
                        Text('Enable WhatsApp Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                      Switch(
                        value: _whatsappReminder,
                        onChanged: (v) => setState(() => _whatsappReminder = v),
                        activeThumbColor: const Color(0xFF00C853),
                      ),
                    ],
                  ),
                  if (_whatsappReminder) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    _WhatsAppPreview(
                      message: '💧 Time to drink water! You\'ve had 3/8 glasses today. Stay hydrated! 🌊',
                      time: '10:00 AM',
                    ),
                    const SizedBox(height: 8),
                    _WhatsAppPreview(
                      message: '🍽️ Lunch time! Don\'t forget your meal. Today\'s suggestion: Dal + Brown Rice 🥗',
                      time: '1:00 PM',
                    ),
                    const SizedBox(height: 8),
                    _WhatsAppPreview(
                      message: '🔥 You\'ve burned 312 kcal today! Keep going, you\'re doing great! 💪',
                      time: '6:00 PM',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📱 WhatsApp reminders activated!'),
                            backgroundColor: Color(0xFF00C853),
                          ),
                        ),
                        icon: const Icon(Icons.send),
                        label: const Text('Send Test Reminder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget trailing;
  const _SectionHeader({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        trailing,
      ],
    );
  }
}

class _WhatsAppPreview extends StatelessWidget {
  final String message;
  final String time;
  const _WhatsAppPreview({required this.message, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: Color(0xFF00C853), shape: BoxShape.circle),
              child: const Center(child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
            ),
            const SizedBox(width: 8),
            const Text('MealSense Bot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00C853))),
          ]),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
