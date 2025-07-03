import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'taskService.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // If null => new task, else edit

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetGoalsController;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _targetGoalsController = TextEditingController(
      text: widget.task?.targetGoals.toString() ?? '',
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final taskService = Provider.of<TaskService>(context, listen: false);
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    final targetGoalsText = _targetGoalsController.text.trim();
    int? targetGoals;
    if (targetGoalsText.isNotEmpty) {
      targetGoals = int.tryParse(targetGoalsText);
      if (targetGoals == null || targetGoals <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Target goals must be a positive number')),
        );
        setState(() => _loading = false);
        return;
      }
    }

    try {
      if (widget.task == null) {
        await taskService.createTask(title, desc, targetGoals: targetGoals);
      } else {
        await taskService.updateTask(widget.task!.id, title, desc,
            targetGoals: targetGoals);
      }

      Navigator.pop(context); // Go back
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetGoalsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Goals',
                        hintText: 'e.g. 3 = 12 Pomodoro sessions',
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(isEditing ? Icons.save : Icons.add),
                      label: Text(isEditing ? 'Update Task' : 'Create Task'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
