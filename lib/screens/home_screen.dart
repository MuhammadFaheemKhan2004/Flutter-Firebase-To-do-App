import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser!;
  final todosRef = FirebaseFirestore.instance.collection('todos');
  File? _pickedImage;

  Future<void> _addTodo() async {
    if (_controller.text.trim().isEmpty) return;

    try {
      String? imageUrl;

      if (_pickedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance
            .ref('user_uploads/${user.uid}/$fileName');

        final uploadTask = await storageRef.putFile(_pickedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await todosRef.add({
        'text': _controller.text.trim(),
        'uid': user.uid,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _controller.clear();
      setState(() => _pickedImage = null);
    } catch (e) {
      print("❌ Error adding todo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add task")),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _deleteTodo(String id) async {
    await todosRef.doc(id).delete();
  }

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My To-Do List"),
        actions: [
          IconButton(onPressed: _signOut, icon: Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Enter task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: Text("Add"),
                ),
              ],
            ),
          ),
          if (_pickedImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Image.file(_pickedImage!, height: 100),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: todosRef
                  .where('uid', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return Center(child: Text("No tasks."));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: data['imageUrl'] != null
                          ? Image.network(data['imageUrl'], width: 40)
                          : null,
                      title: Text(data['text'] ?? ''),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteTodo(doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
