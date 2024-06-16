import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../screens/navigate.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLogin = true; // To toggle between login and signup
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;

  // Add TextEditingController for email and password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleFormMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _isLogin ? _animationController.forward() : _animationController.reverse();
  }


  void _onAuthenticationSuccess() {
  Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const MyHomePage()),
  );
  }

  Future<void> _signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = _isLogin
          ? await _auth.signInWithEmailAndPassword(email: email, password: password)
          : await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (!_isLogin) {
        await userCredential.user?.sendEmailVerification();
        if (mounted) {
          _showErrorDialog(context, 'Please check your email to verify your account.');
        }
      } else {
        if (userCredential.user?.emailVerified ?? false) {
          _onAuthenticationSuccess();
        } else {
          if (mounted) {
            _showErrorDialog(context, 'You need to verify your email to login.');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Try again later.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'invalid-verification-code':
          errorMessage = 'Invalid verification code.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Invalid verification ID.';
          break;
        default:
          errorMessage = 'An unexpected error occurred: ${e.message}';
      }
      if (mounted) {
        _showErrorDialog(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, 'An unexpected error occurred.');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // The user aborted the sign-in
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      _onAuthenticationSuccess();
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with a different credential.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential received is malformed or has expired.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operation not allowed. Please contact support.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found for the given credentials.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-verification-code':
          errorMessage = 'Invalid verification code.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Invalid verification ID.';
          break;
        default:
          errorMessage = 'An unexpected error occurred: ${e.message}';
      }
      if (mounted) {
        _showErrorDialog(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, 'An unexpected error occurred during Google sign-in.');
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        await _auth.signInWithCredential(credential);
        _onAuthenticationSuccess();
      } else {
        if (mounted) {
          _showErrorDialog(context, 'An error occurred during Facebook sign-in: ${result.message}');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with a different credential.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential received is malformed or has expired.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operation not allowed. Please contact support.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found for the given credentials.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-verification-code':
          errorMessage = 'Invalid verification code.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Invalid verification ID.';
          break;
        default:
          errorMessage = 'An unexpected error occurred: ${e.message}';
      }
      if (mounted) {
        _showErrorDialog(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, 'An unexpected error occurred during Facebook sign-in.');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) async {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) =>
            AlertDialog(
              title: const Text('Authentication Error'),
              content: Text(message),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Okay'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                )
              ],
            ),
      );
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          // Perspective effect
          final Matrix4 transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(3.1415 * _flipAnimation.value);
          // Here you can add your flip animation logic
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: _isLogin ? LoginForm(onSignUpSelected: _toggleFormMode,emailController: _emailController,passwordController: _passwordController,signInWithEmailPassword: _signInWithEmailPassword,signInWithFacebook: _signInWithFacebook,signInWithGoogle: _signInWithGoogle,) : SignUpForm(onSignInSelected: _toggleFormMode,emailController: _emailController,passwordController: _passwordController,signUpWithEmailPassword: _signInWithEmailPassword,confirmPasswordController: _confirmPasswordController,),
          );
        },
      ),
    );
  }
}

// LoginForm with updated onPressed callbacks
class LoginForm extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return  Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: () => signInWithEmailPassword(emailController.text, passwordController.text),
            child: const Text('Login'),
          ),
          ElevatedButton(
            onPressed: () => signInWithGoogle(),
            child: const Text('Sign in with Google'),
          ),
          ElevatedButton(
            onPressed: () => signInWithFacebook(),
            child: const Text('Sign in with Facebook'),
          ),
          TextButton(
            onPressed: onSignUpSelected,
            child: const Text('Don\'t have an account? Sign up'),
          ),
        ],

    );
  }
}

// SignUpForm with updated onPressed callbacks and password comparison logic
class SignUpForm extends StatelessWidget {
  final VoidCallback onSignInSelected;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Function(String, String) signUpWithEmailPassword;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  SignUpForm({super.key,
    required this.onSignInSelected,
    required this.emailController,
    required this.passwordController,
    required this.signUpWithEmailPassword,
    required this.confirmPasswordController,
  });

  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return 'please enter a valid email';
              }
              return null;
            },
          ),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: () {
              if
              (_formKey.currentState!.validate()) {
                if (passwordController.text ==
                    _confirmPasswordController.text) {
                  signUpWithEmailPassword(
                      emailController.text, passwordController.text);
                } else {
                  // Show an error if the passwords don't match
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match.')),
                  );
                }
              }
            },
            child: const Text('Sign Up'),
          ),

          TextButton(
            onPressed: onSignInSelected,
            child: const Text('Already have an account? Login'),
          ),
        ],
      ),
    );
  }
}

