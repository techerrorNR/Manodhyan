import 'package:flutter/material.dart';

Future<void> showCreateTaskModal(BuildContext context) async {
  await showModalBottomSheet(
    backgroundColor: const Color(0xFF1B192F),
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Create New Task", style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Task title",
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save logic here
                Navigator.of(ctx).pop();
              },
              child: const Text("Save"),
            )
          ],
        ),
      );
    },
  );
}
