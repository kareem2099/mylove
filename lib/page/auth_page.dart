import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:mylove/page/login_form_page.dart';
import 'package:mylove/screens/user_onboarding_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mylove/service/AudioPlayerService.dart';
import 'package:provider/provider.dart';

import 'signup_form_page.dart'; // Import for audio playback


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

  bool _isLoading = false; // Add loading state
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 2).animate(_animationController);
    _playBackgroundMusic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioPlayerService>(context, listen: false)
          .playBackgroundMusic();});

  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
    _audioPlayer.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    await _audioPlayer.play(AssetSource('video/songSplashScreen.mp3'));
    setState(() {
      _isPlaying = true;
    });
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
      MaterialPageRoute(
        builder: (context) => const UserOnboardingScreen()),

    );
  }


  Future<void> _signInWithEmailPassword(String email, String password) async {
    setState(() {
      _isLoading = true;
    });
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
    } finally { // Add the finally block here
      setState(() {
        _isLoading = false; // Hide loading indicator regardless of outcome
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
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
    } finally { // Add the finally block here
      setState(() {
        _isLoading = false; // Hide loading indicator regardless of outcome
      });
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      _isLoading = true;
    });
    try {
      print('Attempting Facebook login');
      final LoginResult result = await FacebookAuth.instance.login();
      print('Facebook login result; $result');
      if (result.status == LoginStatus.success) {
        print('Facebook Login successful');
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        print('Facebook OAuth Credential obtained: $credential');
        await _auth.signInWithCredential(credential);
        print('Firebase sign-in with facebook credential successful');
        _onAuthenticationSuccess();
      } else {
        print('Facebook login failed; {result.message}');
        if (mounted) {
          _showErrorDialog(context, 'An error occurred during Facebook sign-in: ${result.message}');
        }
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during facebook sign-in: ${e.code}');
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
      print('General exception during Facebook sign-in: $e');
      if (mounted) {
        _showErrorDialog(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, 'An unexpected error occurred during Facebook sign-in: $e.');
      }
    } finally { // Add the finally block here
      setState(() {
        _isLoading = false; // Hide loading indicator regardless of outcome
      });
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
      appBar: AppBar(
        title: const Text(
          'OUR LOVE QUIZ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.pink[300],
      ),
      body: Stack(
        children:[
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/third.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: AnimatedBuilder(
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
                  child: Container(
                  padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              ),
                child: _isLogin ? LoginForm(onSignUpSelected: _toggleFormMode,emailController: _emailController,passwordController: _passwordController,signInWithEmailPassword: _signInWithEmailPassword,signInWithFacebook: _signInWithFacebook,signInWithGoogle: _signInWithGoogle,) : SignUpForm(onSignInSelected: _toggleFormMode,emailController: _emailController,passwordController: _passwordController,signUpWithEmailPassword: _signInWithEmailPassword,confirmPasswordController: _confirmPasswordController,),
                  ),
              );

            },
                    ),
          ),
          if (_isLoading) // Show loading indicator when _isLoading is true
            const Center(
              child: CircularProgressIndicator(),
            ),
      ],
      ),
    );
  }
}
