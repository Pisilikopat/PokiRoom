// lib/features/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/poki_theme.dart';
import '../../shared/widgets/poki_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;
  bool _kvkkAccepted = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (nickname.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = 'Lütfen tüm alanları doldur 🐾');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalı 🔐');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _error = 'Girdiğin şifreler eşleşmiyor, lütfen kontrol et! 🐾');
      return;
    }
    if (!_kvkkAccepted) {
      setState(() => _error = 'Devam etmek için KVKK ve Gizlilik Şartlarını kabul etmelisin 📄');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'nickname': nickname},
      );
      if (mounted) {
        setState(() => _success = true);
      }
    } on AuthException catch (e) {
      setState(() => _error = _friendlyError(e.message));
    } catch (_) {
      setState(() => _error = 'Kayıt olunamadı, tekrar dener misin? 🐱');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showKvkkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('📄', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'KVKK & Gizlilik Bilgilendirmesi',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PokiRoom ("Uygulama") olarak gizliliğinize ve kişisel verilerinizin güvenliğine en üst seviyede önem veriyoruz. 6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") kapsamında veri sorumlusu olarak sizleri bilgilendirmek isteriz:\n\n'
                    '🐾 1. İşlenen Veriler:\n'
                    'Kayıt ve kullanım sırasında yalnızca takma adınız (nickname), e-posta adresiniz, şifrelenmiş parolanız, oda içi mesajlaşmalarınız, çizdiğiniz çıkartmalar ve anılarınız işlenmektedir.\n\n'
                    '🐾 2. Verilerin İşlenme Amacı:\n'
                    'Verileriniz yalnızca PokiRoom içerisindeki 1\'e 1 özel iletişimin, çizim odasının ve hatıra panosunun kusursuz çalışması, hesabınızın güvenliği ve anlık bildirimlerin iletilmesi amacıyla kullanılır.\n\n'
                    '🐾 3. Üçüncü Taraflarla Paylaşım:\n'
                    'Kişisel verileriniz ve mesajlarınız asla ticari veya reklam amacıyla kullanılmaz, üçüncü şahıslara veya kurumlara satılmaz ve aktarılmaz.\n\n'
                    '🐾 4. Veri Güvenliği ve Haklarınız:\n'
                    'Tüm verileriniz endüstri standardı şifreleme protokolleriyle korunur. İstediğiniz zaman hesabınızı silebilir ve tüm verilerinizin kalıcı olarak temizlenmesini talep edebilirsiniz.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: PokiColors.text.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() => _kvkkAccepted = true);
                      },
                      child: const Text('Okudum ve Kabul Ediyorum 🐾'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _friendlyError(String msg) {
    if (msg.contains('already registered')) {
      return 'Bu e-posta zaten kayıtlı 📧';
    }
    if (msg.contains('valid email')) {
      return 'Geçerli bir e-posta gir 📧';
    }
    return 'Kayıt hatası: $msg';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_success) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📧', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    'Doğrulama bağlantısı gönderildi!',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'E-postanı kontrol edip bağlantıya tıkladıktan sonra giriş yapabilirsin.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: PokiColors.text.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Giriş Ekranına Dön'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/icons/app_icon.png', width: 76, height: 76),
                ),
                const SizedBox(height: 12),
                Text(
                  'Yeni bir pati izi bırak',
                  style: textTheme.bodyMedium?.copyWith(
                    color: PokiColors.text.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),

                PokiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nicknameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Takma İsim (Nickname)',
                          prefixIcon: Icon(Icons.pets_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Şifre (en az 6 karakter)',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signUp(),
                        decoration: const InputDecoration(
                          hintText: 'Şifre Tekrar',
                          prefixIcon: Icon(Icons.lock_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _kvkkAccepted,
                              activeColor: PokiColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() => _kvkkAccepted = val ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showKvkkSheet,
                              child: RichText(
                                text: TextSpan(
                                  style: textTheme.bodySmall?.copyWith(
                                    color: PokiColors.text.withOpacity(0.8),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'KVKK ve Gizlilik Şartları',
                                      style: TextStyle(
                                        color: PokiColors.primary,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: '\'nı okudum, kabul ediyorum.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
                          onPressed: _loading ? null : _signUp,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: PokiColors.background,
                                  ),
                                )
                              : const Text('Kaydol 🐾'),
                        ),
                      ),
                    ],
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
