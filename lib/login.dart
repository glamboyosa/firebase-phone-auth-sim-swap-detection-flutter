import 'package:flutter/material.dart';
import 'package:flutterfire/models.dart';
import 'package:http/http.dart' as http;
import 'package:flutterfire/helpers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

final String baseURL = '<YOUR_LOCAL_TUNNEL_URL>';

class Login extends StatefulWidget {
  Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

Future<void> successHandler(BuildContext context) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Successful.'),
          content: const Text('✅'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        );
      });
}

Future<SIMCheck?> createSIMCheck(String phoneNumber) async {
  final response = await http.post(Uri.parse('$baseURL/sim-check'),
      body: {"phone_number": phoneNumber});

  if (response.statusCode != 200) {
    return null;
  }
  final String data = response.body;

  return SIMCheckFromJSON(data);
}

class _LoginState extends State<Login> {
  String? phoneNumber;
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.only(bottom: 45.0),
                margin: const EdgeInsets.only(top: 50),
                child: Image.asset(
                  'assets/images/tru-id-logo.png',
                )),
            Container(
                width: double.infinity,
                child: const Text(
                  'Login.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                )),
            Container(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
                child: TextField(
                  keyboardType: TextInputType.phone,
                  onChanged: (text) {
                    setState(() {
                      phoneNumber = text;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your phone number.',
                  ),
                ),
              ),
            ),
            Container(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
                child: TextButton(
                    onPressed: () async {
                      setState(() {
                        loading = true;
                      });

                      SIMCheck? SIMCheckResult =
                          await createSIMCheck(phoneNumber!);

                      if (SIMCheckResult == null) {
                        return errorHandler(context, 'Something went wrong.',
                            'Phone number not supported');
                      }

                      if (SIMCheckResult.simChanged) {
                        return errorHandler(context, 'Something went wrong',
                            'SIM changed too recently.');
                      }

                      // SIM hasn't changed within 7 days. Proceed with Firebase Auth

                      // create a Firebase Auth instance
                      FirebaseAuth auth = FirebaseAuth.instance;
                      await auth.verifyPhoneNumber(
                        phoneNumber: phoneNumber!,
                        verificationCompleted:
                            (PhoneAuthCredential credential) {
                          // Android only method that auto-signs in on Android devices that support it
                          auth.signInWithCredential(credential);
                        },
                        verificationFailed: (FirebaseAuthException e) {
                          errorHandler(context, 'Something went wrong.',
                              'Unable to verify your phone number');
                          return;
                        },
                        codeSent: (String verificationId, int? resendToken) {

                        },
                        codeAutoRetrievalTimeout: (String verificationId) {},
                      );
                    },
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('Login')),
              ),
            )
          ],
        ),
      ),
    );
  }
}
