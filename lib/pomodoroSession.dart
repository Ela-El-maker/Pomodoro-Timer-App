class PomodoroSession {
  final int? id; 
  final int taskId;
  final String mode;
  final int duration;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool wasCompleted;

  PomodoroSession({
    this.id, 
    required this.taskId,
    required this.mode,
    required this.duration,
    required this.startedAt,
    required this.completedAt,
    required this.wasCompleted,
  });

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'],
      taskId: json['task_id'],
      mode: json['mode'],
      duration: json['duration'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      wasCompleted: json['was_completed'] == true || json['was_completed'] == 1,
    );
  }
}

