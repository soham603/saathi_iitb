import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saathi_iitb/screens/addTask.dart';
import 'package:saathi_iitb/screens/noteDetailScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _userNotesStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _sharedNotesStream;

  @override
  void initState() {
    super.initState();
    _userNotesStream = _fetchUserNotes();
    _sharedNotesStream = _fetchSharedNotes();
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchUserNotes() {
    // Query user's notes
    var userNotesQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('notes')
        .snapshots();

    return userNotesQuery;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchSharedNotes() {
    // Query shared_notes where the owner is the current user's email
    var sharedNotesQueryByOwner = FirebaseFirestore.instance
        .collection('shared_notes')
        .where('owner', isEqualTo: currentUser!.email)
        .snapshots();

    // Query shared_notes where the current user's email is in the shared field
    var sharedNotesQueryByShared = FirebaseFirestore.instance
        .collection('shared_notes')
        .where('shared', arrayContains: currentUser!.email)
        .snapshots();

    // Merge both queries
    return StreamGroup.merge([sharedNotesQueryByOwner, sharedNotesQueryByShared]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white, size: 28), // Set the color of the drawer icon to white
        title: const Text('Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),),
        backgroundColor: const Color.fromRGBO(2,62,138,1),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTask()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white, size: 40),
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width / 1.5,
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 4,
              child: Icon(Icons.account_box, size: 75,),
            ),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: getUserDetails(),
              builder: (context, snapshot) {
                // loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                // error
                else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                // data received
                else if (snapshot.hasData) {
                  // extract data
                  Map<String, dynamic>? user = snapshot.data!.data();
                  if (user == null) {
                    return const Text("Error: User data is null");
                  }
                  return Column(
                    children: [
                      const Text('Username :',style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500),),
                      const SizedBox(height: 5,),
                      Text(
                        user['email'] ?? "No Email",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                } else {
                  return const Text("Unknown error occurred");
                }
              },
            ),
            const SizedBox(height: 50,),
            const Text('LogOut :',style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w500),),
            const SizedBox(height: 5,),
            SizedBox(
              width: 100,
              child: Material(

                  color: Colors.blue,
                  child: Column(
                    children: [
                      IconButton(onPressed: signOut, icon: const Icon(Icons.logout)),
                    ],
                  )
              ),
            ),
            const SizedBox(height: 15,),

          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  'Shared Note\'s',
                  style: GoogleFonts.poppins(
                      fontSize: 28,
                    fontWeight: FontWeight.bold
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height / 24,
                   width: MediaQuery.of(context).size.width / 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey
                      ),
                    ),
                    child: IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.red,))),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _sharedNotesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Text('Error fetching shared notes');
                }

                List<QueryDocumentSnapshot<Map<String, dynamic>>> sharedNotes =
                    snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sharedNotes.length,
                    itemBuilder: (context, index) {
                      final note = sharedNotes[index].data();
                      return NoteCard1(note: note);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  'Users Note\'s',
                  style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold
                  ),
                ),
                Container(
                    height: MediaQuery.of(context).size.height / 24,
                    width: MediaQuery.of(context).size.width / 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.grey
                      ),
                    ),
                    child: IconButton(onPressed: () {}, icon: Icon(Icons.arrow_downward, size: 20,weight: 20, color: Colors.red,))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _userNotesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Text('Error fetching user notes');
                }

                List<QueryDocumentSnapshot<Map<String, dynamic>>> userNotes =
                    snapshot.data!.docs;

                return ListView.builder(
                  itemCount: userNotes.length,
                  itemBuilder: (context, index) {
                    final note = userNotes[index].data();
                    return NoteCard(note: note);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    try {
      return await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser!.uid)
          .get();
    } catch (e) {
      // Handle errors more gracefully
      print("Error fetching user details: $e");
      rethrow;
    }
  }
}

class NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;

  const NoteCard({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        NoteDetailsScreen(noteData: note)));
          },
          child: Container(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
              ),
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            height: MediaQuery.of(context).size.height / 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                  child: Container(
                    height: MediaQuery.of(context).size.height / 9,
                    width: MediaQuery.of(context).size.width / 5,
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: const Center(child: Icon(Icons.list_alt, size: 50, color: Colors.white)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note['title'],
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18
                          ),
                        ),
                        Expanded(
                          child: Text(
                            (note['description'].length > 20)
                                ? '${note['description'].substring(0, 20)}...'
                                : note['description'],
                          ),
                        ),
                        Text(note['date'].toString()),
                        const Text(
                          'Click to see more ...',
                          style: TextStyle(
                              color: Colors.blue,
                              decorationStyle: TextDecorationStyle.solid
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetailsScreen(noteData: note),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoteCard1 extends StatelessWidget {
  final Map<String, dynamic> note;

  const NoteCard1({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    NoteDetailsScreen(noteData: note)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          //color: Color.fromRGBO(2,62,138,1),
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8), // Adjust horizontal spacing
        height: MediaQuery.of(context).size.height / 4,
        width: MediaQuery.of(context).size.width / 1.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Text(
                    note['title'],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 7, right: 5),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color.fromRGBO(2, 62, 138, 1),
                        radius: 20,
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.info, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 3),
                      CircleAvatar(
                        backgroundColor: Color.fromRGBO(2, 62, 138, 1),
                        radius: 20,
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.share, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 70),
              child: Expanded(
                child: Text(
                  note['description'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromRGBO(254, 240, 224, 0.9),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle),
                      const SizedBox(width: 5),
                      Text(
                        note['owner'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Created On: ' + note['date'],
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

