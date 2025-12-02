import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Preencha e-mail e senha.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final auth = ref.read(firebaseAuthProvider);

    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;

      // Volta pro AuthGate (/), que vai mostrar o mapa
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _mapFirebaseError(e);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Erro inesperado. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    final authRepo = ref.read(authRepositoryProvider);

    setState(() => _loading = true);
    try {
      await authRepo.signInWithGoogle();

      if (!mounted) return;
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao entrar com Google: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Informe o e-mail para recuperar a senha.';
      });
      return;
    }

    final auth = ref.read(firebaseAuthProvider);

    try {
      await auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de recuperação enviado.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _mapFirebaseError(e);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Erro ao enviar recuperação.';
      });
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-not-found':
      case 'wrong-password':
        return 'E-mail ou senha incorretos.';
      case 'user-disabled':
        return 'Usuário desativado.';
      default:
        return 'Erro de login: ${e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFE46B3F);
    const bgLight = Color(0xFFF8F6F6);
    const surfaceLight = Color(0xFFFBF9F8);
    const outlineLight = Color(0xFFE6D6D1);
    const placeholderLight = Color(0xFF956350);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 0 : 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          height: 96,
                          width: 96,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.other_houses,
                            color: primary,
                            size: 40,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Bem-vindo(a) de volta!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B120E),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'E-mail',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.brown.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _TextFieldWithIcon(
                        controller: _emailController,
                        hintText: 'Digite seu e-mail',
                        icon: Icons.person,
                        backgroundColor: surfaceLight,
                        outlineColor: outlineLight,
                        placeholderColor: placeholderLight,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Senha
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Senha',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.brown.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PasswordField(
                        controller: _passwordController,
                        backgroundColor: surfaceLight,
                        outlineColor: outlineLight,
                        placeholderColor: placeholderLight,
                      ),

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: const Text(
                            'Esqueci minha senha',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      // Botão Entrar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Entrar'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Divider + botão Google
                      Row(
                        children: const [
                          Expanded(child: Divider(color: outlineLight)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'ou',
                              style: TextStyle(
                                fontSize: 13,
                                color: placeholderLight,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: outlineLight)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _loginWithGoogle,
                          icon: Image.asset(
                            'assets/images/google_logo.png',
                            height: 20,
                          ),
                          label: const Text(
                            'Entrar com Google',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: primary.withOpacity(0.1),
                            side: BorderSide(color: primary.withOpacity(0.2)),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      // Link criar conta
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: const Text(
                          'Ainda não tem uma conta? Criar conta',
                          style: TextStyle(
                            fontSize: 14,
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Campo com ícone à esquerda
class _TextFieldWithIcon extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Color backgroundColor;
  final Color outlineColor;
  final Color placeholderColor;
  final TextInputType? keyboardType;

  const _TextFieldWithIcon({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.backgroundColor,
    required this.outlineColor,
    required this.placeholderColor,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: placeholderColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(color: placeholderColor),
              ),
              style: TextStyle(color: placeholderColor),
              cursorColor: placeholderColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final Color backgroundColor;
  final Color outlineColor;
  final Color placeholderColor;

  const _PasswordField({
    required this.controller,
    required this.backgroundColor,
    required this.outlineColor,
    required this.placeholderColor,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.outlineColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.lock, color: widget.placeholderColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Digite sua senha',
                hintStyle: TextStyle(color: widget.placeholderColor),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _obscure ? Icons.visibility : Icons.visibility_off,
              color: widget.placeholderColor,
            ),
            onPressed: () {
              setState(() {
                _obscure = !_obscure;
              });
            },
          ),
        ],
      ),
    );
  }
}
