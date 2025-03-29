import 'package:flutter/material.dart';
import 'package:mobiletesting/View/login_screen.dart';
import 'package:mobiletesting/services/auth_service.dart';
import 'package:mobiletesting/utils/validators/validation.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  String selectedRole = "Student"; // default selected role for dropdowm
  bool isLoading = false; // to show loading spinner during signup waiting time
  bool isPasswordHidden = true;

  // instance for AuthService for authentication logic
  final AuthService _authService = AuthService();
  // signup function to handle user registration
  void _signup() async {
    // Validate inputs first
    String? emailError = CampusLinkValidator.validateEmail(
      emailController.text,
    );
    String? passwordError = CampusLinkValidator.validatePassword(
      passwordController.text,
    );

    // If any validation errors exist, show them and return
    if (emailError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }

    if (passwordError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(passwordError)));
      return;
    }
    setState(() {
      isLoading = true;
    });

    // call signup method from authservice with user inputs
    String? result = await _authService.signup(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      role: selectedRole,
    );

    setState(() {
      isLoading = false;
    });

    if (result == null) {
      // signup successful : Navigate to login screen with success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup Successful! Now Turn to Login")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // signup failed: show the error message
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Image.asset("assets/signup.png"),
                const SizedBox(height: 20),
                // name
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
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
                const SizedBox(height: 15),

                DropdownButtonFormField(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: "Role",
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ['Runner', 'Student'].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole =
                          newValue!; // update role selection in text field
                    });
                  },
                ),
                const SizedBox(height: 20),
                // signup button
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signup,
                        child: Text("Signup"),
                      ),
                    ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(fontSize: 18),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      },
                      child: Text(
                        "Login here",
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
