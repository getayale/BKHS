import 'package:flutter/material.dart';

import '/pages/teacher/take_attendance_page.dart';
import '/pages/teacher/edit_attendance_page.dart';
import 'attendance_report.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  int selectedTab = 0;

  final List<String> tabs = ['TAKE', 'EDIT', 'HISTORY'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedTab == index;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 6),
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedTab == index) {
                      return;
                    }

                    setState(() {
                      selectedTab = index;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade200,
                    foregroundColor: isSelected ? Colors.white : Colors.black87,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    tabs[index],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case 0:
        return const TakeAttendancePage();

      case 1:
        return const EditAttendancePage();

      case 2:
        return const AttendanceReportPage();

      default:
        return const SizedBox.shrink();
    }
  }
}
