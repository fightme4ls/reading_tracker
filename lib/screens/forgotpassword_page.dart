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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display error message if there's any
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            // Display info message if there's any
            if (_infoMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _infoMessage!,
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
              ),
            // Email input field
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Enter your email',
                hintText: 'Enter your email to reset password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 24),
            // Reset Password button
            ElevatedButton(
              onPressed: () async {
                String email = emailController.text;

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
                    _infoMessage = 'Password reset email has been sent.';
                    _errorMessage = null;
                  });
                } on FirebaseAuthException catch (error) {
                  setState(() {
                    _errorMessage = 'Error: ${error.message}';
                  });
                }
              },
              child: Text('Send Reset Link'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                textStyle: TextStyle(fontSize: 16),
                backgroundColor: Colors.blue,
              ),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                onPressed: () {
                  // Navigate back to the Home screen (MainScreen)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text('Back to Login'),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                onPressed: () {
                  // Navigate back to the Home screen (MainScreen)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                  );
                },
                child: Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
