import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../infrastructure/services/chatbot_service.dart';
import '../../models/chat_message.dart';
import '../../theme/app_colors.dart';

class ChatBotSheet extends StatefulWidget {
  const ChatBotSheet({
    super.key,
    required this.userId,
    required this.microfinancieraId,
    this.userName,
  });

  final String userId;
  final String microfinancieraId;
  final String? userName;

  @override
  State<ChatBotSheet> createState() => _ChatBotSheetState();
}

class _ChatBotSheetState extends State<ChatBotSheet> {
  late final ChatBotService _chatBotService;
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _chatBotService = ChatBotService();
    _messages.add(
      ChatMessage(
        id: 'welcome',
        content:
            'Hola ${widget.userName?.split(' ').first ?? ''} 👋\nSoy tu agente virtual. Cuéntame qué necesitas y consultaré tus datos para ayudarte.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    final userMessage = ChatMessage(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
      _inputController.clear();
    });
    _scrollToBottom();

    try {
      final history = _messages.map((m) => m.toHistoryPayload()).toList();
      final answer = await _chatBotService.sendMessage(
        message: text,
        userId: widget.userId,
        microfinancieraId: widget.microfinancieraId,
        userName: widget.userName,
        history: history,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: 'bot-${DateTime.now().microsecondsSinceEpoch}',
            content: answer,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: 'error-${DateTime.now().microsecondsSinceEpoch}',
            content:
                'No pude contactar al agente. Intenta nuevamente.\nDetalle: $e',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 96,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Asistente IA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Consultas en tiempo real para ${widget.userName ?? 'tu cuenta'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final alignment = message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft;
                        final bubbleColor = message.isUser
                            ? AppColors.primary
                            : message.isError
                                ? Colors.red.shade100
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant;
                        final textColor = message.isUser
                            ? Colors.white
                            : message.isError
                                ? Colors.red.shade900
                                : Theme.of(context).colorScheme.onSurface;

                        return Align(
                          alignment: alignment,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(
                                  message.isUser ? 16 : 4,
                                ),
                                bottomRight: Radius.circular(
                                  message.isUser ? 4 : 16,
                                ),
                              ),
                            ),
                            child: _buildMessageContent(
                              context: context,
                              message: message,
                              textColor: textColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isSending)
                    const LinearProgressIndicator(
                      minHeight: 2,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _handleSend(),
                            decoration: InputDecoration(
                              hintText: 'Escribe tu consulta...',
                              filled: true,
                              fillColor:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton(
                          heroTag: 'chatbot-send-btn',
                          mini: true,
                          backgroundColor: AppColors.primary,
                          onPressed: _handleSend,
                          child: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.send),
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
    );
  }

  Widget _buildMessageContent({
    required BuildContext context,
    required ChatMessage message,
    required Color textColor,
  }) {
    if (message.isUser || message.isError) {
      return Text(
        message.content,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          height: 1.35,
        ),
      );
    }

    return MarkdownBody(
      data: message.content,
      shrinkWrap: true,
      selectable: false,
      styleSheet: _markdownStyle(context, textColor),
      onTapLink: (text, href, title) => _handleLinkTap(href),
    );
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context, Color textColor) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium?.copyWith(
      color: textColor,
      fontSize: 14,
      height: 1.4,
    );

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: base,
      h1: base?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      h2: base?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      h3: base?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      listBullet: base,
      blockquoteDecoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppColors.primary.withOpacity(0.6),
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      tableHead: base?.copyWith(fontWeight: FontWeight.w700),
      tableBody: base,
      tableBorder: TableBorder.all(
        color: textColor.withOpacity(0.3),
        width: 0.5,
      ),
      tableCellsDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: textColor.withOpacity(0.12)),
          bottom: BorderSide(color: textColor.withOpacity(0.12)),
          left: BorderSide(color: textColor.withOpacity(0.05)),
          right: BorderSide(color: textColor.withOpacity(0.05)),
        ),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: textColor.withOpacity(0.25)),
        ),
      ),
    );
  }

  Future<void> _handleLinkTap(String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }
}
