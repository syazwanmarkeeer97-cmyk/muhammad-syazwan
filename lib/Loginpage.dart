import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dashboard_page.dart';
import 'register_page.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  var emailController = TextEditingController();
  var passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title:Text('Smart Lab Safety'),
        centerTitle: true,
      ),

      body: Padding(
        padding:EdgeInsets.all(16.0),

        child: ListView(
          children: [
             SizedBox(height: 30),

             Icon(
              Icons.health_and_safety,
              size: 80,
              color: Colors.deepPurple,
            ),

             SizedBox(height: 20),

             Text(
              'LOGIN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

             SizedBox(height: 10),

             Text(
              'Hi please insert your email',
              textAlign: TextAlign.center,
            ),

             SizedBox(height: 30),

            // email to field
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
            ),

             SizedBox(height: 20),

            // password to field
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
            ),

             SizedBox(height: 30),

            // Button login
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.trim().isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                      content: Text('please insert email and password'),
                    ),
                  );
                  return;
                }

                try {
                  // please check email and password with Firebase
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                  );

                  if (!context.mounted) return;

                  // if login success, open dashboard
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  DashboardPage(),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  if (!context.mounted) return;

                  // displogin gagal
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fail login: ${e.message}'),
                    ),
                  );
                }
              },
              child:  Text('LOGIN'),
            ),

             SizedBox(height: 10),

            // button page for register
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterPage(),
                  ),
                );
              },
              child:Text('Dont have account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}