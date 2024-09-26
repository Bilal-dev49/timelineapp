import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:timelineapp/screens/home_screen.dart';

class AddTimelineScreen extends StatefulWidget {
  @override
  _AddTimelineScreenState createState() => _AddTimelineScreenState();
}

class _AddTimelineScreenState extends State<AddTimelineScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController timelineController = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  bool isLoading = false;

  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    } else {
      // If no image is picked
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
    }
  }

  Future<String> uploadImage(File image) async {
    Reference ref = _storage
        .ref()
        .child("timeline_images")
        .child(DateTime.now().toString());
    UploadTask uploadTask = ref.putFile(image);
    var imageUrl = await (await uploadTask).ref.getDownloadURL();
    return imageUrl;
  }

  void addTimeline() async {
    if (timelineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Timeline content cannot be empty')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check if user is logged in
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("No user is logged in.");
      }

      // Upload image if available, otherwise use an empty string
      String imageUrl = _image != null ? await uploadImage(_image!) : '';

      // Add timeline entry to Firestore
      await _firestore.collection("timelines").add({
        'uid': user.uid,
        'timelineContent': timelineController.text,
        'imageUrl': imageUrl,
        'timestamp': Timestamp.now(),
      });

      // Check if the widget is still mounted before popping
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);

      // Show error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Timeline')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: timelineController,
                decoration: InputDecoration(
                  labelText: 'What\'s on your mind?',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              _image != null
                  ? Image.file(_image!)
                  : ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: Icon(Icons.camera_alt),
                      label: Text('Upload Image'),
                    ),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: addTimeline,
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Post', style: TextStyle(fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
