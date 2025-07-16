import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

class AccountDetailsPage extends StatelessWidget {
  const AccountDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli Account'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Avatar e info principali
                CircleAvatar(
                  radius: 60,
                  backgroundColor: authProvider.isLoggedIn
                      ? (authProvider.isAdmin
                          ? Colors.orange
                          : Colors.deepPurple)
                      : Colors.grey,
                  child: Icon(
                    authProvider.isLoggedIn
                        ? (authProvider.isAdmin
                            ? Icons.admin_panel_settings
                            : Icons.person)
                        : Icons.person_outline,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // Informazioni account
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informazioni Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Email',
                          authProvider.isLoggedIn
                              ? (authProvider.currentUserEmail ??
                                  'Non disponibile')
                              : 'Non connesso',
                          Icons.email,
                        ),
                        _buildInfoRow(
                          'Tipo Account',
                          authProvider.isLoggedIn
                              ? (authProvider.isAdmin
                                  ? 'Amministratore'
                                  : 'Utente Standard')
                              : 'Utente Ospite',
                          Icons.account_circle,
                        ),
                        _buildInfoRow(
                          'Stato',
                          authProvider.isLoggedIn ? 'Connesso' : 'Disconnesso',
                          Icons.online_prediction,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Statistiche account (solo se admin connesso)
                if (authProvider.isLoggedIn && authProvider.isAdmin)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistiche Amministratore',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow('Allenamenti Creati', '12'),
                          _buildStatRow('Recensioni Moderate', '8'),
                          _buildStatRow('Utenti Attivi', '45'),
                        ],
                      ),
                    ),
                  ),

                // Messaggio per utenti non connessi
                if (!authProvider.isLoggedIn)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            // ← Riga 115: Aggiungi const
                            Icons.info,
                            size: 48,
                            color: Colors.blue,
                          ),
                          SizedBox(height: 16), // ← Riga 116: Aggiungi const
                          Text(
                            // ← Riga 118: Aggiungi const
                            'Accesso Richiesto',
                            style: TextStyle(
                              // ← Riga 119: Aggiungi const
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Effettua l\'accesso per visualizzare i dettagli completi del tuo account e gestire le impostazioni.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Pulsante SOLO per utenti non connessi
                if (!authProvider.isLoggedIn)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Accedi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
// Per utenti loggati: NESSUN PULSANTE viene mostrato
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}
