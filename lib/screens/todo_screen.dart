import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser!;
  final todosRef = FirebaseFirestore.instance.collection('todos');
  bool isAdding = false;
  List<Map<String, dynamic>> cachedTodos = [];

  @override
  void initState() {
    super.initState();
    _loadCachedTodos();
  }

  Future<void> _loadCachedTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cachedTodos_${user.uid}');
    if (jsonString != null) {
      setState(() {
        cachedTodos = List<Map<String, dynamic>>.from(json.decode(jsonString));
      });
    }
  }

  Future<void> _cacheTodos(List<Map<String, dynamic>> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedTodos_${user.uid}', json.encode(todos));
  }

  Future<void> _addTodo() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => isAdding = true);

    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      String? imageUrl;

      if (pickedImage != null) {
        File file = File(pickedImage.path);
        if (!file.existsSync()) throw Exception("Image file does not exist.");

        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child('todo_images/\$fileName');

        await ref.putFile(file);
        imageUrl = await ref.getDownloadURL();
      }

      final todo = {
        'text': _controller.text.trim(),
        'uid': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      };

      await todosRef.add(todo);

      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add task")));
    } finally {
      setState(() => isAdding = false);
    }
  }

  Future<void> _deleteTodo(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Task"),
        content: Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await todosRef.doc(id).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete task")));
    }
  }

  Future<void> _signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      Navigator.pop(context);
    } catch (e) {
      print("Sign out error: \$e");
    }
  }

  Widget _animatedTodoCard(Map<String, dynamic> data, String docId) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
       leading: data['imageUrl'] != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          data['imageUrl'],
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 50,
          ),
        ),
      )
    : Icon(Icons.image_not_supported, color: Colors.grey),

        title: Text(
          data['text'] ?? '[No text]',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _deleteTodo(docId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F5F7),
      appBar: AppBar(
        title: Text('To-Do List'),
        backgroundColor: Colors.deepPurpleAccent,
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
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isAdding ? null : _addTodo,
                  child: isAdding
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text("Add"),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: todosRef
                  .where('uid', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading tasks"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final todos = docs.map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id
                }).toList();
                _cacheTodos(todos);

                if (todos.isEmpty && cachedTodos.isNotEmpty) {
                  return ListView(
                    children: cachedTodos.map((todo) {
                      return _animatedTodoCard(todo, todo['id'] ?? '');
                    }).toList(),
                  );
                }

                if (todos.isEmpty) return Center(child: Text("No tasks yet."));

                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (_, index) {
                    final todo = todos[index];
                    return AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: _animatedTodoCard(todo, todo['id']),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
