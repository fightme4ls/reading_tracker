import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _errorMessage;
  String? _infoMessage;

  // Regex to check email format
  bool _isEmailValid(String email) {
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9]+([._%+-])*[a-zA-Z0-9]*@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up Page'),
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
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
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
                String confirmPassword = confirmPasswordController.text;

                if (!_isEmailValid(email)) {
                  setState(() {
                    _errorMessage = 'Please enter a valid email address.';
                  });
                  return;
                }

                if (password != confirmPassword) {
                  setState(() {
                    _errorMessage = null;
                  });
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Error'),
                      content: Text('Passwords do not match!'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                try {
                  UserCredential userCredential =
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  await userCredential.user!.sendEmailVerification();

                  setState(() {
                    _infoMessage = 'A verification email has been sent to $email. Please verify your email before logging in.';
                    _errorMessage = null;
                  });

                  await FirebaseAuth.instance.signOut();
                } on FirebaseAuthException catch (error) {
                  setState(() {
                    _errorMessage = error.message ?? 'An unknown error occurred';
                  });
                  print("Failed to sign up!");
                  print(error.toString());
                }
              },
              child: Text('Sign Up'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                textStyle: TextStyle(fontSize: 16),
                backgroundColor: Colors.green,
              ),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text('Already have an account? Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
