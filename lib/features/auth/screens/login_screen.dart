import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/text_input.dart';
import '../../../core/widgets/inputs/password_text_field.dart';

/// Login screen - Access Account design
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms of Service and Privacy Policy'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await AuthService.instance.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).pushReplacementNamed(result.dashboardRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      // if (googleUser != null) {
      //   // Navigate to the next screen or handle the signed-in user
      //   Navigator.of(context).pushReplacementNamed('/student-dashboard');
      // }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.info,
      body: Column(
        children: [
          // ── Blue header area ──────────────────────────────────
          SizedBox(height: MediaQuery.of(context).padding.top + AppSizes.md),

          // ── White card body ───────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  AppSizes.xl,
                  AppSizes.lg,
                  AppSizes.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title ─────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Access Account',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(height: AppSizes.xs),
                            Text(
                              'Log in to continue your learning journey',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.lg),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: AppSizes.lg),

                      // ── Email Input ───────────────────────────
                      _buildLabel(AppStrings.email),
                      const SizedBox(height: AppSizes.xs),
                      TextInput(
                        controller: _emailController,
                        hint: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        borderColor: AppColors.info,
                        borderRadius: AppSizes.radiusFull,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.fieldRequired;
                          }
                          if (!value.contains('@')) {
                            return AppStrings.invalidEmail;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSizes.md),

                      // ── Password Input ────────────────────────
                      _buildLabel(AppStrings.password),
                      const SizedBox(height: AppSizes.xs),
                      PasswordTextField(
                        controller: _passwordController,
                        hint: 'Enter your password',
                        textInputAction: TextInputAction.done,
                        borderColor: AppColors.info,
                        borderRadius: AppSizes.radiusFull,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.fieldRequired;
                          }
                          if (value.length < 6) {
                            return AppStrings.passwordTooShort;
                          }
                          return null;
                        },
                      ),

                      // ── Forgot Password ───────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.info,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            AppStrings.forgotPassword,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.md),

                      // ── Or sign in with ───────────────────────
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: AppColors.divider),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                            ),
                            child: Text(
                              AppStrings.orSignInWith,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: AppColors.divider),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.lg),

                      // ── Social Buttons ────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialIconButton(
                            onPressed: _handleGoogleSignIn,
                            child: const _GoogleLogo(),
                          ),
                          const SizedBox(width: AppSizes.md),
                          _SocialIconButton(
                            onPressed: () {},
                            child: const _AppleLogo(),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.lg),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: AppSizes.md),

                      // ── Terms Checkbox ────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (v) =>
                                  setState(() => _agreedToTerms = v ?? false),
                              activeColor: AppColors.info,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: AppStrings.termsOfService,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: AppStrings.privacyPolicy,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.xl),

                      // ── Login Button ──────────────────────────
                      PrimaryButton(
                        text: AppStrings.login,
                        onPressed: _agreedToTerms ? _login : null,
                        isLoading: _isLoading,
                        radius: AppSizes.radiusFull,
                        size: ButtonSize.large,
                      ),

                      const SizedBox(height: AppSizes.lg),

                      // ── Sign Up Link ──────────────────────────
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              TextSpan(text: '${AppStrings.noAccount} '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushReplacementNamed('/register'),
                                  child: Text(
                                    AppStrings.signUp,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.md),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.info,
      ),
    );
  }
}

// ── Google Logo ───────────────────────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const FaIcon(
      FontAwesomeIcons.google,
      size: 26,
      color: Color(0xFF4285F4),
    );
  }
}

// ── Apple Logo ────────────────────────────────────────────────────────────────

class _AppleLogo extends StatelessWidget {
  const _AppleLogo();

  @override
  Widget build(BuildContext context) {
    return const FaIcon(FontAwesomeIcons.apple, size: 28, color: Colors.black);
  }
}

// ── Social Icon Button ────────────────────────────────────────────────────────

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: AppColors.info, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
