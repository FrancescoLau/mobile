import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/screens/review_page.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/review_provider.dart';

class WorkoutDetailPage extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late Workout _currentWorkout;

  @override
  void initState() {
    super.initState();
    _currentWorkout = widget.workout;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentWorkout.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // PULSANTE MODIFICA PER ALLENAMENTI PERSONALI
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              bool canEdit = authProvider.isLoggedIn &&
                  !_currentWorkout.isRecommended &&
                  (_currentWorkout.createdBy == authProvider.currentUserEmail ||
                      _currentWorkout.createdBy.isEmpty ||
                      authProvider.isAdmin);

              if (canEdit) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditWorkoutDialog(context, _currentWorkout);
                  },
                  tooltip: 'Modifica allenamento',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // SEZIONE PRINCIPALE - DURATA E DESCRIZIONE IN EVIDENZA
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Durata in evidenza
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.access_time,
                              color: Colors.deepPurple, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_currentWorkout.duration} minuti',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Descrizione in evidenza
                    const Text(
                      'Descrizione',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentWorkout.description,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(Icons.bar_chart, _currentWorkout.difficulty),
                // Mostra creatore solo se non è vuoto
                if (_currentWorkout.createdBy.isNotEmpty)
                  _infoChip(Icons.person,
                      'Creato da: ${_formatCreator(_currentWorkout.createdBy)}')
                else
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.isLoggedIn &&
                          !_currentWorkout.isRecommended) {
                        return _infoChip(Icons.person,
                            'Creato da: ${_formatCreator(authProvider.currentUserEmail ?? 'Tu')}');
                      }
                      return _infoChip(Icons.person, 'Creato da: Sconosciuto');
                    },
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // SEZIONE ESERCIZI - Solo se presenti
            if (_currentWorkout.exercises.isNotEmpty) ...[
              const Text(
                'Esercizi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._currentWorkout.exercises
                  .map((exercise) => _exerciseCard(exercise))
                  .toList(),
              const SizedBox(height: 24),
            ],

            // PULSANTI AZIONE
            // PULSANTE RECENSIONI - Solo per allenamenti consigliati
            if (_currentWorkout.isRecommended) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewPage(
                              workoutId: _currentWorkout.id,
                              workoutTitle: _currentWorkout.title,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.star),
                      label: const Text('Vedi recensioni'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        if (!authProvider.isLoggedIn)
                          return const SizedBox.shrink();

                        return ElevatedButton.icon(
                          onPressed: () {
                            _showAddReviewDialog(context);
                          },
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Scrivi recensione'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Pulsante elimina per allenamenti personali
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                bool canDelete = authProvider.isLoggedIn &&
                    !_currentWorkout.isRecommended &&
                    (_currentWorkout.createdBy ==
                            authProvider.currentUserEmail ||
                        _currentWorkout.createdBy.isEmpty ||
                        authProvider.isAdmin);

                if (canDelete) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showDeleteConfirmation(context, _currentWorkout);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Elimina allenamento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Metodo per formattare il nome del creatore
  String _formatCreator(String creator) {
    if (creator.contains('@')) {
      return creator.split('@')[0];
    }
    return creator;
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(Exercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fitness_center,
              color: Colors.deepPurple, size: 20),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exercise.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(exercise.description),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text('${exercise.sets} serie'),
                  const SizedBox(width: 16),
                  Text('${exercise.reps} ripetizioni'),
                  if (exercise.duration > 0) ...[
                    const SizedBox(width: 16),
                    Text('${exercise.duration}s'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // METODO CORRETTO PER APRIRE IL DIALOG DI MODIFICA
  void _showEditWorkoutDialog(BuildContext context, Workout workout) async {
    final result = await showDialog<Workout>(
      context: context,
      builder: (context) => EditWorkoutDialog(workout: workout),
    );

    // Se l'allenamento è stato modificato, aggiorna la pagina
    if (result != null) {
      setState(() {
        _currentWorkout = result;
      });
    }
  }

  // METODO CORRETTO PER ELIMINAZIONE CON RITORNO ALLA PAGINA PRECEDENTE
  void _showDeleteConfirmation(BuildContext context, Workout workout) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text(
            'Sei sicuro di voler eliminare l\'allenamento "${workout.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Chiudi il dialog
              Navigator.of(dialogContext).pop();

              try {
                final workoutProvider =
                    Provider.of<WorkoutProvider>(context, listen: false);
                await workoutProvider.deleteWorkout(workout.id);

                // Importante: usa context.mounted per verificare se il widget è ancora attivo
                if (context.mounted) {
                  // Torna alla pagina precedente
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      reviewProvider
          .hasUserReviewed(authProvider.currentUserId ?? '', widget.workout.id)
          .then((hasReviewed) {
        if (hasReviewed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Hai già recensito questo allenamento')),
          );
          return;
        }

        showDialog(
          context: context,
          builder: (context) => AddReviewDialog(
            workoutId: widget.workout.id,
            onReviewAdded: () {
              // You can refresh the page or show a message here if needed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recensione aggiunta con successo!')),
              );
            },
          ),
        );
      });
    });
  }
}

// DIALOG PER LA MODIFICA DEGLI ALLENAMENTI
class EditWorkoutDialog extends StatefulWidget {
  final Workout workout;

  const EditWorkoutDialog({super.key, required this.workout});

  @override
  State<EditWorkoutDialog> createState() => _EditWorkoutDialogState();
}

class _EditWorkoutDialogState extends State<EditWorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late String _selectedDifficulty;
  final List<String> _difficulties = ['Facile', 'Medio', 'Difficile'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.workout.title);
    _descriptionController =
        TextEditingController(text: widget.workout.description);
    _durationController =
        TextEditingController(text: widget.workout.duration.toString());
    _selectedDifficulty = widget.workout.difficulty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifica Allenamento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titolo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un titolo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrizione',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci una descrizione';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Durata (minuti)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Inserisci la durata';
                        }
                        final duration = int.tryParse(value.trim());
                        if (duration == null || duration <= 0) {
                          return 'Inserisci un numero valido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficoltà',
                        border: OutlineInputBorder(),
                      ),
                      items: _difficulties.map((difficulty) {
                        return DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        Consumer<WorkoutProvider>(
          builder: (context, workoutProvider, child) {
            return ElevatedButton(
              onPressed: workoutProvider.isLoading ? null : _saveChanges,
              child: workoutProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salva modifiche'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isLoggedIn || widget.workout.isRecommended) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Non hai i permessi per modificare questo allenamento'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final updatedWorkout = widget.workout.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      duration: int.parse(_durationController.text.trim()),
      difficulty: _selectedDifficulty,
      createdBy: widget.workout.createdBy.isEmpty
          ? authProvider.currentUserEmail ?? ''
          : widget.workout.createdBy,
      exercises: widget.workout.exercises,
    );

    try {
      await workoutProvider.updateWorkout(updatedWorkout);

      if (mounted) {
        Navigator.of(context).pop(updatedWorkout);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Allenamento aggiornato con successo!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'aggiornamento: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
