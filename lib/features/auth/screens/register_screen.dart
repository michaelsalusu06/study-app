import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/social_auth_row.dart';
import '../../../core/widgets/common/auth_form_label.dart';
import '../../../core/widgets/common/terms_checkbox.dart';
import '../../../core/widgets/inputs/password_text_field.dart';
import '../../../core/widgets/inputs/text_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please agree to the Terms of Service and Privacy Policy'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await AuthService.instance.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/update-profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
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
                      Center(
                        child: Column(
                          children: [
                            Text(
                              AppStrings.createAccount,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                              ),
                            ),
                            Text(
                              'Sign up to start your learning journey',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.md),

                      const AuthFormLabel(AppStrings.email),
                      const SizedBox(height: AppSizes.xs),
                      TextInput(
                        controller: _emailController,
                        hint: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        borderColor: AppColors.info,
                        borderRadius: AppSizes.radiusFull,
                        validator: Validators.email,
                      ),

                      const SizedBox(height: AppSizes.md),

                      const AuthFormLabel(AppStrings.password),
                      const SizedBox(height: AppSizes.xs),
                      PasswordTextField(
                        controller: _passwordController,
                        hint: 'Enter your password',
                        textInputAction: TextInputAction.next,
                        borderColor: AppColors.info,
                        borderRadius: AppSizes.radiusFull,
                        validator: Validators.password,
                      ),

                      const SizedBox(height: AppSizes.md),

                      const AuthFormLabel(AppStrings.confirmPassword),
                      const SizedBox(height: AppSizes.xs),
                      PasswordTextField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm your password',
                        textInputAction: TextInputAction.done,
                        borderColor: AppColors.info,
                        borderRadius: AppSizes.radiusFull,
                        validator: (value) => Validators.confirmPassword(
                            value, _passwordController.text),
                      ),

                      const SizedBox(height: AppSizes.xl),

                      Row(
                        children: [
                          const Expanded(
                              child: Divider(color: AppColors.divider)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.md),
                            child: Text(
                              AppStrings.orSignUpWith,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Expanded(
                              child: Divider(color: AppColors.divider)),
                        ],
                      ),

                      const SizedBox(height: AppSizes.lg),

                      SocialAuthRow(
                        onGoogleTap: () {},
                        onAppleTap: () {},
                      ),

                      const SizedBox(height: AppSizes.lg),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: AppSizes.md),

                      TermsCheckbox(
                        value: _acceptTerms,
                        onChanged: (v) =>
                            setState(() => _acceptTerms = v ?? false),
                      ),

                      const SizedBox(height: AppSizes.xl),

                      PrimaryButton(
                        text: AppStrings.register,
                        onPressed: _acceptTerms ? _register : null,
                        isLoading: _isLoading,
                        radius: AppSizes.radiusFull,
                        size: ButtonSize.large,
                      ),

                      const SizedBox(height: AppSizes.lg),

                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              TextSpan(text: '${AppStrings.haveAccount} '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context)
                                      .pushReplacementNamed('/login'),
                                  child: Text(
                                    AppStrings.signIn,
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
}
