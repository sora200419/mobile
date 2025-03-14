// lib\View\login_screen.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/View/home_admin.dart';
import 'package:mobiletesting/View/home_runner.dart';
import 'package:mobiletesting/View/home_student.dart';
import 'package:mobiletesting/View/signup_screen.dart';
import 'package:mobiletesting/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;
  final AuthService _authService = AuthService();
  bool isLoading = false;
  void login() async {
    setState(() {
      isLoading = true;
    });

    // call login method from authservice with user inputs
    String? result = await _authService.login(
      email: emailController.text,
      password: passwordController.text,
    );
    setState(() {
      isLoading = false;
    });
    // Navigate based on the role or show the error message
    if (result == "Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeAdmin()),
      );
    } else if (result == "Runner") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeRunner()),
      );
    } else if (result == "Student") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeStudent()),
      );
    } else {
      // login failed: show the error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Signup Failed $result")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 196, 222, 234),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset("assets/logo.png"),
              const SizedBox(height: 20),
              // email
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              // password
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        isPasswordHidden = !isPasswordHidden;
                      });
                    },
                    icon: Icon(
                      isPasswordHidden
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: isPasswordHidden,
              ),
              const SizedBox(height: 20),
              // login button
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: login,
                      child: Text("Login"),
                    ),
                  ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 18),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => SignupScreen()),
                      );
                    },
                    child: Text(
                      "Signup here",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
