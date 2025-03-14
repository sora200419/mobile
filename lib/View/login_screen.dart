import 'package:flutter/material.dart';
import 'package:mobiletesting/View/home_admin.dart';
import 'package:mobiletesting/View/home_runner.dart';
import 'package:mobiletesting/View/home_student.dart';
import 'package:mobiletesting/View/signup_screen.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 196, 222, 234),
      body: SafeArea(
        child: SingleChildScrollView(
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
                authProvider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          String email = emailController.text.trim();
                          String password = passwordController.text.trim();

                          String? error = await authProvider.login(
                            email: email,
                            password: password,
                          );

                          if (error == null) {
                            if (authProvider.role == "Admin") {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => HomeAdmin()),
                              );
                            } else if (authProvider.role == "Runner") {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => HomeRunner()),
                              );
                            } else if (authProvider.role == "Student") {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => HomeStudent()),
                              );
                            }
                            else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Login Failed: $error")),
                              );
                            }
                          }
                        },
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
      ),
    );
  }
}
