import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        title: Text('Кеңесші', style: AppTextStyles.label.copyWith(fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.pureWhite.withValues(alpha: 0.85),
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: AppColors.border,
            height: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              'Бұл жауаптар құқықтық немесе медициналық қорытынды емес. Қауіп төнген жағдайда 112 нөміріне хабарласыңыз.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _historyLoading
                ? const Center(child: CupertinoActivityIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 140, top: 8), // Padding for frosted bottom
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final item = _messages[index];
                      final isUser = item.role == _Role.user;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUser ? CupertinoColors.systemBlue : AppColors.inputBg,
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                              bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(20),
                            ),
                          ),
                          child: Text(
                            item.text,
                            style: AppTextStyles.body.copyWith(
                              color: isUser ? AppColors.pureWhite : AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.pureWhite.withValues(alpha: 0.85),
              border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _QuickPrompts(
                      onTap: (value, context) => _send(value, context: context)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            child: TextField(
                              controller: _controller,
                              enabled: !_sending,
                              style: AppTextStyles.body,
                              maxLines: 4,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: 'Сұрағыңызды жазыңыз...',
                                hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sending ? null : () => _send(_controller.text),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _sending ? AppColors.border : CupertinoColors.systemBlue,
                              shape: BoxShape.circle,
                            ),
                            child: _sending
                                ? const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: CupertinoActivityIndicator(color: Colors.white, radius: 8),
                                  )
                                : const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ActionChip(
              label: Text(item.title, style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.textPrimary)),
              backgroundColor: AppColors.inputBg,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => onTap(item.text, item.context),
            ),
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
