import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../parent_apiservice.dart';

class ParentProfilePage extends StatefulWidget {
  final String token;

  const ParentProfilePage({super.key, required this.token});

  @override
  State<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
  final ParentApiService _apiService = ParentApiService(
    baseUrl: 'http://localhost/BKHS/api',
  );

  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? parent;

  bool isLoading = true;
  bool isUploadingPhoto = false;
  bool isChangingPassword = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _apiService.getProfile(widget.token);

      if (!mounted) return;

      final profileData = data['data']?['parent'] as Map<String, dynamic>?;

      setState(() {
        parent = profileData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) {
        return;
      }

      final photoSize = await pickedFile.length();

      const maxFileSize = 5 * 1024 * 1024;

      if (photoSize > maxFileSize) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo size must not exceed 5 MB.')),
        );

        return;
      }

      setState(() {
        isUploadingPhoto = true;
      });

      final result = await _apiService.changePhoto(widget.token, pickedFile);

      if (!mounted) return;

      final uploadedPhotoUrl = result['data']?['photo_url']?.toString() ?? '';

      setState(() {
        isUploadingPhoto = false;

        if (parent != null && uploadedPhotoUrl.isNotEmpty) {
          parent = {...parent!, 'photo_url': uploadedPhotoUrl};
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Profile photo updated successfully.',
          ),
        ),
      );

      await loadProfile();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();

    final newPasswordController = TextEditingController();

    final confirmPasswordController = TextEditingController();

    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Update your account password.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrentPassword,
                      enabled: !isChangingPassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setSheetState(() {
                              obscureCurrentPassword = !obscureCurrentPassword;
                            });
                          },
                          icon: Icon(
                            obscureCurrentPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      enabled: !isChangingPassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setSheetState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      enabled: !isChangingPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setSheetState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Password must be at least 6 characters.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isChangingPassword
                            ? null
                            : () async {
                                final currentPassword =
                                    currentPasswordController.text;

                                final newPassword = newPasswordController.text;

                                final confirmPassword =
                                    confirmPasswordController.text;

                                if (currentPassword.isEmpty ||
                                    newPassword.isEmpty ||
                                    confirmPassword.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please fill in all password fields.',
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                if (newPassword != confirmPassword) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Passwords do not match.'),
                                    ),
                                  );

                                  return;
                                }

                                if (newPassword.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password must be at least 6 characters.',
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                setSheetState(() {
                                  isChangingPassword = true;
                                });

                                try {
                                  final result = await _apiService
                                      .changePassword(
                                        widget.token,
                                        currentPassword,
                                        newPassword,
                                        confirmPassword,
                                      );

                                  if (!mounted) {
                                    return;
                                  }

                                  setSheetState(() {
                                    isChangingPassword = false;
                                  });

                                  Navigator.pop(sheetContext);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result['message'] ??
                                            'Password changed successfully.',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) {
                                    return;
                                  }

                                  setSheetState(() {
                                    isChangingPassword = false;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: isChangingPassword
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Change Password'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: RefreshIndicator(onRefresh: loadProfile, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 56),

                    const SizedBox(height: 16),

                    Text(errorMessage!, textAlign: TextAlign.center),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: loadProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (parent == null || parent!.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(child: Text('Parent profile not found.')),
          ),
        ],
      );
    }

    final fullName = parent!['full_name']?.toString() ?? '';

    final email = parent!['email']?.toString() ?? '';

    final phone = parent!['phone']?.toString() ?? '';

    final photoUrl = parent!['photo_url']?.toString() ?? '';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Center(
          child: Stack(
            children: [
              ClipOval(
                child: Container(
                  width: 116,
                  height: 116,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                _getInitials(fullName),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            _getInitials(fullName),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),

              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: Theme.of(context).colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: isUploadingPhoto ? null : _pickAndUploadPhoto,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: isUploadingPhoto
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Center(
          child: Text(
            fullName.isEmpty ? 'Parent' : fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 4),

        Center(
          child: Text(
            'Parent Account',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),

        const SizedBox(height: 30),

        _buildInfoCard(
          icon: Icons.person_outline,
          title: 'Full Name',
          value: fullName,
        ),

        _buildInfoCard(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: phone.isEmpty ? 'Not provided' : phone,
        ),

        _buildInfoCard(
          icon: Icons.email_outlined,
          title: 'Email',
          value: email.isEmpty ? 'Not provided' : email,
        ),

        const SizedBox(height: 16),

        _buildActionTile(
          icon: Icons.photo_camera_outlined,
          title: 'Change Profile Photo',
          subtitle: 'Choose a photo from your phone',
          onTap: isUploadingPhoto ? null : _pickAndUploadPhoto,
          trailing: isUploadingPhoto
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
        ),

        _buildActionTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: isChangingPassword ? null : _showChangePasswordDialog,
          trailing: const Icon(Icons.chevron_right),
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required Widget trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  String _getInitials(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return 'P';
    }

    final parts = trimmedName.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
