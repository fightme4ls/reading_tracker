import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart'; // Import MainScreen
import 'signup_page.dart'; // Import SignUpPage
import 'forgotpassword_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    await user.reload(); // Reload user data to get the most updated information
    return user.emailVerified; // Return if email is verified
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled the sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } catch (error) {
      print("Google Sign-In failed: $error");
      setState(() {
        _errorMessage = "Failed to sign in with Google.";
      });
    }
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
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),

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
            TextField(
              controller: passwordController,
              obscureText: !_isPasswordVisible,
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
            ElevatedButton(
              onPressed: () async {
                String email = emailController.text;
                String password = passwordController.text;

                // Check if the email format is valid
                if (!_isEmailValid(email)) {
                  setState(() {
                    _errorMessage = 'Please enter a valid email address.';
                  });
                  return;
                }

                try {
                  // Attempt to sign in the user with email and password
                  UserCredential userCredential =
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  User? user = userCredential.user;
                  if (user != null) {
                    // Check if the email is verified
                    bool isVerified = await _checkEmailVerification(user);
                    if (isVerified) {
                      // If email is verified, navigate to the main screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen()),
                      );
                    } else {
                      // If email is not verified, show info message and log out
                      await user.sendEmailVerification();
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
                  FirebaseAuth.instance.signOut();
                }
              },
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                textStyle: TextStyle(fontSize: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.black,
              ),
            ),
            SizedBox(height: 36),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              child: Text('Don\'t have an account? Sign Up'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                textStyle: TextStyle(fontSize: 16),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _signInWithGoogle,
              icon: Image.asset(
                'assets/google_logo.png',
                height: 24,
                width: 24,
              ),
              label: Text('Login with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                );
              },
              child: Text('Forgot Password?'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                textStyle: TextStyle(fontSize: 16),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.home, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
