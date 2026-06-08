import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final theme = Theme.of(context);

    if (chat.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Envie uma mensagem para criar, listar ou atualizar tarefas.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.builder(
      key: ValueKey(theme.brightness),
      padding: const EdgeInsets.all(10),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        final bubbleColor =
            message.isUser
                ? theme.colorScheme.tertiary
                : theme.colorScheme.primary;
        final bubbleTextColor =
            message.isUser
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onPrimary;

        return Dismissible(
          key: ValueKey('${message.isUser}-${message.text}-$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.transparent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Icon(
              Icons.delete_forever,
              color: theme.colorScheme.error,
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
                color: bubbleColor,
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
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                message.text,
                textAlign: message.isUser ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  color: bubbleTextColor,
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
