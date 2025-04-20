import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  String? _errorMessage;
  String? _infoMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display error message if there's any
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade400, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Display info message if there's any
              if (_infoMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _infoMessage!,
                    style: TextStyle(color: Colors.green, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 20),
              // Email input field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email to reset your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                ),
              ),
              SizedBox(height: 24),
              // Reset Password button
              ElevatedButton(
                onPressed: () async {
                  String email = emailController.text.trim();

                  if (email.isEmpty) {
                    setState(() {
                      _errorMessage = 'Please enter your email address.';
                    });
                    return;
                  }

                  // Send password reset email using Firebase Authentication
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    setState(() {
                      _infoMessage = 'A password reset link has been sent to your email address.';
                      _errorMessage = null;
                    });

                    emailController.clear();
                  } on FirebaseAuthException catch (error) {
                    setState(() {
                      _errorMessage = 'Error: ${error.message}';
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 16),
                ),
                child: Text('Send Password Reset Link'),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate back to the Login screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text(
                  'Back to Login',
                  style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}