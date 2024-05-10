enum Priority { low, medium, high }

class Task {
  int? id;
  String title;
  Priority priority;
  DateTime? deadline;
  DateTime? finishdate;

  Task({required this.title, required this.priority, this.deadline, this.id, this.finishdate});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'priority': priority.index,
      'deadline': deadline?.millisecondsSinceEpoch,
      'finishdate': finishdate?.millisecondsSinceEpoch
    };
  }
}