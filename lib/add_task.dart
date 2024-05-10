import 'package:flutter/material.dart';
import 'task.dart';

class AddTaskScreen extends StatefulWidget {
  final Function(Task)? onAddTask;
  final Function(Task, String, Priority, DateTime?)? onEditTask;
  final Task? task;

  const AddTaskScreen({super.key, this.onAddTask, this.onEditTask, this.task});

  @override
  AddTaskScreenState createState() => AddTaskScreenState();
}

class AddTaskScreenState extends State<AddTaskScreen> {
  late TextEditingController _titleController;
  late Priority _priority;
  late DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _priority = widget.task?.priority ?? Priority.medium;
    _deadline = widget.task?.deadline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Добавить новую задачу' : 'Изменить задачу'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12.0),
            const Text('Приоритет:'),
            DropdownButton<Priority>(
              value: _priority,
              onChanged: (value) {
                setState(() {
                  _priority = value!;
                });
              },
              items: Priority.values
                  .map((priority) => DropdownMenuItem<Priority>(
                value: priority,
                child: Text(_formatPriority(priority)),
              ))
                  .toList(),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                const Text('Дедлайн:'),
                const SizedBox(width: 12.0),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _selectDeadline(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Text(
                        _deadline != null
                            ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                            : 'Выбрать дату',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            widget.onAddTask != null ?
            ElevatedButton(
              onPressed: () {
                final String title = _titleController.text;
                final Task newTask = Task(title: title, priority: _priority, deadline: _deadline);
                widget.onAddTask!(newTask);
                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ) 
            :ElevatedButton(
              onPressed: () {
                final String title = _titleController.text;
                widget.onEditTask!(widget.task!, title, _priority, _deadline);
                Navigator.pop(context);
              },
              child: const Text('Изменить'),
            ),            
          ],
        ),
      ),
    );
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  String _formatPriority(Priority priority) {
    switch (priority) {
      case Priority.high:
        return 'Высокий';
      case Priority.medium:
        return 'Средний';
      case Priority.low:
        return 'Низкий';
      default:
        return '';
    }
  }

}