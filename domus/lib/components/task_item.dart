import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:domus/components/multi_dismissible.dart';
import 'package:domus/models/task.dart';
import 'package:domus/models/task_list.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  const TaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor =
        task.complete
            ? (isDark ? const Color(0xFF1E5A4C) : const Color(0xFFDDF4EC))
            : task.time.isBefore(DateTime.now())
            ? (isDark ? const Color(0xFF633033) : const Color(0xFFFFE3E2))
            : Theme.of(context).colorScheme.tertiary;

    return MultiDismissible(
      object: task,
      card: Card(
        elevation: isDark ? 0 : 3,
        shadowColor: isDark ? Colors.transparent : null,
        surfaceTintColor: Colors.transparent,
        color: cardColor,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            title: Text(
              task.title,
              style: TextStyle(fontSize: 20, color: textColor),
            ),
            showTrailingIcon: task.description != '',
            enabled: task.description != '',
            leading: GestureDetector(
              onTap: () {
                task.completeTask();
                Provider.of<TaskList>(
                  context,
                  listen: false,
                ).updateTaskComplete(task.id, task.complete);
              },
              child: Icon(
                task.complete
                    ? Icons.check_circle_outline_outlined
                    : Icons.circle_outlined,
                color: textColor,
              ),
            ),
            subtitle: Text(
              DateFormat('dd/MM HH:mm').format(task.time),
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 15),
            collapsedIconColor: textColor,
            iconColor: textColor,
            backgroundColor: Colors.transparent,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                child: Text(
                  task.description,
                  style: TextStyle(fontSize: 18, color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
