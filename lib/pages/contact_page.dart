import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  ContactPage({super.key});

  final Uri locationUrl = Uri.parse(
    'https://maps.app.goo.gl/JgkZbnaMTuayXy1K6',
  );

  final Uri phoneUrl = Uri.parse('tel:+251911000000');

  final Uri emailUrl = Uri.parse('mailto:info@bolekalehiwot.edu.et');

  final Uri websiteUrl = Uri.parse('https://www.bolekalehiwot.edu.et');

  Future<void> openUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Neutral background — the colored header lives only in the app's
      // shared top bar, so this page doesn't need its own.
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Us',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Get in touch with Bole Kale Hiwot School.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                _contactCard(
                  icon: Icons.phone,
                  iconColor: const Color(0xFF0D9488), // teal
                  title: 'Phone',
                  value: '+251 911 000 000',
                  onTap: () => openUrl(phoneUrl),
                ),

                const SizedBox(height: 14),

                _contactCard(
                  icon: Icons.email,
                  iconColor: const Color(0xFFF59E0B), // amber
                  title: 'Email',
                  value: 'info@bolekalehiwot.edu.et',
                  onTap: () => openUrl(emailUrl),
                ),

                const SizedBox(height: 14),

                _contactCard(
                  icon: Icons.location_on,
                  iconColor: const Color(0xFFEC4899), // pink
                  title: 'Address',
                  value: 'Bole Sub-City, Woreda 1, Addis Ababa, Ethiopia',
                  onTap: () => openUrl(locationUrl),
                ),

                const SizedBox(height: 14),

                _contactCard(
                  icon: Icons.language,
                  iconColor: const Color(0xFF10B981), // emerald
                  title: 'Website',
                  value: 'www.bolekalehiwot.edu.et',
                  onTap: () => openUrl(websiteUrl),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => openUrl(locationUrl),
                    icon: const Icon(Icons.map),
                    label: const Text(
                      'View School Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF065F46), // deep emerald
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0xFF065F46).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7E5E4), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1C1917).withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
