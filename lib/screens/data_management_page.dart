import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../providers/review_provider.dart';

class DataManagementPage extends StatelessWidget {
  const DataManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Dati'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Sezione Backup
            _buildSectionCard(
              'Backup Dati',
              'Esegui il backup dei tuoi dati',
              Icons.backup,
              [
                _buildActionTile(
                  'Backup Allenamenti',
                  'Salva i tuoi allenamenti personalizzati',
                  Icons.fitness_center,
                  () => _showBackupDialog(context, 'Allenamenti'),
                ),
                _buildActionTile(
                  'Backup Recensioni',
                  'Salva le tue recensioni e valutazioni',
                  Icons.star,
                  () => _showBackupDialog(context, 'Recensioni'),
                ),
                _buildActionTile(
                  'Backup Completo',
                  'Backup di tutti i tuoi dati',
                  Icons.cloud_upload,
                  () => _showBackupDialog(context, 'Completo'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sezione Sincronizzazione
            _buildSectionCard(
              'Sincronizzazione',
              'Sincronizza i dati tra dispositivi',
              Icons.sync,
              [
                _buildActionTile(
                  'Sincronizza con Cloud',
                  'Sincronizza i dati con il cloud',
                  Icons.cloud_sync,
                  () => _showSyncDialog(context),
                ),
                _buildActionTile(
                  'Ultimo Sync',
                  'Visualizza info ultima sincronizzazione',
                  Icons.history,
                  () => _showLastSyncInfo(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sezione Pulizia
            _buildSectionCard(
              'Pulizia Dati',
              'Gestisci e pulisci i dati locali',
              Icons.cleaning_services,
              [
                _buildActionTile(
                  'Pulisci Cache',
                  'Rimuovi i dati temporanei',
                  Icons.clear_all,
                  () => _showClearCacheDialog(context),
                ),
                _buildActionTile(
                  'Reset Dati',
                  'Ripristina ai dati di default',
                  Icons.restore,
                  () => _showResetDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      String title, String subtitle, IconData icon, List<Widget> actions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...actions,
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _showBackupDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Backup $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Creazione backup $type in corso...'),
          ],
        ),
      ),
    );

    // Simula processo di backup
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // ← CORREZIONE: Rimosso const (interpolazione $type)
            content: Text('Backup $type completato con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sincronizzazione'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sincronizzazione con il cloud in corso...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // ← const OK (nessuna interpolazione)
            content: Text('Sincronizzazione completata!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showLastSyncInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ultima Sincronizzazione'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data: 15 Luglio 2025'),
            Text('Ora: 10:30'),
            Text('Stato: Completata'),
            Text('Elementi sincronizzati: 23'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pulisci Cache'),
        content: const Text(
            'Sei sicuro di voler eliminare tutti i dati temporanei?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    // ← const OK (testo statico)
                    content: Text('Cache pulita con successo!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Pulisci', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Dati'),
        content: const Text(
          'ATTENZIONE: Questa operazione ripristinerà tutti i dati ai valori predefiniti. Tutti i tuoi allenamenti personalizzati e recensioni saranno eliminati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performReset(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performReset(BuildContext context) {
    if (context.mounted) {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);

      // Simula reset dei dati
      workoutProvider.clearSearch();
      reviewProvider.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          // ← const OK (testo statico)
          content: Text('Dati ripristinati ai valori predefiniti!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
