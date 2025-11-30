import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_providers.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _acceptedTerms = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithGoogle() async {
    final authRepo = ref.read(authRepositoryProvider);

    setState(() => _loading = true);
    try {
      await authRepo.signInWithGoogle();

      if (!mounted) return;
      // Depois do login/cadastro com Google,
      // o AuthGate vai detectar o usuário logado e mandar pro mapa
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar conta com Google: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() {
        _errorMessage = 'Preencha todos os campos.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'A senha deve ter pelo menos 6 caracteres.';
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _errorMessage = 'As senhas não coincidem.';
      });
      return;
    }

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Você precisa aceitar os Termos de uso.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final auth = ref.read(firebaseAuthProvider);

    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user?.updateDisplayName(name);

      if (!mounted) return;

      // Volta pro AuthGate, que detecta user logado e mostra o mapa
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _mapFirebaseError(e);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Erro ao criar conta. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Já existe uma conta com esse e-mail.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'Senha fraca.';
      default:
        return 'Erro: ${e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFE46B3F);
    const bgLight = Color(0xFFF8F6F6);
    const outlineLight = Color(0xFFE6D6D1);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Logo
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.maps_home_work,
                  color: primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Crie sua conta',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B120E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bem-vindo! Insira seus dados abaixo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              _LabeledField(
                label: 'Nome',
                controller: _nameController,
                hintText: 'Digite seu nome completo',
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'E-mail',
                controller: _emailController,
                hintText: 'Digite seu e-mail',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _LabeledPasswordField(
                label: 'Senha',
                controller: _passwordController,
                hintText: 'Crie uma senha',
              ),
              const SizedBox(height: 16),
              _LabeledPasswordField(
                label: 'Confirmar senha',
                controller: _confirmController,
                hintText: 'Confirme sua senha',
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (v) {
                      setState(() {
                        _acceptedTerms = v ?? false;
                      });
                    },
                    activeColor: primary,
                  ),
                  const Expanded(
                    child: Text(
                      'Concordo com os Termos de uso',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
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

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                      : const Text('Criar conta'),
                ),
              ),

              const SizedBox(height: 16),

              // divisor "ou"
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: outlineLight.withOpacity(0.7),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'ou',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: outlineLight.withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Botão "Criar conta com Google"
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _signUpWithGoogle,
                  icon: Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    height: 20,
                  ),
                  label: const Text(
                    'Criar conta com Google',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: primary.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'Já tem conta? Entrar',
                  style: TextStyle(
                    fontSize: 14,
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Container(
                height: 1,
                color: outlineLight.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    const outlineLight = Color(0xFFE6D6D1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1B120E),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: outlineLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE46B3F)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;

  const _LabeledPasswordField({
    required this.label,
    required this.controller,
    required this.hintText,
  });

  @override
  State<_LabeledPasswordField> createState() => _LabeledPasswordFieldState();
}

class _LabeledPasswordFieldState extends State<_LabeledPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    const outlineLight = Color(0xFFE6D6D1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1B120E),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscure = !_obscure;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: outlineLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE46B3F)),
            ),
          ),
        ),
      ],
    );
  }
}
