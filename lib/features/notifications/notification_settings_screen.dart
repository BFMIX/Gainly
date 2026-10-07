import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/ledger_controller.dart';
import '../../core/domain/notification_preferences.dart';
import '../../localization/formatters.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, required this.controller});

  final LedgerController controller;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationPreferences preferences =
      widget.controller.notificationPreferences;
  bool saving = false;

  Future<void> chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: preferences.reminderMinutes ~/ 60,
        minute: preferences.reminderMinutes % 60,
      ),
    );
    if (selected != null) {
      setState(() {
        preferences = preferences.copyWith(
          reminderMinutes: selected.hour * 60 + selected.minute,
        );
      });
    }
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await widget.controller.saveNotificationPreferences(preferences);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.strings.notificationSettingsSaved)),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.strings.saveError)));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final time = TimeOfDay(
      hour: preferences.reminderMinutes ~/ 60,
      minute: preferences.reminderMinutes % 60,
    );
    return Scaffold(
      appBar: AppBar(title: Text(s.notificationSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SwitchListTile(
            title: Text(s.dailyReminder),
            subtitle: Text(s.dailyReminderHelp),
            value: preferences.dailyReminder,
            onChanged: (value) => setState(
              () => preferences = preferences.copyWith(dailyReminder: value),
            ),
          ),
          ListTile(
            enabled: preferences.dailyReminder,
            title: Text(s.reminderTime),
            trailing: Text(time.format(context)),
            onTap: preferences.dailyReminder ? chooseTime : null,
          ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                s.dailyReminderWebLimitation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              s.importantAlerts,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          SwitchListTile(
            title: Text(s.negativeDaysWarning),
            subtitle: Text(s.negativeDaysWarningHelp),
            value: preferences.negativeDaysWarning,
            onChanged: (value) => setState(
              () => preferences = preferences.copyWith(
                negativeDaysWarning: value,
              ),
            ),
          ),
          SwitchListTile(
            title: Text(s.performanceBalanceWarning),
            subtitle: Text(s.performanceBalanceWarningHelp),
            value: preferences.performanceBalanceWarning,
            onChanged: (value) => setState(
              () => preferences = preferences.copyWith(
                performanceBalanceWarning: value,
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              s.optionalEncouragement,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          SwitchListTile(
            title: Text(s.streakEncouragement),
            value: preferences.streakEncouragement,
            onChanged: (value) => setState(
              () => preferences = preferences.copyWith(
                streakEncouragement: value,
              ),
            ),
          ),
          SwitchListTile(
            title: Text(s.badgeNotifications),
            value: preferences.badgeAchievements,
            onChanged: (value) => setState(
              () =>
                  preferences = preferences.copyWith(badgeAchievements: value),
            ),
          ),
          SwitchListTile(
            title: Text(s.goalProgressNotifications),
            value: preferences.goalProgress,
            onChanged: (value) => setState(
              () => preferences = preferences.copyWith(goalProgress: value),
            ),
          ),
          SwitchListTile(
            title: Text(s.positiveMilestoneNotifications),
            value: preferences.positiveMilestones,
            onChanged: (value) => setState(
              () =>
                  preferences = preferences.copyWith(positiveMilestones: value),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('saveNotificationSettings'),
            onPressed: saving ? null : save,
            child: saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(s.save),
          ),
        ],
      ),
    );
  }
}
