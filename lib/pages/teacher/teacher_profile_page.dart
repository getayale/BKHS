import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api_service.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  Map<String, dynamic>? profile;

  bool isLoading = true;
  bool isUploadingPhoto = false;
  bool isChangingPassword = false;

  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController currentPasswordController =
      TextEditingController();

  final TextEditingController newPasswordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscureCurrentPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.getTeacherProfile();

      if (!mounted) return;

      setState(() {
        profile = Map<String, dynamic>.from(data['profile'] ?? {});
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        _showMessage('Photo must be smaller than 5 MB.', isError: true);
        return;
      }

      setState(() {
        isUploadingPhoto = true;
      });

      final data = await ApiService.uploadTeacherProfilePhoto(
        photoBytes: bytes,
        fileName: image.name,
      );

      if (!mounted) return;

      setState(() {
        profile = Map<String, dynamic>.from(data['profile'] ?? {});
        isUploadingPhoto = false;
      });

      _showMessage('Profile photo updated successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploadingPhoto = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please fill in all password fields.', isError: true);
      return;
    }

    if (newPassword.length < 8) {
      _showMessage(
        'New password must be at least 8 characters.',
        isError: true,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage(
        'New password and confirmation do not match.',
        isError: true,
      );
      return;
    }

    setState(() {
      isChangingPassword = true;
    });

    try {
      await ApiService.changeTeacherPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (!mounted) return;

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      setState(() {
        isChangingPassword = false;
      });

      _showMessage('Password changed successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isChangingPassword = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _value(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty) return fallback;

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Profile'), centerTitle: false),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 16),
                    _buildPersonalInformation(),
                    const SizedBox(height: 16),
                    _buildProfessionalInformation(),
                    const SizedBox(height: 16),
                    _buildAddressInformation(),
                    const SizedBox(height: 16),
                    _buildAccountInformation(),
                    const SizedBox(height: 16),
                    _buildPasswordSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final data = profile ?? {};

    final fullName = _value(data['full_name'], fallback: 'Teacher');

    final teacherId = _value(data['teacher_id']);

    final role = _value(data['role'], fallback: 'Teacher');

    final photoUrl = _value(data['photo_url'], fallback: '');

    final initials = _value(data['initials'], fallback: 'T');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.white,
                child: photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildInitials(initials);
                          },
                        ),
                      )
                    : _buildInitials(initials),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: Colors.white,
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.camera_alt_outlined,
                              color: Color(0xFF4F46E5),
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Teacher ID: $teacherId',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the camera button to change your photo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(String initials) {
    return Text(
      initials,
      style: const TextStyle(
        color: Color(0xFF4F46E5),
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildPersonalInformation() {
    final data = profile?['personal'];

    final personal = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};

    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _buildInfoRow(
          Icons.person_outline,
          'Full Name',
          _value(profile?['full_name']),
        ),
        _buildInfoRow(Icons.email_outlined, 'Email', _value(profile?['email'])),
        _buildInfoRow(Icons.phone_outlined, 'Phone', _value(profile?['phone'])),
        _buildInfoRow(Icons.wc_outlined, 'Gender', _value(personal['gender'])),
        _buildInfoRow(
          Icons.calendar_today_outlined,
          'Birth Date',
          _buildBirthDate(personal),
        ),
        _buildInfoRow(
          Icons.favorite_border,
          'Marital Status',
          _value(personal['marital_status']),
        ),
      ],
    );
  }

  String _buildBirthDate(Map<String, dynamic> personal) {
    final year = personal['birth_eth_year'];
    final month = personal['birth_eth_month'];
    final day = personal['birth_eth_day'];

    if (year == null || month == null || day == null) {
      return '-';
    }

    return '$year/$month/$day';
  }

  Widget _buildProfessionalInformation() {
    final data = profile?['professional'];

    final professional = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};

    return _buildSection(
      title: 'Professional Information',
      icon: Icons.work_outline,
      children: [
        _buildInfoRow(
          Icons.school_outlined,
          'Education Level',
          _value(professional['education_level']),
        ),
        _buildInfoRow(
          Icons.account_tree_outlined,
          'Department',
          _value(professional['department']),
        ),
        _buildInfoRow(
          Icons.account_balance_outlined,
          'College / University',
          _value(professional['college_university_institution']),
        ),
      ],
    );
  }

  Widget _buildAddressInformation() {
    final data = profile?['address'];

    final address = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};

    return _buildSection(
      title: 'Address',
      icon: Icons.location_on_outlined,
      children: [
        _buildInfoRow(Icons.map_outlined, 'Region', _value(address['region'])),
        _buildInfoRow(
          Icons.location_city_outlined,
          'Zone',
          _value(address['zone']),
        ),
        _buildInfoRow(Icons.home_outlined, 'Woreda', _value(address['woreda'])),
      ],
    );
  }

  Widget _buildAccountInformation() {
    final data = profile?['account'];

    final account = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};

    return _buildSection(
      title: 'Account Information',
      icon: Icons.manage_accounts_outlined,
      children: [
        _buildInfoRow(
          Icons.badge_outlined,
          'User ID',
          _value(profile?['user_id']),
        ),
        _buildInfoRow(
          Icons.login_outlined,
          'Last Login',
          _value(account['last_login_at']),
        ),
        _buildInfoRow(
          Icons.calendar_month_outlined,
          'Account Created',
          _value(account['created_at']),
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return _buildSection(
      title: 'Change Password',
      icon: Icons.lock_outline,
      children: [
        _buildPasswordField(
          controller: currentPasswordController,
          label: 'Current Password',
          obscureText: obscureCurrentPassword,
          onToggle: () {
            setState(() {
              obscureCurrentPassword = !obscureCurrentPassword;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildPasswordField(
          controller: newPasswordController,
          label: 'New Password',
          obscureText: obscureNewPassword,
          onToggle: () {
            setState(() {
              obscureNewPassword = !obscureNewPassword;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildPasswordField(
          controller: confirmPasswordController,
          label: 'Confirm New Password',
          obscureText: obscureConfirmPassword,
          onToggle: () {
            setState(() {
              obscureConfirmPassword = !obscureConfirmPassword;
            });
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: isChangingPassword ? null : _changePassword,
            icon: isChangingPassword
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_reset),
            label: Text(isChangingPassword ? 'Changing...' : 'Change Password'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
