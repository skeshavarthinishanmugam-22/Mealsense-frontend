import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/chat_bubble_widget.dart';

class _Message {
  final String text;
  final bool isUser;
  final String time;
  const _Message({required this.text, required this.isUser, required this.time});
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> with SingleTickerProviderStateMixin {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  bool _isTyping = false;
  bool _hasText = false;

  late AnimationController _sendBtnCtrl;

  static const _welcome =
      "Hello! I'm Dr. Sense 🩺, your AI health assistant.\n\n"
      "I can help you with:\n"
      "• 🥗 Diet tips\n"
      "• 💪 Protein foods\n"
      "• ⚖️ Weight loss advice\n"
      "• 💧 Hydration tips\n"
      "• 😴 Sleep & recovery\n"
      "• 🔥 Calories info\n"
      "• 🍳 Breakfast ideas\n\n"
      "Just type your question and I'll guide you!";

  static const Map<String, String> _responses = {
    'diet': "Here are some great diet tips for you:\n\n"
        "🥦 1. Fill half your plate with vegetables\n"
        "🍗 2. Include lean protein in every meal\n"
        "🌾 3. Choose whole grains over refined carbs\n"
        "🚫 4. Avoid processed and packaged foods\n"
        "🍽️ 5. Eat smaller portions, more frequently\n"
        "💧 6. Stay hydrated — aim for 8 glasses/day\n\n"
        "Consistency is key! Small changes lead to big results. 💪",

    'protein': "Top protein-rich foods for your goals:\n\n"
        "🍗 Chicken Breast — 31g per 100g\n"
        "🥚 Eggs — 13g per 100g\n"
        "🐟 Tuna / Salmon — 25g per 100g\n"
        "🫘 Lentils (Dal) — 9g per 100g\n"
        "🧀 Paneer — 18g per 100g\n"
        "🥛 Greek Yogurt — 10g per 100g\n"
        "🌱 Tofu — 8g per 100g\n"
        "🥜 Peanut Butter — 25g per 100g\n\n"
        "Aim for 0.8–1.2g of protein per kg of body weight daily! 🎯",

    'weight loss': "Effective weight loss strategies:\n\n"
        "🔥 1. Create a 300–500 calorie daily deficit\n"
        "🏃 2. Do 150+ mins of cardio per week\n"
        "💪 3. Add strength training 3x/week\n"
        "🥗 4. Prioritize protein to preserve muscle\n"
        "😴 5. Sleep 7–9 hours — poor sleep = weight gain\n"
        "📱 6. Track your meals with MealSense\n"
        "💧 7. Drink water before meals\n\n"
        "Remember: slow and steady wins the race! 🐢✨",

    'water': "Hydration tips for better health:\n\n"
        "💧 Aim for 2.5–3L of water daily\n"
        "🌅 Start your morning with a glass of water\n"
        "🍋 Add lemon for electrolytes\n"
        "⏰ Drink a glass 30 mins before each meal\n"
        "🏋️ Increase intake on workout days\n\n"
        "Dehydration can mimic hunger — stay hydrated! 💦",

    'sleep': "Sleep & recovery tips:\n\n"
        "😴 Aim for 7–9 hours of quality sleep\n"
        "📵 Avoid screens 1 hour before bed\n"
        "🌡️ Keep your room cool (18–20°C)\n"
        "☕ No caffeine after 2 PM\n"
        "🧘 Try 5 mins of deep breathing before sleep\n\n"
        "Poor sleep raises cortisol and increases fat storage! 🚨",

    'calories': "Understanding calories:\n\n"
        "📊 1g Protein = 4 calories\n"
        "📊 1g Carbs = 4 calories\n"
        "📊 1g Fat = 9 calories\n\n"
        "Your daily needs depend on:\n"
        "• Age, gender, height, weight\n"
        "• Activity level\n"
        "• Fitness goal\n\n"
        "Use MealSense's onboarding to get your personalized calorie target! 🎯",

    'breakfast': "Healthy breakfast ideas:\n\n"
        "🥣 Oats with banana and nuts\n"
        "🥚 Scrambled eggs with whole wheat toast\n"
        "🥛 Greek yogurt with berries\n"
        "🫓 Poha with vegetables\n"
        "🥤 Smoothie with spinach, banana & protein\n\n"
        "Never skip breakfast — it kickstarts your metabolism! ⚡",
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _sendBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );

    _inputCtrl.addListener(() {
      setState(() => _hasText = _inputCtrl.text.trim().isNotEmpty);
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _addAiMessage(_welcome);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _sendBtnCtrl.dispose();
    super.dispose();
  }

  String _getTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _addAiMessage(String text) {
    setState(() {
      _messages.add(_Message(text: text, isUser: false, time: _getTime()));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getAiResponse(String input) {
    final lower = input.toLowerCase();
    for (final key in _responses.keys) {
      if (lower.contains(key)) return _responses[key]!;
    }
    return "That's a great question! 🤔\n\n"
        "Try asking me about:\n"
        "• 'diet' — nutrition tips\n"
        "• 'protein' — protein-rich foods\n"
        "• 'weight loss' — fat loss strategies\n"
        "• 'water' — hydration advice\n"
        "• 'sleep' — recovery tips\n"
        "• 'calories' — macro breakdown\n"
        "• 'breakfast' — morning meal ideas\n\n"
        "I'm here to help! 😊";
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add(_Message(text: text, isUser: true, time: _getTime()));
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    setState(() => _isTyping = false);
    _addAiMessage(_getAiResponse(text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_isTyping && i == _messages.length) {
                        return ChatBubble(
                          message: '',
                          isUser: false,
                          time: _getTime(),
                          isTyping: true,
                        );
                      }
                      final msg = _messages[i];
                      return ChatBubble(
                        message: msg.text,
                        isUser: msg.isUser,
                        time: msg.time,
                      );
                    },
                  ),
          ),
          _buildQuickReplies(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00897B)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C853).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(child: Text('🩺', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dr. Sense',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isTyping ? 'typing...' : 'AI Health Assistant • Online',
                          style: TextStyle(
                            color: _isTyping
                                ? const Color(0xFF00C853)
                                : Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showInfoSheet,
                icon: Icon(Icons.info_outline_rounded,
                    color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: Text('🩺', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 16),
          Text(
            'Starting conversation...',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    const chips = ['Diet tips', 'Protein foods', 'Weight loss', 'Sleep tips', 'Calories'];
    return Container(
      color: const Color(0xFFF0F4F8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _sendMessage(chips[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: const Color(0xFF00C853).withValues(alpha: 0.4)),
              ),
              child: Text(
                chips[i],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF00897B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                            fontSize: 14.5, color: Color(0xFF1A1A2E)),
                        decoration: InputDecoration(
                          hintText: 'Ask Dr. Sense anything...',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: _sendBtnCtrl,
              child: GestureDetector(
                onTapDown: (_) => _sendBtnCtrl.reverse(),
                onTapUp: (_) => _sendBtnCtrl.forward(),
                onTapCancel: () => _sendBtnCtrl.forward(),
                onTap: _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _hasText
                        ? const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF00897B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _hasText ? null : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _hasText
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00C853).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _hasText ? Colors.white : Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00897B)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                  child: Text('🩺', style: TextStyle(fontSize: 32))),
            ),
            const SizedBox(height: 14),
            const Text('Dr. Sense',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A))),
            const SizedBox(height: 4),
            Text('AI Health & Nutrition Assistant',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            ...[
              'Personalized diet recommendations',
              'Nutrition & macro guidance',
              'Weight management tips',
              'Healthy lifestyle advice',
            ].map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF00C853), size: 18),
                    const SizedBox(width: 10),
                    Text(t,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF1A1A2E))),
                  ]),
                )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Not a substitute for professional medical advice.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
