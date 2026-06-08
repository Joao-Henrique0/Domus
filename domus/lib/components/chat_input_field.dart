import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'chat_provider.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({super.key});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  void _sendToChatbot(String message, ChatProvider chat, BuildContext context) {
    _controller.clear();
    chat.sendMessage(message, context);
  }

  Future<void> startListening(ChatProvider chat) async {
    final available = await _speech.initialize(
      onStatus: (status) => debugPrint('Status: $status'),
      onError: (error) => debugPrint('Erro: $error'),
    );

    if (!mounted) return;

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
            _isListening = !result.finalResult;
          });
          if (result.finalResult) {
            debugPrint('Texto final: $_lastWords');
            _sendToChatbot(_lastWords, chat, context);
          }
        },
      );
    } else {
      debugPrint('Reconhecimento de voz nao disponivel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Digite uma mensagem...',
                hintStyle: Theme.of(context).textTheme.bodyLarge,
                filled: true,
                fillColor: Theme.of(context).colorScheme.tertiary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    final text = _controller.text;
                    _controller.clear();
                    chat.sendMessage(text, context);
                  },
                ),
                prefixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: () => startListening(chat),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
