import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/ltmo_colors.dart';

// Web Client ID from Google Cloud Console (ltmo-52722) - used so Android/iOS
// issue an ID token whose audience the backend can verify. Must stay equal
// to GOOGLE_CLIENT_ID in the backend .env (the aud claim GoogleAuthController
// checks). Public value - safe to commit.
const String _googleServerClientId =
    '362475867876-v77kbb0udncs1bf90kjprscnfquhljod.apps.googleusercontent.com';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLogin = true;
  late TextEditingController _nameController;
  late TextEditingController _inviteCodeController;
  String? _errorMessage;
  bool _googleSigningIn = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _googleServerClientId,
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
    _inviteCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);

    final hasInviteCode =
        !_isLogin && _inviteCodeController.text.trim().isNotEmpty;

    if (_passwordController.text.isEmpty ||
        (!hasInviteCode && _emailController.text.isEmpty)) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    try {
      final userNotifier = ref.read(userProvider.notifier);

      if (_isLogin) {
        await userNotifier.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        if (_nameController.text.isEmpty) {
          setState(() => _errorMessage = 'Please fill all fields');
          return;
        }

        if (hasInviteCode) {
          await userNotifier.acceptInvite(
            token: _inviteCodeController.text.trim(),
            name: _nameController.text,
            password: _passwordController.text,
            passwordConfirmation: _passwordController.text,
          );
        } else {
          await userNotifier.register(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            passwordConfirmation: _passwordController.text,
          );
        }
      }

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _errorMessage = null;
      _googleSigningIn = true;
    });

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled the sign-in flow.
        setState(() => _googleSigningIn = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        throw 'Impossible de récupérer le jeton Google';
      }

      await ref.read(userProvider.notifier).loginWithGoogle(idToken);

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _googleSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LTMO Mark
              Center(
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ltmo-mark.svg',
                      width: 64,
                      height: 64,
                      colorFilter: const ColorFilter.mode(
                        LtmoColors.encre,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'LTMO',
                      style: AppTypography.headline2.copyWith(
                        color: LtmoColors.encre,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Se connecter' : 'Créer un compte',
                      style: AppTypography.bodyMedium.copyWith(
                        color: LtmoColors.sauge,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              const SizedBox(height: 24),
              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isLogin) ...[
                      Text('Nom complet', style: AppTypography.labelMedium),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('name_field'),
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(
                          hintText: 'Léa Besse',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_isLogin || _inviteCodeController.text.trim().isEmpty) ...[
                      Text('Email', style: AppTypography.labelMedium),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('email_field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        // Password managers like Bitwarden key their
                        // Android-autofill matching primarily off the
                        // "username" hint - offering only `email` is not
                        // always enough for them to recognize this as a
                        // login/signup form, so both are set.
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        decoration: InputDecoration(
                          hintText: 'example@email.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text('Mot de passe', style: AppTypography.labelMedium),
                    const SizedBox(height: 8),
                    TextField(
                      key: ValueKey(_isLogin ? 'password_field_login' : 'password_field_register'),
                      controller: _passwordController,
                      obscureText: true,
                      // Explicit visiblePassword keyboard type is what makes
                      // Android mark this as an actual password input field -
                      // without it, password managers' "suggest strong
                      // password" prompt (triggered by the newPassword hint
                      // below) often doesn't show up on the register form.
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: [
                        _isLogin
                            ? AutofillHints.password
                            : AutofillHints.newPassword,
                      ],
                      onSubmitted: (_) => _handleSubmit(),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Code d\'invitation (optionnel)',
                        style: AppTypography.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Si votre partenaire vous a envoyé un code, entrez-le '
                        'ici pour rejoindre son couple directement.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _inviteCodeController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Code reçu par votre partenaire',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sage,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  TextInput.finishAutofillContext();
                  _handleSubmit();
                },
                child: Text(
                  _isLogin ? 'Se connecter' : 'S\'inscrire',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ou',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.border1),
                ),
                onPressed: _googleSigningIn ? null : _handleGoogleSignIn,
                icon: _googleSigningIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.g_mobiledata, size: 24),
                label: Text(
                  _isLogin
                      ? 'Continuer avec Google'
                      : 'S\'inscrire avec Google',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _errorMessage = null;
                    _nameController.clear();
                    _emailController.clear();
                    _passwordController.clear();
                    _inviteCodeController.clear();
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Pas encore de compte? S\'inscrire'
                      : 'Déjà inscrit? Se connecter',
                  style: const TextStyle(color: AppColors.sage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
