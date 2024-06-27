import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onSignUpSelected;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  final Function(String, String) signInWithEmailPassword;
  final Function signInWithGoogle;
  final Function signInWithFacebook;



  const LoginForm({super.key,
    required this.onSignUpSelected,
    required this.emailController,
    required this.passwordController,
    required this.signInWithEmailPassword,
    required this.signInWithGoogle,
    required this.signInWithFacebook,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {

  bool _obscureText = true;
  bool _isEmailValid = false;



  @override
  Widget build(BuildContext context) {
    return Card( // Enclose the form in a Card
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email TextField
            TextFormField(
              controller: widget.emailController,
              decoration: InputDecoration(
                labelText: 'Your Soulmate Email',
                hintText: 'Enter your email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: _isEmailValid
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                setState(() {
                  _isEmailValid = value.contains('@');
                });
              },
            ),
            const SizedBox(height: 8),
            if (_isEmailValid)
              const Text(
                'Ah, a lovely email address!',
                style: TextStyle(color: Colors.green),
              ),

            const SizedBox(height: 16),

            // Password TextField
            TextFormField(
              controller: widget.passwordController,
              decoration: InputDecoration(
                labelText: 'Key to Your Heart',
                hintText: 'Enter your password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
              obscureText: _obscureText,
            ),

            const SizedBox(height: 24),

            // Email Sign-In Button
            ElevatedButton(
              onPressed: () => widget.signInWithEmailPassword(
                  widget.emailController.text, widget.passwordController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[200],
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text('Unite Our Hearts'),
            ),
            const SizedBox(height: 16),

            // Google Sign-In Button
            ElevatedButton(
              onPressed: () => widget.signInWithGoogle(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Adjust as needed
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical:15),
                textStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.black, // Adjust as needed
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text('Sign in with Google'),
            ),
            const SizedBox(height: 16),

            // Facebook Sign-In Button
            ElevatedButton(
              onPressed: () => widget.signInWithFacebook(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800], // Adjust as needed
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.white, // Adjust as needed
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text('Sign in with Facebook'),
            ),
            const SizedBox(height: 16),

            // Sign-Up Text Button
            TextButton(
              onPressed: widget.onSignUpSelected,
              child: const Text('New to Love? Find Your Match'),
            ),
          ],
        ),
      ),
    );
  }
}