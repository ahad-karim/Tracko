import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../main.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<StatefulWidget> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  String _selectedCurrency = 'BDT (৳)';
  final List<String> _currencyOptions = ['USD (\$)', 'BDT (৳)'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              const SizedBox(height: 24),
              _buildSectionHeader('PREFERENCES'),
              _buildDarkModeTile(),
              _buildCurrencyTile(),
              const SizedBox(height: 24),
              _buildSectionHeader('NOTIFICATIONS'),
              _buildNotificationTile(),
              const SizedBox(height: 30),
              _buildLogoutButton(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
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
            child: const Icon(Icons.person_rounded,
                size: 38, color: AppColors.deepPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MD. Adnan Hossain',
                    style: AppStyles.headingSmall
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text('adnan@gmail.com', style: AppStyles.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.edit_rounded, color: AppColors.primaryPurple),
            onPressed: () {},
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppStyles.bodySmall.copyWith(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDarkModeTile() {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: AppStyles.borderRadiusMedium,
            border: Border.all(color: AppColors.divider.withOpacity(0.5)),
          ),
          child: SwitchListTile(
            activeColor: AppColors.primaryPurple,
            secondary: const Icon(
              Icons.dark_mode_rounded,
              color: AppColors.deepPurple,
              size: 22,
            ),
            title: Text(
              'Dark Mode ',
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            value: isDarkMode,
            onChanged: (value) {
              isDarkModeNotifier.value = value;
            },
          ),
        );
      },
    );
  }

  Widget _buildCurrencyTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.borderRadiusMedium,
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: const Icon(Icons.attach_money_rounded,
            color: AppColors.deepPurple, size: 22),
        title: Text('Currency Preference',
            style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCurrency,
            style: AppStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.deepPurple),
            items: _currencyOptions.map((currency) {
              return DropdownMenuItem(value: currency, child: Text(currency));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCurrency = value;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.borderRadiusMedium,
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: SwitchListTile(
        activeColor: AppColors.primaryPurple,
        secondary: const Icon(Icons.notifications_none_rounded,
            color: AppColors.deepPurple, size: 22),
        title: Text('Push Notifications',
            style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        value: _pushNotifications,
        onChanged: (value) {
          setState(() {
            _pushNotifications = value;
          });
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _showLogoutDialog,
        icon: const Icon(Icons.logout_rounded, color: AppColors.expenseRed),
        label: Text('Log Out',
            style: AppStyles.buttonText.copyWith(color: AppColors.expenseRed)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.expenseRed, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: AppStyles.borderRadiusMedium),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out of TRACKO?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expenseRed),
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
        );
      },
    );
  }
}
