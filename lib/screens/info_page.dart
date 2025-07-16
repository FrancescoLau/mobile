import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informazioni'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),

            // Logo dell'app
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Nome dell'app
            const Text(
              'Workout App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 8),

            // Versione
            const Text(
              'Versione 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 32),

            // Descrizione
            const Text(
              'Un\'applicazione mobile per la gestione di allenamenti e recensioni, sviluppata con Flutter per il corso di Mobile Computing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            // Informazioni tecniche
            _buildInfoCard('Tecnologia', 'Flutter & Dart'),
            _buildInfoCard('Piattaforme', 'Android & iOS'),
            _buildInfoCard('Backend', 'Firebase (configurato)'),
            _buildInfoCard('Architettura', 'Provider Pattern'),

            const SizedBox(height: 24),

            // Informazioni sviluppatore
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Sviluppatore',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Progetto Mobile Computing',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Università',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Copyright
            Text(
              '© 2025 Workout App - Tutti i diritti riservati',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}
