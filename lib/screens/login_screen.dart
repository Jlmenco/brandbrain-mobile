import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await context.read<AuthProvider>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: kErrorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // Logo
                  _Logo(),

                  const SizedBox(height: 40),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Entrar na sua conta',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: kTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              hintText: 'seu@email.com',
                              prefixIcon: Icon(Icons.email_outlined, color: kTextMuted),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o e-mail';
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'E-mail inválido';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outlined, color: kTextMuted),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: kTextMuted,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe a senha';
                              }
                              if (value.length < 6) {
                                return 'Senha deve ter ao menos 6 caracteres';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Submit button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Text(
                    'Brand Brain © ${DateTime.now().year}',
                    style: const TextStyle(
                      color: kTextMuted,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Purple BB box
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'BB',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // App name
        const Text(
          'Brand Brain',
          style: TextStyle(
            color: kTextColor,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 6),

        // Subtitle
        const Text(
          'Sistema de Inteligência de Marca',
          style: TextStyle(
            color: kTextSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
