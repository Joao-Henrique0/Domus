import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:domus/components/notification.dart';
import 'package:domus/utils/db_util.dart';
import 'task.dart';

class TaskList with ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks {
    // Ordena as tarefas por tempo antes de retornar
    _tasks.sort((a, b) => a.time.compareTo(b.time));
    return [..._tasks];
  }

  int get itensCount {
    return _tasks.length;
  }

  Future<void> refreshTasks() async {
    await loadTasks();
    notifyListeners();
  }

  Future<void> loadTasks() async {
    final dataList = await DbUtil.getData();
    _tasks =
        dataList
            .map(
              (item) => Task(
                id: item['id'],
                title: item['title'],
                description: item['description'],
                time: DateTime.parse(item['time']),
                complete: item['complete'] == 1 ? true : false,
              ),
            )
            .toList();
    notifyListeners();
  }

  Task itemByIndex(int index) {
    return _tasks[index];
  }

  Future<void> saveTask(Map<String, Object> data) async {
    bool hasId = data['id'] != null && (data['id'] as String).isNotEmpty;
    final currentIndex =
        hasId ? _tasks.indexWhere((task) => task.id == data['id']) : -1;
    final task = Task(
      id: hasId ? data['id'] as String : "",
      title: data['title'] as String,
      description: data['description'] as String,
      time: data['time'] as DateTime,
      complete: currentIndex >= 0 ? _tasks[currentIndex].complete : false,
    );

    if (hasId) {
      await updateTask(task);
    } else {
      await addTask(task);
    }
  }

  Future<void> addTask(Task task) async {
    final responseBody = await DbUtil.insertData({
      'title': task.title,
      'description': task.description,
      'time': task.time.toIso8601String(),
    });

    final String newId = responseBody.toString();
    debugPrint("New task ID: $newId");

    final newTask = Task(
      id: newId,
      title: task.title,
      description: task.description,
      time: task.time,
      complete: false,
    );

    _tasks.add(newTask);
    notifyListeners();

    // Agenda a notificação com o id correto
    debugPrint("tasktime: ${newTask.time}");
    await LocalNotificationService.showScheduledRepeatingNotification(
      title: newTask.title,
      description: newTask.description,
      taskTime: newTask.time,
      taskId: newTask.id,
    );
  }

  Future<void> updateTask(Task task) async {
    int index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
      notifyListeners();
      await DbUtil.updateData({
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'time': task.time.toIso8601String(),
        'complete': task.complete,
      });

      // Agenda a notificação ao atualizar também
      await LocalNotificationService.cancelTaskNotifications(task.id.hashCode);
      if (!task.complete) {
        await LocalNotificationService.showScheduledRepeatingNotification(
          title: task.title,
          description: task.description,
          taskTime: task.time,
          taskId: task.id,
        );
      }
    }
  }

  Future<void> removeTask(Task task) async {
    int index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks.removeAt(index);
      notifyListeners();
      await DbUtil.deleteData(task.id);
      // Remove a notificação atrelada à tarefa
      await LocalNotificationService.cancelTaskNotifications(task.id.hashCode);
    }
  }

  Future<void> updateTaskComplete(String taskId, bool complete) async {
    // Atualiza a tarefa na lista em memória
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex >= 0) {
      _tasks[taskIndex].complete = complete;
      notifyListeners();
      if (complete) {
        await LocalNotificationService.cancelTaskNotifications(taskId.hashCode);
      } else {
        final task = _tasks[taskIndex];
        await LocalNotificationService.showScheduledRepeatingNotification(
          title: task.title,
          description: task.description,
          taskTime: task.time,
          taskId: task.id,
        );
      }
    }
    // Atualiza o status de conclusão da tarefa no banco de dados
    await DbUtil.updateComplete(taskId, complete);
  }

  Future<void> rescheduleOpenTaskNotifications() async {
    if (_tasks.isEmpty) {
      await loadTasks();
    }

    for (final task in _tasks) {
      await LocalNotificationService.cancelTaskNotifications(task.id.hashCode);
      if (task.complete) continue;
      await LocalNotificationService.showScheduledRepeatingNotification(
        title: task.title,
        description: task.description,
        taskTime: task.time,
        taskId: task.id,
      );
    }
  }

  Future<void> backupTasksToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final tasksData =
        _tasks
            .map(
              (task) => {
                'id': task.id,
                'user_id': user.id,
                'title': task.title,
                'description': task.description,
                'time': task.time.toIso8601String(),
                'complete': task.complete,
              },
            )
            .toList();

    // Remove backups antigos do usuário (opcional)
    await Supabase.instance.client
        .from('tasks')
        .delete()
        .eq('user_id', user.id);

    // Insere todas as tarefas como backup
    try {
      await Supabase.instance.client.from('tasks').insert(tasksData);
    } catch (e) {
      debugPrint('Erro ao salvar backup: $e');
    }

    // Você pode tratar o response para mostrar sucesso/erro
  }

  Future<void> restoreTasksFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('tasks')
          .select()
          .eq('user_id', user.id);

      // Limpa o banco local antes de restaurar
      final dataList = await DbUtil.getData();
      for (final item in dataList) {
        await DbUtil.deleteData(item['id']);
      }

      // Salva cada tarefa restaurada no SQLite local
      for (final item in response) {
        try {
          await DbUtil.insertData({
            'id': item['id'].toString(),
            'title': item['title'],
            'description': item['description'],
            'time': item['time'], // garanta que está em ISO string
            'complete': item['complete'] == true || item['complete'] == 1,
          });
        } catch (e) {
          debugPrint('Erro ao inserir tarefa local: $e');
        }
      }

      // Recarrega do banco local para garantir sincronismo
      await loadTasks();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao restaurar backup: $e');
    }
  }
}
