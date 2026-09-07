import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _biometrics = true;
  bool _pushNotifications = true;
  bool _expenseAlerts = true;
  String _selectedCurrency = 'USD (\$)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: AppStyles.borderRadiusMedium,
                  boxShadow: AppStyles.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.palePurple,
                        border: Border.all(color: AppColors.primaryPurple, width: 2),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 38,
                        color: AppColors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MD. Adnan Hossain',
                            style: AppStyles.headingSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'adnan@gmail.com',
                            style: AppStyles.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.palePurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppColors.primaryPurple),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Preferences Section
              _buildSectionHeader('PREFERENCES'),
              _buildSettingsTile(
                icon: Icons.attach_money_rounded,
                title: 'Currency Preference',
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.deepPurple),
                    items: const [
                      DropdownMenuItem(value: 'USD (\$)', child: Text('USD (\$)')),
                      DropdownMenuItem(value: 'BDT (৳)', child: Text('BDT (৳)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCurrency = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Notifications Section
              _buildSectionHeader('NOTIFICATIONS'),
              _buildSwitchTile(
                icon: Icons.notifications_none_rounded,
                title: 'Push Notifications',
                value: _pushNotifications,
                onChanged: (val) => setState(() => _pushNotifications = val),
              ),

              const SizedBox(height: 32),
              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Log Out'),
                        content: const Text('Are you sure to log out of TRACKO?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            },
                            child: const Text('Log Out'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.expenseRed),
                  label: Text(
                    'Log Out',
                    style: AppStyles.buttonText.copyWith(color: AppColors.expenseRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.expenseRed, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppStyles.borderRadiusMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppStyles.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryPurple,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.borderRadiusMedium,
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.deepPurple, size: 22),
        title: Text(title, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.borderRadiusMedium,
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: SwitchListTile(
        activeColor: AppColors.primaryPurple,
        secondary: Icon(icon, color: AppColors.deepPurple, size: 22),
        title: Text(title, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}