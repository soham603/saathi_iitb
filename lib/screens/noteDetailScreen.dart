import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:saathi_iitb/screens/editNote.dart';

class NoteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? noteData;

  const NoteDetailsScreen({Key? key, required this.noteData}) : super(key: key);

  @override
  State<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {
  final TextEditingController shareController = TextEditingController();
  late List<bool> checklistValues;

  @override
  void initState() {
    super.initState();
    // Initialize checklistValues with the values from the noteData
    checklistValues = List<bool>.from(widget.noteData?['checklistValues'] ?? []);
  }

  void _shareNote() async {
    String email = shareController.text.trim();
    if (email.isNotEmpty) {
      try {
        // Get a reference to the current user's note document
        DocumentReference currentUserNoteRef = FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('notes')
            .doc(widget.noteData?['id']);

        // Fetch the current user's note data
        DocumentSnapshot currentUserNoteSnapshot = await currentUserNoteRef.get();

        // Check if the note exists
        if (currentUserNoteSnapshot.exists) {
          // Get the note data
          Map<String, dynamic>? noteData = currentUserNoteSnapshot.data() as Map<String, dynamic>?;

          // Add owner's email to the note data
          noteData!['owner'] = FirebaseAuth.instance.currentUser!.email;

          // Add the email of the shared user
          noteData['shared'] = [FirebaseAuth.instance.currentUser!.email,email];

          // Store the shared note details in the 'shared_notes' collection
          await FirebaseFirestore.instance.collection('shared_notes').add(noteData);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note shared successfully')),
          );
          shareController.clear();
        } else {
          // Show error message if note does not exist
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note does not exist')),
          );
        }
      } catch (e) {
        // Show error message if an error occurs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share note: $e')),
        );
      }
    } else {
      // Show error message if email is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email')),
      );
    }
  }


  void _editNote() {
    // Navigate to the AddTask screen with the existing note data for editing
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(
          noteData: widget.noteData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteData?['title'] ?? 'Untitled'),
        actions: [
          IconButton(
            onPressed: _editNote,
            icon: Icon(Icons.edit),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(widget.noteData?['description'] ?? 'No description available'),
              const SizedBox(height: 16),
              const Text(
                'Checklist:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Display checklist items with corresponding checkbox values
              ListView.builder(
                shrinkWrap: true,
                itemCount: widget.noteData?['checklistItems'].length ?? 0,
                itemBuilder: (context, index) {
                  return IgnorePointer(
                    ignoring: true, // Prevent user interaction with the Checkbox
                    child: CheckboxListTile(
                      value: checklistValues[index],
                      onChanged: null, // Set onChanged to null to disable checkbox changes
                      title: Text(widget.noteData?['checklistItems'][index] ?? ''),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Share Note :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              SizedBox(height: 10,),
              TextFormField(
                controller: shareController,
                decoration: const InputDecoration(
                  hintText: 'Enter Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10,),
              Center(
                child: ElevatedButton(
                  onPressed: _shareNote,
                  child: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
