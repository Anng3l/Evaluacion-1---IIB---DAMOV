import 'package:evaluacion_flutter/tabs/users_tabs.dart';
import 'package:evaluacion_flutter/users_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try
  {
      // Inicializa Supabase
    await Supabase.initialize(
      url: 'https://aeibxelgxgyekteghbaq.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWJ4ZWxneGd5ZWt0ZWdoYmFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE5MTAzMTksImV4cCI6MjA2NzQ4NjMxOX0.djUFcD11biv7ND6PGek5DVWsqQPviFAcYZWVtVpY7vM',
    );
  }
  catch(e)
  {
    print(e);
  }
  
  try
  {
    // Inicializa Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBYNSV-w25kWc0alTNfuaGHaq1YTzzARNQ",
        authDomain: "damov-f01bc.firebaseapp.com",
        projectId: "damov-f01bc",
        storageBucket: "damov-f01bc.firebasestorage.app",
        messagingSenderId: "301407417101",
        appId: "1:301407417101:web:a3ad24b0e8b10b7c3a3644",
        measurementId: "G-K9ETLVGQ9N"
      )
    );
  }
  catch(e)
  {
    print(e);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tareas',
      home: const AuthGate(),
    );
  }
}






class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();

    _checkSession();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _checkSession();
      }
    });
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 1));
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const UsersTabs()),
        (route) => false,
      );
    }
    else
    {
      /*try
      {
        await Supabase.instance.client.auth.signOut();
      }
      catch(e)
      {

      }*/
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }

    if (!mounted) return;

    setState(() {
      _checkingSession = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8AD25)),
          ),
        ),
      );
    }

    return const LoginPage();
  }
}
