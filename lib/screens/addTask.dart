import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddTask extends StatefulWidget {
  const AddTask({Key? key}) : super(key: key);

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final List<TextEditingController> checklistItemControllers = [];

  late List<bool> checklistValues;

  @override
  void initState() {
    super.initState();
    // Initialize checklistValues with an empty list
    checklistValues = [];
    addChecklistItem(); // Initially add one checklist item
  }

  void addChecklistItem() {
    final TextEditingController newController = TextEditingController();
    checklistItemControllers.add(newController);
    setState(() {
      // Add a corresponding false value for the new checklist item
      checklistValues.add(false);
    });
  }

  Future<void> _submitForm() async {
    final title = titleController.text;
    final description = descriptionController.text;
    final checklistItems = checklistItemControllers
        .map((controller) => controller.text.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    try {
      var uuid = const Uuid().v4();
      DateTime now = DateTime.now();
      DateTime istTime = now.toUtc().add(const Duration(hours: 5, minutes: 30));
      DateTime time = now.toLocal();
      String formattedISTTime = DateFormat('dd-MM-yyyy').format(istTime);

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notes')
          .doc(uuid)
          .set({
        'id': uuid,
        'time': time,
        'title': title,
        'description': description,
        'checklistItems': checklistItems,
        'checklistValues': checklistValues,
        'date': formattedISTTime.toString(),
      });
      setState(() {
        titleController.clear();
        descriptionController.clear();
        checklistItemControllers.forEach((controller) => controller.clear());
        setState(() {
          // Clear the checklist values
          checklistValues.clear();
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note added successfully'),
        ),
      );
      // Clear the form after successful submission
    } catch (e) {
      print('Error adding note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add note. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
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
              Text('Add Checklists : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
              SizedBox(height: 10,),

              Padding(
                padding: const EdgeInsets.only(left: 1),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: checklistItemControllers.length,
                  itemBuilder: (context, index) {
                    bool initialValue = index < checklistValues.length ? checklistValues[index] : false;
                    return Row(
                      children: [
                        Checkbox(
                          value: initialValue,
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
              ),
              SizedBox(height: 10,),

              ElevatedButton(
                onPressed: addChecklistItem,
                child: const Text('Add Checklist Item'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
