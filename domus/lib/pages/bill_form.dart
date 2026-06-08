import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:domus/models/bill.dart';
import 'package:domus/models/bill_list.dart';

class BillForm extends StatefulWidget {
  const BillForm({super.key});

  @override
  State<BillForm> createState() => _BillFormState();
}

class _BillFormState extends State<BillForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  final _formData = <String, Object?>{};

  DateTime _selectedDate = DateTime.now();
  bool _recurring = false;
  BillStatus _status = BillStatus.open;

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _showDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    _formData['title'] = _titleController.text.trim();
    _formData['value'] = double.parse(
      _valueController.text.replaceAll(',', '.'),
    );
    _formData['dueDate'] = _selectedDate;
    _formData['recurring'] = _recurring;
    _formData['status'] = _status;

    try {
      final billList = Provider.of<BillList>(context, listen: false);
      await billList.saveBill(_formData);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (err) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Ocorreu um erro!'),
              content: const Text('Ocorreu um erro ao salvar a conta.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
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
    if (_formData.isNotEmpty) return;

    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg == null) return;

    final bill = arg as Bill;
    _formData['id'] = bill.id;
    _formData['expenseId'] = bill.expenseId;
    _formData['recurringSourceId'] = bill.recurringSourceId;
    _formData['paidDate'] = bill.paidDate;
    _titleController.text = bill.title;
    _valueController.text = bill.value.toStringAsFixed(2).replaceAll('.', ',');
    _selectedDate = bill.dueDate;
    _recurring = bill.recurring;
    _status = bill.status;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/y');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conta'),
        actions: [
          IconButton(onPressed: _submitForm, icon: const Icon(Icons.save)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titulo',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final title = value?.trim() ?? '';
                  if (title.length < 3) {
                    return 'O titulo precisa de no minimo 3 letras';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final isValid = RegExp(
                      r'^\d*([,.]\d{0,2})?$',
                    ).hasMatch(newValue.text);
                    return isValid ? newValue : oldValue;
                  }),
                ],
                validator: (value) {
                  final normalized = (value ?? '').replaceAll(',', '.');
                  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) {
                    return 'Use no maximo 2 casas decimais';
                  }
                  final parsed = double.tryParse(normalized);
                  if (parsed == null || parsed <= 0) {
                    return 'Digite um valor valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BillStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: BillStatus.open,
                    child: Text('Em aberto'),
                  ),
                  DropdownMenuItem(
                    value: BillStatus.paid,
                    child: Text('Paga'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _status = value);
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Conta recorrente'),
                value: _recurring,
                onChanged: (value) => setState(() => _recurring = value),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vencimento: ${dateFormat.format(_selectedDate)}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showDatePicker,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Selecionar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
