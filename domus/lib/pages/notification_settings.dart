import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:domus/models/task_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  final _firstNotificationController = TextEditingController();
  final _repeatIntervalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _firstNotificationController.dispose();
    _repeatIntervalController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNotificationController.text =
          (prefs.getInt('first_notification') ?? 30).toString();
      _repeatIntervalController.text =
          (prefs.getInt('repeat_interval') ?? 20).toString();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final firstNotification =
        int.tryParse(_firstNotificationController.text) ?? 30;
    final repeatInterval =
        int.tryParse(_repeatIntervalController.text) ?? 20;

    await prefs.setInt(
      'first_notification',
      firstNotification.clamp(0, 10080).toInt(),
    );
    await prefs.setInt(
      'repeat_interval',
      repeatInterval.clamp(1, 1440).toInt(),
    );

    if (!mounted) return;
    await Provider.of<TaskList>(
      context,
      listen: false,
    ).rescheduleOpenTaskNotifications();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações salvas!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações de Notificação')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _firstNotificationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutos antes da tarefa (primeira notificação)',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _repeatIntervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Intervalo de repetição (minutos)',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Salvar Configurações'),
            ),
          ],
        ),
      ),
    );
  }
}
