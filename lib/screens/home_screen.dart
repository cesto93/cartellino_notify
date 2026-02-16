import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/cartellino_service.dart';
import '../theme.dart';
import '../widgets/components.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bgDark, Color(0xFF0F1329)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Consumer<AppState>(
            builder: (context, state, _) {
              return CustomScrollView(
                slivers: [
                  // ── App Bar ──
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.access_time_filled_rounded, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Text('Cartellino'),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
                        onPressed: () => _showSettingsSheet(context, state),
                      ),
                      if (state.status != ShiftStatus.notStarted)
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                          onPressed: () => _confirmReset(context, state),
                        ),
                    ],
                  ),

                  // ── Content ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 12),

                        // Status Badge
                        Center(child: StatusBadge(status: state.status)),
                        const SizedBox(height: 28),

                        // Progress Ring
                        Center(
                          child: ShiftProgressRing(
                            progress: state.progress,
                            status: state.status,
                            centerText: state.endTimeDisplay,
                            subtitle: state.status == ShiftStatus.notStarted
                                ? 'Set start time'
                                : 'shift end',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Remaining time display
                        if (state.remainingDisplay.isNotEmpty)
                          Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                state.remainingDisplay,
                                key: ValueKey(state.remainingDisplay),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),

                        // Info Card
                        GlassCard(
                          child: Column(
                            children: [
                              InfoRow(
                                label: 'Start Time',
                                value: state.startTime ?? '--:--',
                                icon: Icons.login_rounded,
                              ),
                              const Divider(color: AppColors.bgCardLight, height: 20),
                              InfoRow(
                                label: 'Shift End',
                                value: state.endTimeDisplay,
                                icon: Icons.logout_rounded,
                              ),
                              const Divider(color: AppColors.bgCardLight, height: 20),
                              InfoRow(
                                label: 'Liq. Overtime',
                                value: state.liquidatableTimeDisplay,
                                icon: Icons.timer_rounded,
                                valueColor: AppColors.accent,
                              ),
                              if (state.leisureTime != null) ...[
                                const Divider(color: AppColors.bgCardLight, height: 20),
                                InfoRow(
                                  label: 'Leisure Time',
                                  value: state.leisureTime!,
                                  icon: Icons.coffee_rounded,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Notification status
                        if (state.notificationsScheduled)
                          GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.working.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.notifications_active_rounded,
                                      size: 18, color: AppColors.working),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Text(
                                    'Notifications scheduled',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.check_circle_rounded,
                                    size: 18, color: AppColors.working),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Action Buttons
                        _buildActionButtons(context, state),

                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppState state) {
    if (state.status == ShiftStatus.notStarted) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: "I'm Arrived",
              icon: Icons.waving_hand_rounded,
              onPressed: () => state.markArrival(),
              gradient: AppColors.workingGradient,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: 'Set Start Time',
              icon: Icons.edit_calendar_rounded,
              onPressed: () => _showTimeInputDialog(
                context,
                title: 'Set Start Time',
                hint: 'e.g. 08:30',
                onSubmit: (v) => state.setStartTime(v),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GradientButton(
                label: 'Leisure',
                icon: Icons.coffee_rounded,
                onPressed: () => _showTimeInputDialog(
                  context,
                  title: 'Set Leisure Time',
                  hint: 'e.g. 00:15',
                  onSubmit: (v) => state.setLeisureTime(v),
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9B59F7)],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientButton(
                label: 'Work End',
                icon: Icons.info_outline_rounded,
                onPressed: () => _showWorkEndDialog(context, state),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF4FC3F7)],
                ),
              ),
            ),
          ],
        ),
        if (state.leisureTime != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: 'Clear Leisure Time',
              icon: Icons.clear_rounded,
              onPressed: () => state.clearLeisureTime(),
              gradient: const LinearGradient(
                colors: [Color(0xFF455A64), Color(0xFF78909C)],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showTimeInputDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required void Function(String) onSubmit,
  }) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Color(0xFF2A2E4A), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter time in HH:MM format',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                      letterSpacing: 4,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (isValidTimeFormat(value)) {
                      onSubmit(value);
                      Navigator.pop(ctx);
                    }
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Confirm',
                    icon: Icons.check_rounded,
                    onPressed: () {
                      final value = controller.text;
                      if (isValidTimeFormat(value)) {
                        onSubmit(value);
                        Navigator.pop(ctx);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Invalid format. Use HH:MM'),
                            backgroundColor: AppColors.liquidatable,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWorkEndDialog(BuildContext context, AppState state) {
    final endTime = state.endTimeDisplay;
    final remaining = state.remainingDisplay;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.schedule_rounded, size: 48, color: AppColors.accent),
              const SizedBox(height: 16),
              Text(
                'Shift ends at $endTime',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                remaining,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Close',
                  icon: Icons.close_rounded,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0xFF2A2E4A), width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              _SettingsTile(
                icon: Icons.work_rounded,
                label: 'Work Duration',
                value: state.workTime,
                onTap: () {
                  Navigator.pop(ctx);
                  _showTimeInputDialog(
                    context,
                    title: 'Work Duration',
                    hint: '07:12',
                    onSubmit: (v) => state.setWorkTime(v),
                  );
                },
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.restaurant_rounded,
                label: 'Lunch Break',
                value: state.lunchTime,
                onTap: () {
                  Navigator.pop(ctx);
                  _showTimeInputDialog(
                    context,
                    title: 'Lunch Break',
                    hint: '00:30',
                    onSubmit: (v) => state.setLunchTime(v),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _confirmReset(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Reset Day?',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'This will clear your start time and leisure time for today.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                state.resetDay();
                Navigator.pop(ctx);
              },
              child: const Text('Reset', style: TextStyle(color: AppColors.liquidatable)),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
