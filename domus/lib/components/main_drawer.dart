import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:domus/models/task_list.dart';
import 'package:domus/theme/theme.dart';
import 'package:domus/theme/theme_provider.dart';
import 'package:domus/utils/app_routes.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Drawer(
      child: Column(
        children: [
          AppBar(title: const Text('Opcoes'), automaticallyImplyLeading: false),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Modo Escuro'),
            trailing: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Switch(
                  value: themeProvider.themeData == darkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Configuracoes de notificacao'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.notiSettings),
          ),
          ListTile(
            leading: const Icon(Icons.notification_important),
            title: const Text('Notificacoes de contas'),
            onTap:
                () => Navigator.pushNamed(context, AppRoutes.billNotiSettings),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Tipos de despesa'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.expenseTypes),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Restaurar backup'),
            onTap: () async {
              final taskList = Provider.of<TaskList>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

              Navigator.of(context).pop();
              await taskList.restoreTasksFromSupabase();

              scaffoldMessenger?.showSnackBar(
                const SnackBar(content: Text('Backup restaurado!')),
              );
            },
          ),
          ListTile(
            leading: Icon(user != null ? Icons.cloud_done : Icons.login),
            title: Text(
              user != null
                  ? 'Backup ativo e ChatBot conectado'
                  : 'Login para Backup e ChatBot',
            ),
            onTap: () async {
              if (user == null) {
                Navigator.of(context).pushNamed(AppRoutes.login);
                return;
              }

              await showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Ja esta logado'),
                      content: const Text('Deseja sair da conta?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            Navigator.of(ctx).pop();
                            await Supabase.instance.client.auth.signOut(
                              scope: SignOutScope.global,
                            );
                            await GoogleSignIn().signOut();
                            navigator.pushReplacementNamed(AppRoutes.home);
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
