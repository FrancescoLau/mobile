import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../widgets/review_widget.dart';

class WorkoutDetailPage extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workout.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Descrizione
            Text(
              workout.description,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            // Info principali
            Row(
              children: [
                _infoChip(Icons.access_time, '${workout.duration} min'),
                const SizedBox(width: 8),
                _infoChip(Icons.bar_chart, workout.difficulty),
                const SizedBox(width: 8),
                _infoChip(Icons.person, 'Creato da: ${workout.createdBy}'),
              ],
            ),
            const SizedBox(height: 24),
            // Lista esercizi
            const Text(
              'Esercizi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...workout.exercises
                .map((exercise) => _exerciseCard(exercise))
                .toList(),
            const SizedBox(height: 24),
            // Pulsante recensioni
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ReviewWidget(
                            workoutId: workout.id,
                            showAddReview: true,
                            showStats: true,
                          )),
                );
              },
              icon: const Icon(Icons.rate_review),
              label: const Text('Vedi recensioni'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.deepPurple),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _exerciseCard(Exercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.fitness_center, color: Colors.deepPurple),
        title: Text(exercise.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exercise.description.isNotEmpty) Text(exercise.description),
            Text('Serie: ${exercise.sets}  Ripetizioni: ${exercise.reps}'),
          ],
        ),
      ),
    );
  }
}
