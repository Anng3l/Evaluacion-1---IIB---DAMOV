import 'package:flutter/material.dart';
import 'package:evaluacion_flutter/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();


  final supabase = Supabase.instance.client;
  bool _obscurePassword = true;
  bool _cargando = false;

  void _showSnackBar(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool validarCampos() {
    final campos = {
      'Correo': emailController.text.trim(),
      'Contraseña': passwordController.text.trim(),
      'Nombre': nameController.text.trim(),
      'Apellido': lastNameController.text.trim(),
    };

    for (final entry in campos.entries) {
      if (entry.value.isEmpty) {
        _showSnackBar('Todos los campos son obligatorios.', error: true);
        return false;
      }
    }
    return true;
  }

  Future<void> signup() async {
    if (!validarCampos()) return;

    setState(() => _cargando = true);

    try {     
        final response = await supabase.auth.signUp(
        email: emailController.text,
        password: passwordController.text,
        emailRedirectTo: 'userTasks://auth/callback',
        //emailRedirectTo: 'elbuhoturismo://auth/callback',
      );

      final user = response.user;



      if (user != null) {
        await supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'name': nameController.text,
          'lastname': lastNameController.text,
        });

        _showSnackBar('Revisa tu correo para confirmar tu cuenta.');

        // Limpiar campos
        emailController.clear();
        passwordController.clear();
        nameController.clear();
        lastNameController.clear();
      

        // Redirigir al login
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar('Error al registrarse: $e', error: true);
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child:
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height,),
          child: IntrinsicHeight(
            child:    
              Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 255, 149, 0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Registrarse'),
                      ),
                const SizedBox(height: 12),

                const Text(
                  '¿Ya tienes una cuenta?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text('Iniciar sesión', style: TextStyle(color: Color.fromARGB(255, 255, 149, 0)),),
                ),
              ],
            ),
          ),
        )
      )
    ); 
  }
}
