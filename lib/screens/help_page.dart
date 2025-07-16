import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aiuto'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildHelpSection(
              'Come iniziare',
              'Effettua il login con le tue credenziali per accedere agli allenamenti e alle recensioni.',
              Icons.login,
            ),

            _buildHelpSection(
              'Gestione Allenamenti',
              'Visualizza gli allenamenti disponibili e, se sei un admin, puoi crearne di nuovi.',
              Icons.fitness_center,
            ),

            _buildHelpSection(
              'Sistema Recensioni',
              'Puoi aggiungere recensioni agli allenamenti e visualizzare quelle di altri utenti.',
              Icons.star_rate,
            ),

            _buildHelpSection(
              'Credenziali di Test',
              'Admin: admin@workout.com / admin123\nUtente: user@workout.com / user123',
              Icons.account_circle,
            ),

            const SizedBox(height: 24),

            // Sezione FAQ
            const Text(
              'Domande Frequenti',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 16),

            _buildFAQItem(
              'Come posso creare un nuovo allenamento?',
              'Solo gli utenti admin possono creare nuovi allenamenti. Effettua il login come admin e usa il pulsante "+" nella schermata principale.',
            ),

            _buildFAQItem(
              'Come posso aggiungere una recensione?',
              'Vai ai dettagli di un allenamento e clicca su "Vedi recensioni", poi "Scrivi una recensione".',
            ),

            _buildFAQItem(
              'L\'app funziona offline?',
              'L\'app utilizza dati mock locali, quindi funziona anche senza connessione internet.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.deepPurple, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
