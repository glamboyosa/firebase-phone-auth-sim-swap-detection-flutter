import 'package:flutter/material.dart';
import 'package:flutterfire/helpers.dart';
import 'package:flutterfire/login.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isInitialized = false;
  bool initializationError = false;
  // function for initializing FlutterFire

  void initializeFlutterFire() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        isInitialized = true;
      });
    } catch (e) {
      setState(() {
        initializationError = true;
      });
    }
  }
    @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    if (initializationError) {
      errorHandler(context, 'Something Went Wrong.', 'Please restart the app.');
    }
    if(!isInitialized){
       return const Center(
      child: CircularProgressIndicator(),
    );
    }
    return MaterialApp(
      title: 'Flutter Firebase & tru.ID SIMCheck',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Login(),
    );
  }
}
