import 'package:app_links/app_links.dart';
import 'package:domus/models/bill_list.dart';
import 'package:domus/models/expense_type_list.dart';
import 'package:domus/models/transaction_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:domus/components/chat_provider.dart';
import 'package:domus/components/notification.dart';
import 'package:domus/components/transaction_form.dart';
import 'package:domus/models/task_list.dart';
import 'package:domus/pages/bill_form.dart';
import 'package:domus/pages/bill_notification_settings.dart';
import 'package:domus/pages/chatbot_page.dart';
import 'package:domus/pages/expense_types_page.dart';
import 'package:domus/pages/login_page.dart';
import 'package:domus/pages/notification_settings.dart';
import 'package:domus/pages/register_page.dart';
import 'package:domus/pages/tabs_page.dart';
import 'package:domus/pages/task_form.dart';
import 'package:domus/theme/theme_provider.dart';
import 'package:domus/utils/app_routes.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');
  await dotenv.load();
  await LocalNotificationService.init();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  tz.initializeTimeZones();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late TaskList _taskList;
  late TransactionList _transactionList;
  late BillList _billList;
  late ExpenseTypeList _expenseTypeList;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _taskList = TaskList();
    _transactionList = TransactionList();
    _billList = BillList(_transactionList);
    _expenseTypeList = ExpenseTypeList();
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() {
    _appLinks = AppLinks();
    _sub = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null &&
            uri.scheme == 'myapp' &&
            uri.host == 'abrir_funcionalidade') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const TaskForm()));
        }
      },
      onError: (err) {
        // tratar erros
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (!mounted) return;
      await _taskList.backupTasksToSupabase();
      debugPrint("Backup automático realizado ao sair do app.");
    }
  }

  @override
  Widget build(BuildContext context) {
    LocalNotificationService.registerOnTaskComplete(
      _taskList.updateTaskComplete,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskList>.value(value: _taskList),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
        ChangeNotifierProvider<TransactionList>.value(value: _transactionList),
        ChangeNotifierProvider<BillList>.value(value: _billList),
        ChangeNotifierProvider<ExpenseTypeList>.value(value: _expenseTypeList),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Tasks',
            theme: themeProvider.themeData,
            routes: {
              AppRoutes.home: (ctx) => const TabsScreen(),
              AppRoutes.taskForm: (ctx) => const TaskForm(),
              AppRoutes.transactionForm: (ctx) => const TransactionForm(),
              AppRoutes.billForm: (ctx) => const BillForm(),
              AppRoutes.billNotiSettings:
                  (ctx) => const BillNotificationSettings(),
              AppRoutes.expenseTypes: (ctx) => const ExpenseTypesPage(),
              AppRoutes.chatBot: (ctx) => const ChatbotScreen(),
              AppRoutes.login: (ctx) => const LoginPage(),
              AppRoutes.register: (ctx) => const RegisterPage(),
              AppRoutes.notiSettings: (ctx) => const NotificationSettings(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/abrir_funcionalidade') {
                return MaterialPageRoute(builder: (_) => const TaskForm());
              }
              return null;
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
