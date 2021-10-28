import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Flutter Auth Demo'),
    );
  }

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();

}

class _MyHomePageState extends State<MyHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  late String _verificationId;
  final SmsAutoFill _autoFill = SmsAutoFill();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _auth.setLanguageCode("my-MM");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      body: Padding(padding: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone number (+xx xxx-xxx-xxxx)'),
              ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              alignment: Alignment.center,
              child: RaisedButton(
                child: Text('Get Current Number'),
                onPressed: () async => {
                  _phoneNumberController.text = (await _autoFill.hint)!
                },
                color: Colors.greenAccent[700]
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              alignment: Alignment.center,
              child: RaisedButton(
                color: Colors.greenAccent[400],
                child: Text('Verify Number'),
                onPressed: () async {
                  verifyPhoneNumber();
                },
              ),
            ),
            TextFormField(
              controller: _smsController,
              decoration: const InputDecoration(labelText: 'Verification Code'),
            ),
            Container(
              padding: const EdgeInsets.only(top: 16.0),
              alignment: Alignment.center,
              child: RaisedButton(
                color: Colors.greenAccent[200],
                onPressed: () async {
                  signInWithPhoneNumber();
                },
                child: Text('Sign in'),
              ),
            )
            ],
        ),
      ),),
    );
  }

  Future<void> verifyPhoneNumber() async {
    PhoneVerificationCompleted verificationCompleted = (PhoneAuthCredential phoneAuthCredential) async {
      await _auth.signInWithCredential(phoneAuthCredential);
      showSnackbar("Phone number automatically verfied and user signed in : ${_auth.currentUser!.uid}");
      print(_auth.currentUser!.uid);
    };

    PhoneVerificationFailed verificationFailed = (FirebaseAuthException authException) {
      showSnackbar('Phone number verification failed. Code : ${authException.code}. Message : ${authException.message}');
      print(authException.message);
    };

    PhoneCodeSent codeSent = (String verificationId, int forceResendingToken) async {
      showSnackbar('Please check your phone for the verification code.');
      _verificationId = verificationId;
    } as PhoneCodeSent;

    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout = (String verificationId) {
      showSnackbar('verification code : '+ verificationId);
      _verificationId = verificationId;
    };

    try{
      await _auth.verifyPhoneNumber(
          phoneNumber: _phoneNumberController.text,
          timeout: const Duration(seconds: 5),
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout
      );
    } catch (e) {
      showSnackbar("Failed to verify phone number : ${e}");
      print(e);
    }


  }

  void signInWithPhoneNumber() async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: _smsController.text
      );

      final User? user = (await _auth.signInWithCredential(credential)).user;
      showSnackbar("Successfully signed in UID : ${user!.uid}");
    }catch (e){
      showSnackbar("Failed to sign in : "+e.toString());
    }
  }

  void showSnackbar(String s) {
    _scaffoldKey.currentState!.showSnackBar(SnackBar(content: Text(s)));
  }

}