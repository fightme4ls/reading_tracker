import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart'; // Import MainScreen
import 'signup_page.dart'; // Import SignUpPage
import 'forgotpassword_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? _errorMessage;
  String? _infoMessage;
  String? _infoMessage2;
  bool _isPasswordVisible = false;

  // Regex to check email format
  bool _isEmailValid(String email) {
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9]+([._%+-])*[a-zA-Z0-9]*@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Check if email is verified and return a bool
  Future<bool> _checkEmailVerification(User user) async {
    await user.reload(); // Reload user data to make sure we get the most updated information
    if (!user.emailVerified) {
      return false; // Email is not verified
    }
    return true; // Email is verified
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
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

            // Display info message if there's any (for email verification)
            if (_infoMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _infoMessage!,
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
              ),

            if (_infoMessage2 != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _infoMessage2!,
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
              ),
            // Email input field
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),
            // Password input field
            TextField(
              controller: passwordController,
              obscureText: !_isPasswordVisible, // Toggle visibility
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 24),
            // Login button
            ElevatedButton(
              onPressed: () async {
                String email = emailController.text;
                String password = passwordController.text;

                // First, check if the email format is valid
                if (!_isEmailValid(email)) {
                  setState(() {
                    _errorMessage = 'Please enter a valid email address.';
                  });
                  return;
                }

                try {
                  // try to sign in the user with email and password
                  UserCredential userCredential =
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  User? user = userCredential.user;
                  if (user != null) {
                    // check if the email is verified
                    bool isVerified = await _checkEmailVerification(user);
                    if (isVerified) {
                      // if email is verified, navigate to the main screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen()),
                      );
                    } else {
                      // if email is not verified, show info message
                      await user.sendEmailVerification();
                      print("Attempting to send email");
                      setState(() {
                        _infoMessage = 'Please verify your email address before logging in.';
                        _infoMessage2 = 'Resending verification email.';
                        _errorMessage = null;
                      });

                      FirebaseAuth.instance.signOut();
                    }
                  }
                } on FirebaseAuthException catch (error) {
                  setState(() {
                    _errorMessage = 'Email or Password is incorrect';
                  });
                  print("Failed to sign in!");
                  print(error.toString());
                }
              },
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                textStyle: TextStyle(fontSize: 16),
                backgroundColor: Colors.blue,
              ),
            ),
            SizedBox(height: 16),
            // Sign Up button
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                onPressed: () {
                  // Navigate to the SignUpPage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
                child: Text('Don\'t have an account? Sign Up'),
              ),
            ),
            // Add Forgot Password Button under the Sign Up button
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                onPressed: () {
                  // Navigate to the ForgotPasswordPage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                  );
                },
                child: Text('Forgot Password?'),
              ),
            ),
            // Back to Home button (added below SignUp button)
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
