import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_admin/features/login/view/login_controller.dart';
import 'package:signals_flutter/signals_flutter.dart';

class LoginView extends StatefulWidget {
  final LoginController controller;
  final VoidCallback onLoggedIn;

  const LoginView({
    super.key,
    required this.controller,
    required this.onLoggedIn,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const _darkBrown = Color(0xFF2A1F17);
  static const _mutedText = Color(0xFF998875);
  static const _background = Color(0xFFF5F0EB);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await widget.controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) widget.onLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Abaixo de 900px o painel da marca some e sobra só o formulário.
          final isWide = constraints.maxWidth >= 900;

          return Row(
            children: [
              if (isWide) const Expanded(flex: 5, child: _BrandPanel()),
              Expanded(
                flex: 6,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildForm(showLogo: !isWide),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm({required bool showLogo}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLogo) ...[
            const Align(alignment: Alignment.centerLeft, child: _BrandMark()),
            const SizedBox(height: 32),
          ],
          Text(
            'Bem-vindo de volta',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _darkBrown,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Entre para gerenciar os pedidos da noite.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 32),
          _buildLabel('E-mail'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(hint: 'admin@romeu.com'),
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Informe o e-mail.';
              if (!email.contains('@') || !email.contains('.')) {
                return 'E-mail inválido.';
              }
              return null;
            },
            onChanged: (_) => widget.controller.clearError(),
            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 20),
          _buildLabel('Senha'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: _fieldDecoration(
              hint: '••••••••',
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 19,
                  color: _mutedText,
                ),
                tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
              ),
            ),
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
            validator: (value) =>
                (value ?? '').isEmpty ? 'Informe a senha.' : null,
            onChanged: (_) => widget.controller.clearError(),
            onFieldSubmitted: (_) => _submit(),
          ),
          SignalBuilder(
            builder: (context) {
              final error = widget.controller.errorMessage.value;
              if (error == null) return const SizedBox(height: 28);
              return Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: _ErrorBanner(message: error),
              );
            },
          ),
          SignalBuilder(
            builder: (context) => _SubmitButton(
              isLoading: widget.controller.isLoading.value,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: _darkBrown,
      letterSpacing: 0.2,
    ),
  );

  InputDecoration _fieldDecoration({required String hint, Widget? suffix}) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: _mutedText.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: border(const Color(0xFFE2D9CF)),
      enabledBorder: border(const Color(0xFFE2D9CF)),
      focusedBorder: border(const Color(0xFFEF7B00), 1.6),
      errorBorder: border(const Color(0xFFE23725)),
      focusedErrorBorder: border(const Color(0xFFE23725), 1.6),
      errorStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: const Color(0xFFE23725),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: isLoading
                ? const [Color(0xFFD9836F), Color(0xFFE0A06B)]
                : const [Color(0xFFE23725), Color(0xFFF97316)],
          ),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Entrar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE23725);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF8C2318),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painel esquerdo — só aparece em janela larga.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1F17), Color(0xFFBF360C)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/burguer.webp',
                  width: 132,
                  height: 132,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Romeu Lanches',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFFFB627),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Painel administrativo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
              Text(
                'Pedidos, cardápio e faturamento num lugar só.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFFC9A88B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marca compacta, usada quando o painel esquerdo não cabe.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE23725), Color(0xFFF97316)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            'R',
            style: GoogleFonts.bricolageGrotesque(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Romeu',
              style: GoogleFonts.bricolageGrotesque(
                color: const Color(0xFF2A1F17),
                fontWeight: FontWeight.w700,
                fontSize: 17,
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              'ADMIN',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF998875),
                fontSize: 11,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
