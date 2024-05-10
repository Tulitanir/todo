import 'package:flutter/material.dart';
import 'package:todo/databse_service.dart';
import 'task.dart';
import 'add_task.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  TaskListScreenState createState() => TaskListScreenState();
}

class TaskListScreenState extends State<TaskListScreen> {
  List<Task>? _tasks = null;
  int value = 0;

  @override
  void initState() {
    super.initState();

    _getTasks().then((list) => setState(() {
       _tasks = list;
       _sortTasks(value);
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks == null) {
      return const CircularProgressIndicator();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        actions: [
          DropdownButton(
            value: value,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Приотритет')),
              DropdownMenuItem(value: 1, child: Text('Дедлайн')),
              DropdownMenuItem(value: 2, child: Text('Завершённые')),
            ],
            onChanged: (int? newValue) async {
              _tasks = await _getTasks();
              setState(() {
                value = newValue!;
                _sortTasks(newValue);
              });
            }),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _navigateToAddTaskScreen(context);
            },
          ),
        ],
      ),
      body: _tasks!.isEmpty
          ? const Center(
        child: Text(
          'Нет задач',
          style: TextStyle(fontSize: 20.0),
        ),
      )
          : ListView.builder(
        itemCount: _tasks!.length,
        itemBuilder: (context, index) {
          return _buildTaskCard(_tasks![index]);
        },
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 4.0,
      child: ListTile(
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Приоритет: ${_formatPriority(task.priority)}'),
            task.finishdate == null ? 
                Text('Дедлайн: ${_formatDate(task.deadline)}') 
                : Text('Дата выполнения: ${_formatDate(task.finishdate)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            task.finishdate == null ? 
            IconButton(
              icon: const Icon(Icons.done),
              onPressed: () async {
                await _completeTask(task);
              },
            ) : const SizedBox(width: 0, height: 0),
            task.finishdate == null ? 
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _editTaskScreen(context, task);
              },
            ) : const SizedBox(width: 0, height: 0),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await _deleteTask(task);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date != null) {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } else {
      return 'Нет дедлайнов';
    }
  }

  String _formatPriority(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Низкий';
      case Priority.medium:
        return 'Средний';
      case Priority.high:
        return 'Высокий';
      default:
        return '';
    }
  }

  void _editTaskScreen(BuildContext context, Task task) {
    Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddTaskScreen(onEditTask: _editTask, task: task)),
    );

    setState(() {
      _sortTasks(value);
    });
  }

  void _navigateToAddTaskScreen(BuildContext context) async {
    final newTask = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTaskScreen(onAddTask: _addTask)),
    );
    if (newTask != null) {
      setState(() {
        _addTask(newTask as Task);
      });
    }
  }

  Future<void> _editTask(Task task, String title, Priority priority, DateTime? deadline) async {
    final db = await DatabaseService().database;
    task.title = title;
    task.priority = priority;
    task.deadline = deadline;
    await db.update(
      'task',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );

    setState(() {
      _sortTasks(value);
    });
  }

  Future<void> _addTask(Task task) async {
    final db = await DatabaseService().database;
    _tasks = await _getTasks();
    setState(() {
      db.insert('task', task.toMap());
      _sortTasks(value);
    });
  }

  Future<void> _completeTask(Task task) async {
    final db = await DatabaseService().database;

    task.deadline = null;
    task.finishdate = DateTime.now();
    
    await db.update(
      'task',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );

    _tasks = await _getTasks();

    setState(() {
      _sortTasks(value);
    });
  }

  Future<void> _deleteTask(Task task) async {
    final db = await DatabaseService().database;

    await db.delete(
      'task',
      where: 'id = ?',
      whereArgs: [task.id],
    );

    _tasks = await _getTasks();

    setState(() {
      _sortTasks(value);
    });
  }

  Future<List<Task>> _getTasks() async {
    final db = await DatabaseService().database;
    final List<Map<String, dynamic>> maps = await db.query('task');

    return List.generate(maps.length, (i) {
      return Task(
        id: maps[i]['id'],
        title: maps[i]['title'],
        priority: Priority.values[maps[i]['priority']],
        deadline: maps[i]['deadline'] == null ? null : DateTime.fromMillisecondsSinceEpoch(maps[i]['deadline']),
        finishdate: maps[i]['finishdate'] == null ? null : DateTime.fromMillisecondsSinceEpoch(maps[i]['finishdate'])
      );
    });
  }

  void _sortTasks(int key) {
    switch (key) {
      case 1:
        _tasks!.sort((a, b) {
          if (a.deadline != null && b.deadline != null) {
            return a.deadline!.compareTo(b.deadline!);
          } else if (a.deadline != null) {
            return -1;
          } else if (b.deadline != null) {
            return 1;
          } else {
            return 0;
          }
        });
        break;
      case 2:
        _tasks!.sort((a, b) {
          if (a.finishdate != null && b.finishdate != null) {
            return a.finishdate!.compareTo(b.finishdate!);
          } else if (a.finishdate != null) {
            return -1;
          } else if (b.finishdate != null) {
            return 1;
          } else {
            return 0;
          }
        });
        break;
      default:
        _tasks!.sort((a, b) {
          if (a.priority != b.priority) {
            return b.priority.index.compareTo(a.priority.index);
          } else {
            if (a.deadline != null && b.deadline != null) {
              return a.deadline!.compareTo(b.deadline!);
            } else if (a.deadline != null) {
              return -1;
            } else if (b.deadline != null) {
              return 1;
            } else {
              return 0;
            }
          }
        });
    }
  }

}