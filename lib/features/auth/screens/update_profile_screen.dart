import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_state.dart';
import '../../../core/services/user_api_service.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/text_input.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fullNameController.text = AuthState.instance.fullName ?? '';
    usernameController.text = AuthState.instance.username ?? '';
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _submitCompleteIdentity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? uploadedUrl;
    if (_selectedImage != null) {
      // Logic for uploading to S3/Cloudinary would go here.
      // For now, we use a placeholder or keep current URL.
      uploadedUrl = AuthState.instance.avatarUrl; 
    }

    if (AppConfig.useMock) {
      AuthState.instance
        ..fullName = fullNameController.text.trim()
        ..username = usernameController.text.trim();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _isLoading = false);
    } else {
      final result = await UserApiService.instance.updateProfile(
        fullName: fullNameController.text.trim(),
        username: usernameController.text.trim(),
        bio: bioController.text.trim(),
        avatarUrl: uploadedUrl,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Something went wrong.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final userData = result.user;
      if (userData != null) {
        AuthState.instance.fullName = userData['full_name']?.toString();
        AuthState.instance.username = userData['username']?.toString();
        AuthState.instance.avatarUrl = userData['avatar_url']?.toString();
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      final role = AuthState.instance.role?.toLowerCase();
      if (role == 'tutor' || role == 'teacher') {
        Navigator.of(context).pushReplacementNamed('/teacher-dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/student-dashboard');
      }
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.info,
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.info,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 50),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Edit Profile',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      
                      // Avatar Picker
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.info, width: 2),
                                  image: _selectedImage != null
                                    ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                    : (AuthState.instance.avatarUrl != null
                                        ? DecorationImage(image: NetworkImage(AuthState.instance.avatarUrl!), fit: BoxFit.cover)
                                        : null),
                                ),
                                child: (_selectedImage == null && AuthState.instance.avatarUrl == null)
                                  ? const Icon(Icons.camera_alt_rounded, color: AppColors.info, size: 32)
                                  : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppColors.info, shape: BoxShape.circle),
                                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.lg),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: AppSizes.lg),
                      _buildLabel('Full Name'),
                      const SizedBox(height: AppSizes.xs),
                      TextInput(
                        controller: fullNameController,
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        borderColor: AppColors.info,
                        borderRadius: AppSizes.radiusLg,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.md),
                      _buildLabel('Username'),
                      const SizedBox(height: AppSizes.xs),
                      TextInput(
                        controller: usernameController,
                        hint: 'Choose a unique username',
                        prefixIcon: Icons.alternate_email_rounded,
                        textInputAction: TextInputAction.next,
                        borderColor: AppColors.info,
                        borderRadius: AppSizes.radiusLg,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.md),
                      _buildLabel('Bio (Optional)'),
                      const SizedBox(height: AppSizes.xs),
                      TextInput(
                        controller: bioController,
                        hint: 'Tell us a bit about yourself',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 3,
                        borderColor: AppColors.info,
                        borderRadius: AppSizes.radiusLg,
                      ),
                      const SizedBox(height: AppSizes.lg),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: AppSizes.xl),
                      PrimaryButton(
                        text: 'Save Changes',
                        onPressed: _submitCompleteIdentity,
                        isLoading: _isLoading,
                        radius: AppSizes.radiusFull,
                        size: ButtonSize.large,
                        backgroundColor: AppColors.info,
                      ),
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
