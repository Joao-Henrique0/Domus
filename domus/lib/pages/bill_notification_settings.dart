import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:domus/models/bill_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillNotificationSettings extends StatefulWidget {
  const BillNotificationSettings({super.key});

  @override
  State<BillNotificationSettings> createState() =>
      _BillNotificationSettingsState();
}

class _BillNotificationSettingsState extends State<BillNotificationSettings> {
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
    if (!mounted) return;
    setState(() {
      _firstNotificationController.text =
          (prefs.getInt('bill_first_notification_days') ?? 5).toString();
      _repeatIntervalController.text =
          (prefs.getInt('bill_repeat_interval_days') ?? 1).toString();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final firstNotification =
        int.tryParse(_firstNotificationController.text) ?? 5;
    final repeatInterval = int.tryParse(_repeatIntervalController.text) ?? 1;

    await prefs.setInt(
      'bill_first_notification_days',
      firstNotification.clamp(0, 365).toInt(),
    );
    await prefs.setInt(
      'bill_repeat_interval_days',
      repeatInterval.clamp(1, 365).toInt(),
    );

    if (!mounted) return;
    await Provider.of<BillList>(
      context,
      listen: false,
    ).rescheduleOpenBillNotifications();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuracoes salvas!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificacoes de contas')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _firstNotificationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Dias antes do vencimento',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _repeatIntervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Intervalo de repeticao (dias)',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Salvar Configuracoes'),
            ),
          ],
        ),
      ),
    );
  }
}
