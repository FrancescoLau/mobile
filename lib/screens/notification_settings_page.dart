import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni Notifiche'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notifiche generali
                _buildSectionHeader('Notifiche Generali'),
                Card(
                  child: SwitchListTile(
                    title: const Text('Abilita Notifiche'),
                    subtitle:
                        const Text('Attiva o disattiva tutte le notifiche'),
                    value: notificationProvider.notificationsEnabled,
                    activeColor: Colors.deepPurple,
                    onChanged: (bool value) {
                      notificationProvider.setNotificationsEnabled(value);
                    },
                    secondary: const Icon(Icons.notifications),
                  ),
                ),

                const SizedBox(height: 20),

                // Notifiche specifiche
                if (notificationProvider.notificationsEnabled) ...[
                  _buildSectionHeader('Tipi di Notifiche'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Promemoria Allenamenti'),
                          subtitle: const Text(
                              'Ricordati di completare gli allenamenti'),
                          value: notificationProvider.workoutReminders,
                          activeColor: Colors.deepPurple,
                          onChanged: (bool value) {
                            notificationProvider.setWorkoutReminders(value);
                          },
                          secondary: const Icon(Icons.fitness_center),
                        ),

                        const Divider(),

                        SwitchListTile(
                          title: const Text('Notifiche Recensioni'),
                          subtitle: const Text(
                              'Nuove recensioni sui tuoi allenamenti'),
                          value: notificationProvider.reviewNotifications,
                          activeColor: Colors.deepPurple,
                          onChanged: (bool value) {
                            notificationProvider.setReviewNotifications(value);
                          },
                          secondary: const Icon(Icons.star),
                        ),

                        const Divider(),

                        // Notifiche admin
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            if (authProvider.isAdmin) {
                              return SwitchListTile(
                                title: const Text('Notifiche Amministratore'),
                                subtitle:
                                    const Text('Gestione utenti e contenuti'),
                                value: notificationProvider.adminNotifications,
                                activeColor: Colors.orange,
                                onChanged: (bool value) {
                                  notificationProvider
                                      .setAdminNotifications(value);
                                },
                                secondary:
                                    const Icon(Icons.admin_panel_settings),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Sezione test
                _buildSectionHeader('Test e Ripristino'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.send),
                        title: const Text('Test Notifiche'),
                        subtitle:
                            const Text('Verifica che le notifiche funzionino'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _sendTestNotification(context, notificationProvider);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.restore),
                        title: const Text('Ripristina Impostazioni'),
                        subtitle:
                            const Text('Riporta alle impostazioni predefinite'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showResetDialog(context, notificationProvider);
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Informazione
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Le notifiche richiedono i permessi del dispositivo. Assicurati di averli abilitati nelle impostazioni di sistema.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  void _sendTestNotification(
      BuildContext context, NotificationProvider provider) {
    if (provider.notificationsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notifica: Le notifiche sono abilitate!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le notifiche sono disabilitate'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showResetDialog(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ripristina Impostazioni'),
        content: const Text(
          'Sei sicuro di voler ripristinare tutte le impostazioni di notifica ai valori predefiniti?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Impostazioni ripristinate!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );
  }
}
