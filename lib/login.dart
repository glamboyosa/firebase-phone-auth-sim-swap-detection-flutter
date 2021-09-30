import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutterfire/models.dart';
import 'package:http/http.dart' as http;
import 'package:flutterfire/helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tru_sdk_flutter/tru_sdk_flutter.dart';

final String baseURL = '<YOUR_LOCAL_TUNNEL_URL>';

class Login extends StatefulWidget {
  Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

// Success scenario UI
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
  final phoneNumber = TextEditingController();
  final otp = TextEditingController();
  String? phoneNumberValue;
  int? resendingToken;
  bool proceedWithFirebaseAuth = false;
  bool loading = false;
  @override
  void dispose() {
    phoneNumber.dispose();
    otp.dispose();
    super.dispose();
  }

// OTP Screen UI
  Future<void> otpHandler(
      BuildContext context, FirebaseAuth auth, String verificationId) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Please Enter OTP"),
            content: TextField(
              keyboardType: TextInputType.phone,
              controller: otp,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter OTP',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  // create a PhoneAuthCredential with the otp

                  PhoneAuthCredential credential = PhoneAuthProvider.credential(
                      verificationId: verificationId, smsCode: otp.text);
                  try {
                    // sign in the user
                    await auth.signInWithCredential(credential);

                    setState(() {
                      loading = false;
                    });
                  } catch (e) {
                    print(e);

                    setState(() {
                      loading = false;
                    });
                    return errorHandler(context, "Unable to sign you in.",
                        "Unable to sign you in at this moment. Please try again");
                  }

                  successHandler(context);

                  return Navigator.pop(context, 'OK');
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
  }

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
                    controller: phoneNumber,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your phone number.',
                    ),
                  )),
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

                      // check if we have coverage
                      TruSdkFlutter sdk = TruSdkFlutter();

                      String? reachabilityInfo = await sdk.isReachable();

                      ReachabilityDetails reachabilityDetails =
                          json.decode(reachabilityInfo!);

                      bool isSIMCheckSupported = false;

                      if (reachabilityDetails.error?.status != 412) {
                        isSIMCheckSupported = false;

                        for (var products in reachabilityDetails.products!) {
                          if (products.productName == "Sim Check") {
                            isSIMCheckSupported = true;
                          }
                        }
                      } else {
                        isSIMCheckSupported = true;
                      }

                      if (isSIMCheckSupported) {
                        // SIMCheck is supported, create SIMCheck
                        SIMCheck? SIMCheckResult =
                            await createSIMCheck(phoneNumber.text);

                        if (SIMCheckResult == null) {
                          setState(() {
                            loading = false;
                          });
                          return errorHandler(context, 'Something went wrong.',
                              'Phone number not supported');
                        }

                        if (SIMCheckResult.simChanged) {
                          setState(() {
                            loading = false;
                            phoneNumberValue = phoneNumber.text;
                          });
                          phoneNumber.clear();
                          return errorHandler(context, 'Something went wrong',
                              'SIM changed too recently.');
                        }

                        //The SIM hasn't changed in 7 days, proceed with Firebase Auth

                        // create a Firebase Auth instance
                        FirebaseAuth auth = FirebaseAuth.instance;

                        await auth.verifyPhoneNumber(
                          phoneNumber: phoneNumberValue!,
                          timeout: const Duration(seconds: 120),
                          verificationCompleted:
                              (PhoneAuthCredential credential) async {
                            // Android only method that auto-signs in on Android devices that support it
                            await auth.signInWithCredential(credential);

                            setState(() {
                              loading = false;
                            });

                            return successHandler(context);
                          },
                          verificationFailed: (FirebaseAuthException e) {
                            setState(() {
                              loading = false;
                            });

                            errorHandler(context, 'Something went wrong.',
                                'Unable to verify your phone number');

                            return;
                          },
                          codeSent:
                              (String verificationId, int? resendToken) async {
                            // save resendToken to state

                            setState(() {
                              resendingToken = resendToken;
                            });

                            print("your resend token is: ");

                            print(resendToken);
                            // render OTP dialog UI
                            otpHandler(context, auth, verificationId);
                          },
                          codeAutoRetrievalTimeout: (String verificationId) {},
                        );
                      } else {
                        // SIM Check isn't supported by MNO do not bother creating SIMCheck just proceed with Firebase Auth
                        // create a Firebase Auth instance
                        phoneNumber.clear();
                        FirebaseAuth auth = FirebaseAuth.instance;
                        await auth.verifyPhoneNumber(
                          phoneNumber: phoneNumberValue!,
                          timeout: const Duration(seconds: 120),
                          verificationCompleted:
                              (PhoneAuthCredential credential) async {
                            // Android only method that auto-signs in on Android devices that support it
                            await auth.signInWithCredential(credential);

                            setState(() {
                              loading = false;
                            });

                            return successHandler(context);
                          },
                          verificationFailed: (FirebaseAuthException e) {
                            setState(() {
                              loading = false;
                            });

                            errorHandler(context, 'Something went wrong.',
                                'Unable to verify your phone number');

                            return;
                          },
                          codeSent:
                              (String verificationId, int? resendToken) async {
                            // save resendToken to state

                            setState(() {
                              resendingToken = resendToken;
                            });

                            print("your resend token is: ");

                            print(resendToken);
                            // render OTP dialog UI
                            otpHandler(context, auth, verificationId);
                          },
                          codeAutoRetrievalTimeout: (String verificationId) {},
                        );
                      }
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
