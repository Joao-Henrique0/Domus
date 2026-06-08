import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro inesperado: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _googleSignIn() async {
    const webClientId =
        '1083824003756-3h6pdgovv34im6u2rgjrbk51rl0sfn2j.apps.googleusercontent.com';
    const iosClientId =
        '1083824003756-4drp6t0bivrb203rm37hi96825plgtdc.apps.googleusercontent.com';

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('No Access Token found.');
      }
      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e, s) {
      debugPrint('Erro ao logar: $e');
      debugPrint('Stack: $s');
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao logar com Google: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child:
                  _loading
                      ? const CircularProgressIndicator()
                      : const Text('Entrar'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loading ? null : _googleSignIn,
              icon: const Icon(Icons.login),
              label: const Text("Entrar com Google"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/register');
              },
              child: const Text('Não tem conta? Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}
