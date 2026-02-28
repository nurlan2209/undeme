import 'package:flutter/material.dart';

import '../../../utils/colors.dart';
import '../../../utils/text_styles.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../data/ai_repository.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.onNavigateBack});

  final Function(int)? onNavigateBack;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final AiRepository _repository = AiRepository();
  final TextEditingController _controller = TextEditingController();

  final List<_ChatMessage> _messages = <_ChatMessage>[];
  bool _sending = false;
  bool _historyLoading = false;
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        role: _Role.assistant,
        text:
            'Бұл чат тек бағыт-бағдар береді. Қауіп төнсе, дереу 112 нөміріне хабарласыңыз.',
      ),
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String text, {String context = 'general'}) async {
    final message = text.trim();
    if (message.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(role: _Role.user, text: message));
    });

    _controller.clear();

    try {
      final response =
          await _repository.sendMessage(message: message, context: context);
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _Role.assistant,
            text: response['message']?.toString() ?? 'Жауап алынбады',
          ),
        );
      });
    } catch (error) {
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _Role.assistant,
            text:
                'AI сервисте қате болды: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyLoading = true;
    });

    try {
      final items = await _repository.history();
      final chronological = items.reversed.toList();

      for (final item in chronological) {
        final message = item['message']?.toString().trim() ?? '';
        final response = item['response']?.toString().trim() ?? '';

        if (message.isNotEmpty) {
          _messages.add(_ChatMessage(role: _Role.user, text: message));
        }
        if (response.isNotEmpty) {
          _messages.add(_ChatMessage(role: _Role.assistant, text: response));
        }
      }
    } catch (_) {
      // History is optional for rendering; keep chat available.
    } finally {
      if (mounted) {
        setState(() {
          _historyLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Қауіпсіздік кеңесшісі'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Text(
              'Дисклеймер: жауаптар құқықтық/медициналық қорытынды емес. Қауіп болса 112-ге хабарласыңыз.',
              style: AppTextStyles.caption,
            ),
          ),
          _QuickPrompts(
              onTap: (value, context) => _send(value, context: context)),
          Expanded(
            child: _historyLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final item = _messages[index];
                      final isUser = item.role == _Role.user;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: isUser
                                ? null
                                : Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            item.text,
                            style: TextStyle(
                              color:
                                  isUser ? Colors.white : AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      decoration: InputDecoration(
                        hintText: 'Сұрағыңызды жазыңыз...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sending ? null : () => _send(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Жіберу'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != _currentIndex && widget.onNavigateBack != null) {
            widget.onNavigateBack!(index);
          }
        },
      ),
    );
  }
}

class _QuickPrompts extends StatelessWidget {
  const _QuickPrompts({required this.onTap});

  final void Function(String text, String context) onTap;

  @override
  Widget build(BuildContext context) {
    final prompts = <({String title, String text, String context})>[
      (
        title: 'Задержание',
        text: 'Мені полиция ұстады, не істеуім керек?',
        context: 'detention',
      ),
      (
        title: 'Медициналық көмек',
        text: 'Жарақат жағдайында алғашқы қадамдар қандай?',
        context: 'medical',
      ),
      (
        title: 'Зорлық қаупі',
        text: 'Үйдегі зорлық қаупі кезінде қауіпсіздік жоспары қандай?',
        context: 'domestic_violence',
      ),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = prompts[index];
          return ActionChip(
            label: Text(item.title),
            onPressed: () => onTap(item.text, item.context),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: prompts.length,
      ),
    );
  }
}

enum _Role { user, assistant }

class _ChatMessage {
  _ChatMessage({required this.role, required this.text});

  final _Role role;
  final String text;
}
