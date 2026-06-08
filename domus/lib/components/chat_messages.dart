import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final theme = Theme.of(context); // Adicione esta linha

    return ListView.builder(
      key: ValueKey(theme.brightness), // Força rebuild ao trocar o tema
      padding: const EdgeInsets.all(10),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        return Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.transparent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Icon(
              Icons.delete_forever,
              color: Color.fromARGB(255, 143, 136, 136),
              size: 32,
            ),
          ),
          onDismissed: (_) {
            chat.deleteMessage(index);
          },
          child: Align(
            alignment:
                message.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
                minWidth: 40,
              ),
              decoration: BoxDecoration(
                color:
                    message.isUser
                        ? Colors.grey.shade200
                        : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      message.isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                  bottomRight:
                      message.isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                message.text,
                textAlign: message.isUser ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  color: message.isUser ? Colors.black87 : Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
