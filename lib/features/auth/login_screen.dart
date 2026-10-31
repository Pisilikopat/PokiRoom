// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/poki_theme.dart';
import '../../shared/widgets/poki_card.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'E-posta ve şifre boş bırakılamaz 🐾');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      setState(() => _error = _friendlyError(e.message));
    } catch (_) {
      setState(() => _error = 'Bir şeyler ters gitti, tekrar dener misin? 🐱');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String msg) {
    if (msg.contains('Invalid login')) return 'E-posta veya şifre hatalı 🐾';
    if (msg.contains('Email not confirmed')) return 'Lütfen e-postanı doğrula 📧';
    return 'Giriş yapılamadı: $msg';
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool resetLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Text('🔑', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Şifremi Unuttum',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kayıtlı e-posta adresini gir, sana hemen bir şifre sıfırlama bağlantısı gönderelim 🐾',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PokiColors.text.withOpacity(0.7),
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'E-posta adresin',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: resetLoading ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: resetLoading
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lütfen geçerli bir e-posta yaz 🐾')),
                          );
                          return;
                        }

                        setDialogState(() => resetLoading = true);

                        try {
                          await Supabase.instance.client.auth.resetPasswordForEmail(email);
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sıfırlama bağlantısı e-postana gönderildi! 📧'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } on AuthException catch (e) {
                          setDialogState(() => resetLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_friendlyError(e.message))),
                            );
                          }
                        } catch (_) {
                          setDialogState(() => resetLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('E-posta gönderilemedi, tekrar dener misin? 🐱')),
                            );
                          }
                        }
                      },
                child: resetLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Bağlantı Gönder 🐾'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / Başlık
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset('assets/icons/app_icon.png', width: 88, height: 88),
                ),
                const SizedBox(height: 12),
                Text(
                  'PokiRoom',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cebine hoş geldin!',
                  style: textTheme.bodyMedium?.copyWith(
                    color: PokiColors.text.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Kart
                PokiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Giriş Yap',
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'E-posta',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signIn(),
                        decoration: const InputDecoration(
                          hintText: 'Şifre',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Şifremi Unuttum?',
                            style: textTheme.bodySmall?.copyWith(
                              color: PokiColors.primaryButton,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: PokiColors.background,
                                  ),
                                )
                              : const Text('Patile 🐾'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: _goToRegister,
                  child: Text.rich(
                    TextSpan(
                      text: 'Hesabın yok mu? ',
                      children: [
                        TextSpan(
                          text: 'Kayıt Ol',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: PokiColors.primaryButton,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
