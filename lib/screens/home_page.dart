import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/review_provider.dart';
import '../models/workout.dart';
import 'workout_detail_page.dart';
import 'login_page.dart';
import 'package:workout_app/screens/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final int _selectedIndex = 0;

  void _showAddWorkoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddWorkoutDialog(),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Caricamento iniziale dei dati
  Future<void> _loadInitialData() async {
    try {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Carica gli allenamenti
      await workoutProvider.loadWorkouts();

      // Imposta lo stato admin se necessario
      if (authProvider.isLoggedIn) {
        workoutProvider.setAdminStatus(authProvider.isAdmin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il caricamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'WorkoutApp',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple,
                      Colors.deepPurple.shade300,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            RecommendedWorkoutsTab(),
            PersonalWorkoutsTab(),
            ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          color: Colors.white,
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.star_rounded),
              text: 'Consigliati',
            ),
            Tab(
              icon: Icon(Icons.fitness_center_rounded),
              text: 'Personali',
            ),
            Tab(
              icon: Icon(Icons.person_rounded),
              text: 'Profilo',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => _showAddWorkoutDialog(context),
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// TAB DEGLI ALLENAMENTI CONSIGLIATI
class RecommendedWorkoutsTab extends StatefulWidget {
  const RecommendedWorkoutsTab({super.key});

  @override
  State<RecommendedWorkoutsTab> createState() => _RecommendedWorkoutsTabState();
}

class _RecommendedWorkoutsTabState extends State<RecommendedWorkoutsTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        if (workoutProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (workoutProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Errore: ${workoutProvider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    workoutProvider.clearError();
                    workoutProvider.loadWorkouts();
                  },
                  child: const Text('Riprova'),
                ),
              ],
            ),
          );
        }

        final workouts = workoutProvider.filteredRecommendedWorkouts;

        return RefreshIndicator(
          onRefresh: () async {
            await workoutProvider.refresh();
          },
          child: Column(
            children: [
              // SEZIONE RICERCA E FILTRI
              _buildSearchAndFilters(context, workoutProvider),

              // LISTA ALLENAMENTI
              Expanded(
                child: workouts.isEmpty
                    ? _buildEmptyState(
                        'Nessun allenamento consigliato trovato',
                        'Prova a modificare i filtri di ricerca',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: workouts.length,
                        itemBuilder: (context, index) {
                          final workout = workouts[index];
                          return Consumer<ReviewProvider>(
                            builder: (context, reviewProvider, child) {
                              final stats =
                                  reviewProvider.getWorkoutStats(workout.id);
                              return _buildWorkoutCard(context, workout,
                                  stats['rating'] ?? 0.0, stats['count'] ?? 0);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkoutCard(
      BuildContext context, Workout workout, double rating, int reviewCount) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: InkWell(
          onTap: () async {
            // NAVIGAZIONE CORRETTA CON GESTIONE DEL RISULTATO
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailPage(workout: workout),
              ),
            );

            // Se l'allenamento è stato eliminato, refresh la lista e forza il rebuild
            if (result == true) {
              await Provider.of<WorkoutProvider>(context, listen: false)
                  .refresh();
              setState(() {}); // Forza il rebuild della tab personale
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workout.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(
                        Icons.access_time_rounded, '${workout.duration} min'),
                    _buildInfoChip(Icons.bar_chart_rounded, workout.difficulty),
                    if (reviewCount > 0) _buildRatingChip(rating, reviewCount),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.deepPurple),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.deepPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChip(double rating, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} ($count)',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
      BuildContext context, WorkoutProvider workoutProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra di ricerca
          TextField(
            decoration: InputDecoration(
              hintText: 'Cerca allenamenti...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: workoutProvider.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        workoutProvider.clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onChanged: (value) {
              workoutProvider.searchWorkouts(value);
            },
          ),

          const SizedBox(height: 12),

          // Filtri
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Difficoltà',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: workoutProvider.selectedDifficulty,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tutte')),
                    DropdownMenuItem(value: 'Facile', child: Text('Facile')),
                    DropdownMenuItem(value: 'Medio', child: Text('Medio')),
                    DropdownMenuItem(
                        value: 'Difficile', child: Text('Difficile')),
                  ],
                  onChanged: (value) {
                    workoutProvider.filterByDifficulty(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  workoutProvider.clearSearch();
                  workoutProvider.clearFilters();
                },
                child: const Text('Reset'),
              ),
            ],
          ),

          // Indicatore ricerca attiva
          if (workoutProvider.searchQuery.isNotEmpty ||
              workoutProvider.selectedDifficulty != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    'Filtri attivi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// TAB DEGLI ALLENAMENTI PERSONALI
class PersonalWorkoutsTab extends StatefulWidget {
  const PersonalWorkoutsTab({super.key});

  @override
  State<PersonalWorkoutsTab> createState() => _PersonalWorkoutsTabState();
}

class _PersonalWorkoutsTabState extends State<PersonalWorkoutsTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<WorkoutProvider, AuthProvider>(
      builder: (context, workoutProvider, authProvider, child) {
        if (workoutProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (workoutProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Errore: ${workoutProvider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    workoutProvider.clearError();
                    workoutProvider.loadWorkouts();
                  },
                  child: const Text('Riprova'),
                ),
              ],
            ),
          );
        }

        final workouts = workoutProvider.filteredPersonalWorkouts;

        return RefreshIndicator(
          onRefresh: () async {
            await workoutProvider.refresh();
          },
          child: Column(
            children: [
              // SEZIONE RICERCA E FILTRI
              _buildSearchAndFilters(context, workoutProvider),

              // LISTA ALLENAMENTI
              Expanded(
                child: workouts.isEmpty
                    ? _buildEmptyState(
                        authProvider.isLoggedIn
                            ? 'Nessun allenamento personale'
                            : 'Accedi per vedere i tuoi allenamenti',
                        authProvider.isLoggedIn
                            ? 'Crea il tuo primo allenamento personalizzato'
                            : 'Effettua il login per gestire i tuoi allenamenti personali',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: workouts.length,
                        itemBuilder: (context, index) {
                          final workout = workouts[index];
                          return _buildPersonalWorkoutCard(context, workout);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalWorkoutCard(BuildContext context, Workout workout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // NAVIGAZIONE CORRETTA CON GESTIONE DEL RISULTATO
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutDetailPage(workout: workout),
            ),
          );

          // Se l'allenamento è stato eliminato, refresh la lista
          if (result == true) {
            Provider.of<WorkoutProvider>(context, listen: false).refresh();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con titolo e badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workout.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Personale',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Descrizione
              Text(
                workout.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _infoChip(Icons.access_time, '${workout.duration} min'),
                      const SizedBox(width: 8),
                      _infoChip(Icons.bar_chart, workout.difficulty),
                    ],
                  ),
                  if (workout.exercises.isNotEmpty)
                    _infoChip(Icons.fitness_center,
                        '${workout.exercises.length} esercizi'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
      BuildContext context, WorkoutProvider workoutProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra di ricerca
          TextField(
            decoration: InputDecoration(
              hintText: 'Cerca nei tuoi allenamenti...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: workoutProvider.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        workoutProvider.clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onChanged: (value) {
              workoutProvider.searchWorkouts(value);
            },
          ),

          const SizedBox(height: 12),

          // Filtri e pulsante aggiungi
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Difficoltà',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: workoutProvider.selectedDifficulty,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tutte')),
                    DropdownMenuItem(value: 'Facile', child: Text('Facile')),
                    DropdownMenuItem(value: 'Medio', child: Text('Medio')),
                    DropdownMenuItem(
                        value: 'Difficile', child: Text('Difficile')),
                  ],
                  onChanged: (value) {
                    workoutProvider.filterByDifficulty(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton.icon(
                    onPressed: authProvider.isLoggedIn
                        ? () {
                            _showAddWorkoutDialog(context);
                          }
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Crea'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),

          // Indicatore ricerca attiva
          if (workoutProvider.searchQuery.isNotEmpty ||
              workoutProvider.selectedDifficulty != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    'Filtri attivi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddWorkoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddWorkoutDialog(),
    );
  }
}

// TAB DEL PROFILO
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Accedi per vedere il tuo profilo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text('Accedi'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar e info utente
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          authProvider.currentUserEmail
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        authProvider.currentUserEmail ?? 'Utente',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (authProvider.isAdmin)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Amministratore',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Statistiche
              Consumer<WorkoutProvider>(
                builder: (context, workoutProvider, child) {
                  final personalWorkouts = workoutProvider.personalWorkouts;
                  final totalWorkouts = personalWorkouts.length;
                  final totalDuration = personalWorkouts.fold<int>(
                    0,
                    (sum, workout) => sum + workout.duration,
                  );

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Le tue statistiche',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Allenamenti',
                                totalWorkouts.toString(),
                                Icons.fitness_center,
                              ),
                              _buildStatItem(
                                'Minuti totali',
                                totalDuration.toString(),
                                Icons.access_time,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Pulsante logout
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    authProvider.logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.deepPurple),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// DIALOG PER AGGIUNGERE ALLENAMENTO
class AddWorkoutDialog extends StatefulWidget {
  const AddWorkoutDialog({super.key});

  @override
  State<AddWorkoutDialog> createState() => _AddWorkoutDialogState();
}

class _AddWorkoutDialogState extends State<AddWorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  String _selectedDifficulty = 'Medio';
  final List<String> _difficulties = ['Facile', 'Medio', 'Difficile'];

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
      title: const Text('Crea Nuovo Allenamento'),
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
              onPressed: workoutProvider.isLoading ? null : _createWorkout,
              child: workoutProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crea'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _createWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devi essere loggato per creare un allenamento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final workout = Workout(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      duration: int.parse(_durationController.text.trim()),
      difficulty: _selectedDifficulty,
      exercises: [],
      isRecommended: false,
      createdAt: DateTime.now(),
      createdBy: authProvider.currentUserEmail ?? '',
    );

    try {
      await workoutProvider.addPersonalWorkout(
        workout,
        userEmail: authProvider.currentUserEmail,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Allenamento creato con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante la creazione: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
