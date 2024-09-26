import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timelineapp/screens/login_screen.dart';
import 'dart:io';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  bool isLoading = false;

  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = File(pickedFile!.path);
    });
  }

  Future<String> uploadImage(File image) async {
    Reference ref =
        _storage.ref().child("profile_images").child(DateTime.now().toString());
    UploadTask uploadTask = ref.putFile(image);
    var imageUrl = await (await uploadTask).ref.getDownloadURL();
    return imageUrl;
  }

  void signUp() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Attempt to create a new user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Check if user creation is successful and the image is available
      if (userCredential.user != null && _image != null) {
        try {
          // Attempt to upload the profile image to FirebaseStorage
          String imageUrl = await uploadImage(_image!);

          // Store user data in Firestore with profile image
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': emailController.text,
            'profileImage': imageUrl,
          });

          // Navigate to the HomeScreen after successful sign-up
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => LoginScreen()));
        } catch (storageError) {
          // Handle errors during image upload to Firebase Storage
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => LoginScreen()));
          print('Image upload failed: $storageError');
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      if (e.code == 'email-already-in-use') {
        print('The email is already in use.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email already in use. Please log in.')),
        );
      } else if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The password is too weak.')),
        );
      } else {
        print('FirebaseAuthException: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e) {
      // Handle any other errors
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Sign Up",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              _image != null
                  ? CircleAvatar(
                      backgroundImage: FileImage(_image!),
                      radius: 40,
                    )
                  : GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: signUp,
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Sign Up', style: TextStyle(fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
