import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:domus/models/expense_type_list.dart';
import 'package:domus/models/transaction.dart';
import 'package:domus/models/transaction_list.dart';

class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  static const _otherCategory = 'Outros';

  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _otherController = TextEditingController();
  final _formData = <String, Object>{};

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = _otherCategory;
  late Future<void> _loadTypesFuture;

  @override
  void initState() {
    super.initState();
    _loadTypesFuture = Provider.of<ExpenseTypeList>(
      context,
      listen: false,
    ).loadTypes();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _showDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2019),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null || !mounted) return;
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final category =
        _selectedCategory == _otherCategory
            ? _otherController.text.trim()
            : _selectedCategory;
    final title = category.isEmpty ? _otherCategory : category;

    _formData['title'] = title;
    _formData['category'] =
        _selectedCategory == _otherCategory ? _otherCategory : category;
    _formData['value'] = double.parse(_valueController.text.replaceAll(',', '.'));
    _formData['date'] = _selectedDate;

    try {
      final transactionList = Provider.of<TransactionList>(
        context,
        listen: false,
      );
      await transactionList.saveTransaction(_formData);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Ocorreu um erro!'),
              content: const Text('Ocorreu um erro ao salvar a despesa'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Ok'),
                ),
              ],
            ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_formData.isNotEmpty) return;

    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg == null) return;

    final transaction = arg as Transaction;
    _formData['id'] = transaction.id;
    _selectedCategory = transaction.category;
    _valueController.text = transaction.value.toString();
    _selectedDate = transaction.date;

    if (transaction.category == _otherCategory) {
      _otherController.text = transaction.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesa'),
        actions: [
          IconButton(onPressed: _submitForm, icon: const Icon(Icons.save)),
        ],
      ),
      body: FutureBuilder(
        future: _loadTypesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Consumer<ExpenseTypeList>(
            builder: (context, typeList, _) {
              final categories = <String>{
                ...typeList.types.map((type) => type.name),
                _otherCategory,
              }.toList();
              if (!categories.contains(_selectedCategory)) {
                _selectedCategory = _otherCategory;
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
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
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) {
                              final isValid = RegExp(
                                r'^\d*([,.]\d{0,2})?$',
                              ).hasMatch(newValue.text);
                              return isValid ? newValue : oldValue;
                            },
                          ),
                        ],
                        validator: (value) {
                          final normalized = (value ?? '').replaceAll(
                            ',',
                            '.',
                          );
                          if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(
                            normalized,
                          )) {
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
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de despesa',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedCategory = value);
                        },
                      ),
                      if (_selectedCategory == _otherCategory) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _otherController,
                          decoration: const InputDecoration(
                            labelText: 'Descricao',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_selectedCategory != _otherCategory) {
                              return null;
                            }
                            if ((value ?? '').trim().length < 3) {
                              return 'Descreva a despesa';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Data: ${DateFormat('dd/MM/y').format(_selectedDate)}',
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
              );
            },
          );
        },
      ),
    );
  }
}
