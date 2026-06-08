import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:domus/models/task.dart';
import 'package:domus/models/task_list.dart';
import 'package:intl/intl.dart';

class TaskForm extends StatefulWidget {
  const TaskForm({super.key});

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _formData = <String, Object>{};
  DateTime _selectedDate = DateTime.now();

  Future<void> _showDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        if (!mounted) return;
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    _formData['time'] = _selectedDate;

    _formKey.currentState?.save();

    try {
      // Salvar a tarefa
      final taskList = Provider.of<TaskList>(context, listen: false);
      await taskList.saveTask(_formData);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (err) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Ocorreu um erro!'),
              content: const Text('Ocorreu um erro ao salvar a tarefa!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Ok'),
                ),
              ],
            ),
      );
      debugPrint(err.toString());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_formData.isEmpty) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg != null) {
        final task = arg as Task;
        _formData['id'] = task.id;
        _formData['title'] = task.title;
        _formData['description'] = task.description;
        _selectedDate = task.time; // Usando o horário registrado no cadastro
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefa'),
        actions: [
          IconButton(onPressed: _submitForm, icon: const Icon(Icons.save)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _formData['title']?.toString(),
                decoration: const InputDecoration(labelText: 'Título'),
                textInputAction: TextInputAction.next,
                onSaved: (newValue) => _formData['title'] = newValue ?? '',
                validator: (name) {
                  final value = name ?? '';
                  if (value.trim().isEmpty) {
                    return 'O Título é obrigatório';
                  }
                  if (value.trim().length < 3) {
                    return 'O Título precisa de no mínimo 3 letras';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _formData['description']?.toString(),
                decoration: const InputDecoration(labelText: 'Descrição'),
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                onSaved:
                    (newValue) => _formData['description'] = newValue ?? '',
              ),
              SizedBox(
                height: 70,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Data e hora selecionadas: ${DateFormat('dd/MM/y HH:mm').format((_formData['time'] as DateTime?) ?? _selectedDate)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _showDatePicker();
                      },
                      child: Text(
                        'Selecionar Data e Hora',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
