import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  AboutPage({super.key});
  final Uri locationUrl = Uri.parse(
    'https://maps.app.goo.gl/JgkZbnaMTuayXy1K6',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Neutral, non-blue background — the colored header now lives only
      // in the app's shared top bar, so this page doesn't need its own.
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About Us',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Our mission, vision, and where to find us',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                _InfoCard(
                  icon: Icons.flag,
                  iconColor: const Color(0xFFF59E0B), // amber
                  title: 'Mission',
                  body: 'To provide quality education that develops students’ knowledge, skills, creativity, and character for a successful future.',
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  icon: Icons.visibility,
                  iconColor: const Color(0xFF10B981), // emerald
                  title: 'Vision',
                  body: 'To become a center of excellence that inspires students to achieve their full potential and contribute positively to society.',
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  icon: Icons.location_on,
                  iconColor: const Color(0xFFEC4899), // pink
                  title: 'Location',
                  body: 'Bole Sub-City, Woreda 1, Addis Ababa, Ethiopia',
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await launchUrl(locationUrl);
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('View on Google Maps'),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        const Color(0xFFEC4899),
                      ),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      elevation: WidgetStateProperty.resolveWith<double>((
                        states,
                      ) {
                        if (states.contains(WidgetState.pressed)) return 0;
                        return 2;
                      }),
                      shadowColor: WidgetStateProperty.all(
                        const Color(0xFFEC4899).withOpacity(0.4),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
