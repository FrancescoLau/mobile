import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'account_details_page.dart';
import 'language_selection_page.dart';
import 'data_management_page.dart';
import 'notification_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Sezione Account
                _buildSectionHeader('Account'),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(authProvider.isAdmin ? 'Admin' : 'Utente'),
                      subtitle: Text(authProvider.isLoggedIn
                          ? 'Connesso'
                          : 'Non connesso'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountDetailsPage(),
                          ),
                        );
                      },
                    );
                  },
                ),

                const Divider(),

                // Sezione App
                _buildSectionHeader('Applicazione'),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifiche'),
                  subtitle: Text(notificationProvider.notificationsEnabled
                      ? 'Abilitate'
                      : 'Disabilitate'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: notificationProvider.notificationsEnabled,
                        activeColor: Colors.deepPurple,
                        onChanged: (bool value) {
                          notificationProvider.setNotificationsEnabled(value);
                        },
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsPage(),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Lingua'),
                  subtitle: const Text('Italiano'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageSelectionPage(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // Sezione Dati
                _buildSectionHeader('Dati'),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Gestione Dati'),
                  subtitle: const Text('Backup e sincronizzazione'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DataManagementPage(),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Pulsante Logout
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isLoggedIn) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            authProvider.logout();
                            Navigator.of(context).pushReplacementNamed('/');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Esci'),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}
