import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../providers/app_state.dart';
import 'admin_screen.dart';
import 'student_screen.dart';
import 'teacher_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  bool mostrarSenha = false;
  bool carregando = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    final email = emailController.text.trim();
    final senha = senhaController.text;
    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o e-mail e a senha.')),
      );
      return;
    }
    setState(() => carregando = true);
    final state = context.read<AppState>();
    await state.initialized;
    if (!mounted) return;
    state.login(email);
    setState(() => carregando = false);

    final destination = switch (state.role) {
      UserRole.professor => const TeacherScreen(),
      UserRole.administrador => const AdminScreen(),
      _ => const StudentScreen(),
    };
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF062846), Color(0xFF174B78), Color(0xFF3478A9)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -80, right: -60, child: _circle(220)),
            Positioned(bottom: -100, left: -70, child: _circle(260)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 85,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'PRESENÇA QR',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sistema Inteligente de Frequência Escolar',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 35),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Bem-vindo!',
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Entre com seus dados institucionais.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 28),
                                  TextField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    enabled: !carregando,
                                    autocorrect: false,
                                    autofillHints: const [AutofillHints.email],
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'E-mail',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 17),
                                  TextField(
                                    controller: senhaController,
                                    obscureText: !mostrarSenha,
                                    textInputAction: TextInputAction.done,
                                    enabled: !carregando,
                                    onSubmitted: carregando
                                        ? null
                                        : (_) => entrar(),
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Senha',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(
                                            () => mostrarSenha = !mostrarSenha,
                                          );
                                        },
                                        icon: Icon(
                                          mostrarSenha
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: carregando
                                          ? null
                                          : _showPasswordRecovery,
                                      child: const Text('Esqueci minha senha'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: FilledButton(
                                      onPressed: carregando ? null : entrar,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF6FAED0,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF062846,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: carregando
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'ENTRAR',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'MODO DEMONSTRAÇÃO • NÃO ARMAZENA SENHAS',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF6FAED0).withValues(alpha: 0.12),
      ),
    );
  }

  void _showPasswordRecovery() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_reset_outlined),
        title: const Text('Recuperação de senha'),
        content: const Text(
          'O acesso está em modo demonstração e não utiliza senhas reais. '
          'Para entrar, use um dos e-mails de demonstração e qualquer senha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDI'),
          ),
        ],
      ),
    );
  }
}
