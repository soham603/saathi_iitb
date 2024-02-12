import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditNoteScreen extends StatefulWidget {
  final Map<String, dynamic>? noteData;

  const EditNoteScreen({Key? key, required this.noteData}) : super(key: key);

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late List<TextEditingController> checklistItemControllers;
  late List<bool> checklistValues;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.noteData?['title'] ?? '');
    descriptionController = TextEditingController(text: widget.noteData?['description'] ?? '');
    checklistItemControllers = [];
    checklistValues = List<bool>.from(widget.noteData?['checklistValues'] ?? []);
    widget.noteData?['checklistItems']?.forEach((item) {
      checklistItemControllers.add(TextEditingController(text: item));
    });
  }

  void updateNote() async {
    final title = titleController.text;
    final description = descriptionController.text;
    final checklistItems = checklistItemControllers
        .map((controller) => controller.text.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    try {
      // Check if the note exists in shared_notes collection
      QuerySnapshot sharedNoteSnapshot = await FirebaseFirestore.instance
          .collection('shared_notes')
          .where('id', isEqualTo: widget.noteData?['id'])
          .get();

      if (sharedNoteSnapshot.docs.isNotEmpty) {
        // Update the note in shared_notes collection
        await FirebaseFirestore.instance
            .collection('shared_notes')
            .doc(sharedNoteSnapshot.docs.first.id)
            .update({
          'title': title,
          'description': description,
          'checklistItems': checklistItems,
          'checklistValues': checklistValues,
        });
      } else {
        // Update the note in the current user's collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('notes')
            .doc(widget.noteData?['id'])
            .update({
          'title': title,
          'description': description,
          'checklistItems': checklistItems,
          'checklistValues': checklistValues,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note updated successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update note: $e'),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        actions: [
          IconButton(
            onPressed: updateNote,
            icon: const Icon(Icons.done),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Checklists'),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: checklistItemControllers.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Checkbox(
                        value: checklistValues[index],
                        onChanged: (newValue) {
                          setState(() {
                            checklistValues[index] = newValue!;
                          });
                        },
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: checklistItemControllers[index],
                          decoration: const InputDecoration(
                            hintText: 'Enter checklist item',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            checklistItemControllers.removeAt(index);
                            checklistValues.removeAt(index);
                          });
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  );
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    checklistItemControllers.add(TextEditingController());
                    checklistValues.add(false);
                  });
                },
                child: const Text('Add Checklist Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
