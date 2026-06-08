import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:domus/models/expense_type_list.dart';

class ExpenseTypesPage extends StatefulWidget {
  const ExpenseTypesPage({super.key});

  @override
  State<ExpenseTypesPage> createState() => _ExpenseTypesPageState();
}

class _ExpenseTypesPageState extends State<ExpenseTypesPage> {
  final _controller = TextEditingController();
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addType() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    await Provider.of<ExpenseTypeList>(
      context,
      listen: false,
    ).addType(name);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tipos de despesa')),
      body: FutureBuilder(
        future: _loadTypesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          labelText: 'Novo tipo',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addType(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addType,
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Consumer<ExpenseTypeList>(
                    builder: (context, typeList, _) {
                      if (typeList.types.isEmpty) {
                        return const Center(
                          child: Text('Nenhum tipo cadastrado'),
                        );
                      }

                      return ListView.separated(
                        itemCount: typeList.types.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final type = typeList.types[index];
                          return ListTile(
                            title: Text(
                              type.name,
                              style: const TextStyle(fontSize: 18),
                            ),
                            trailing: TextButton(
                              onPressed: () => typeList.removeType(type),
                              child: const Text('Remover'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
