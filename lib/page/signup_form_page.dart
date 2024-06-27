import 'package:flutter/material.dart';

class SignUpForm extends StatefulWidget {
  final VoidCallback onSignInSelected;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Function(String, String) signUpWithEmailPassword;

  const SignUpForm({super.key,
    required this.onSignInSelected,
    required this.emailController,
    required this.passwordController,
    required this.signUpWithEmailPassword,
    required this.confirmPasswordController,
  });

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  bool _hasCapital = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _hasEightChars = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  double _passwordStrength = 0.0;
  bool _showPasswordStrength = false; // Add this variable

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _confirmPasswordController = TextEditingController();


  void _checkPasswordStrength(String password) {
    int strength = 0;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    if (password.length >= 8) strength++;

    setState(() {
      _passwordStrength = strength / 4.0; // Normalize strength to 0.0- 1.0
      _hasCapital = password.contains(RegExp(r'[A-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasEightChars = password.length >= 8;
      _showPasswordStrength = password.isNotEmpty; // Show if password is not empty
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card( // Enclose the form in a Card
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email TextField
              TextFormField(
                controller: widget.emailController,
                decoration: InputDecoration(
                  labelText: 'Your Love Letter Email',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password TextField
              TextFormField(
                controller: widget.passwordController,
                decoration: InputDecoration(
                  labelText: 'Secret of Our Love',
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
                onChanged: _checkPasswordStrength,
              ),

              // Conditionally show password strength indicator
              if (_showPasswordStrength) ...[
                LinearProgressIndicator(
                  value: _passwordStrength,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _passwordStrength >= 0.75
                        ? Colors.green
                        : _passwordStrength >= 0.5
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _passwordStrength < 0.5
                      ? 'Our love needs a stronger password...'
                      : _passwordStrength < 0.75
                      ? 'Almost there, add a little more spice!'
                      : 'Perfect! Our love is unbreakable!',
                  style: TextStyle(
                    color: _passwordStrength >= 0.75
                        ? Colors.green
                        : _passwordStrength >= 0.5
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Confirm Password TextField
              TextFormField(
                controller:_confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Whisper It Again',
                  hintText: 'Confirm your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmText = !_obscureConfirmText;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmText,
              ),
              const SizedBox(height: 16),

              // Password Strength Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _buildPasswordIndicator(_hasCapital, 'Capital Letter')),
                  Expanded(child: _buildPasswordIndicator(_hasNumber, 'Number')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _buildPasswordIndicator(_hasSpecialChar, 'Special Character')),
                  Expanded(child: _buildPasswordIndicator(_hasEightChars, 'At least 8 characters')),
                ],
              ),
              const SizedBox(height: 24),

              // Sign Up Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (widget.passwordController.text == _confirmPasswordController.text) {
                      if (_hasCapital && _hasNumber && _hasSpecialChar && _hasEightChars) {
                        // All password criteria met, proceed with sign up
                        widget.signUpWithEmailPassword(
                            widget.emailController.text, widget.passwordController.text);
                      } else {
                        // Show an error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Our love deserves a strong foundation! Make sure your password has a capital letter, a number, a special character, and is at least 8 characters long.'),
                          ),
                        );
                      }
                    } else {
                      // Show an error if the passwords don't match
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Our heartsbeat as one, but these passwords don\'t match!')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[200],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: const Text('Begin Our Story'),
              ),
              const SizedBox(height: 16),

              // Sign In Text Button
              TextButton(
                onPressed: widget.onSignInSelected,
                child: const Text('Already Found Love? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build password strength indicators
  Widget _buildPasswordIndicator(bool isMet, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent Column from taking up extra space
        children: [
          Container(
            width: 14,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
              child: Text(
                  label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center, // Center the text
                overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
              ),),

        ],
      ),
    );
  }
}