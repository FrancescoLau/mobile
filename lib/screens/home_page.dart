import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/review_provider.dart';
import '../models/workout.dart';
import '../screens/settings_page.dart';
import '../screens/help_page.dart';
import '../screens/info_page.dart';
import '../screens/workout_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    workoutProvider.loadWorkouts();
  }

  List<Widget> get _pages => [
        const RecommendedWorkoutsTab(),
        const PersonalWorkoutsTab(),
        ProfileTab(onLogout: _handleLogout),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Workout App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.isLoggedIn) {
                return IconButton(
                  icon: const Icon(Icons.login),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    ).then((_) => _loadInitialData());
                  },
                );
              }

              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor:
                      authProvider.isAdmin ? Colors.orange : Colors.deepPurple,
                  child: Icon(
                    authProvider.isAdmin
                        ? Icons.admin_panel_settings
                        : Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.currentUserEmail ?? 'Utente',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          authProvider.isAdmin ? 'Amministratore' : 'Utente',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.recommend),
            label: 'Consigliati',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'I Miei',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 1
          ? Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return FloatingActionButton(
                  onPressed: () {
                    if (authProvider.isLoggedIn) {
                      _showAddPersonalWorkoutDialog(context);
                    } else {
                      _showLoginRequiredDialog(context);
                    }
                  },
                  tooltip: 'Aggiungi Allenamento',
                  child: const Icon(Icons.add),
                );
              },
            )
          : null,
    );
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    await authProvider.logout();

    workoutProvider.clearSearch();
    reviewProvider.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout effettuato con successo'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const SearchDialog();
      },
    );
  }

  void _showAddPersonalWorkoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddWorkoutDialog(isRecommended: false);
      },
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accesso Richiesto'),
          content: const Text(
              'Devi effettuare l\'accesso per creare allenamenti personalizzati.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ).then((_) => _loadInitialData());
              },
              child: const Text('Accedi'),
            ),
          ],
        );
      },
    );
  }
}

// Tab per allenamenti consigliati
class RecommendedWorkoutsTab extends StatelessWidget {
  const RecommendedWorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Allenamenti Consigliati',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isAdmin) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        _showAddRecommendedWorkoutDialog(context);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Aggiungi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<WorkoutProvider>(
              builder: (context, workoutProvider, child) {
                if (workoutProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (workoutProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 80, color: Colors.red),
                        const SizedBox(height: 20),
                        Text(
                          'Errore: ${workoutProvider.errorMessage}',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
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

                final recommendedWorkouts = workoutProvider.recommendedWorkouts;

                if (recommendedWorkouts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          'Nessun allenamento consigliato disponibile',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => workoutProvider.refresh(),
                  child: ListView.builder(
                    itemCount: recommendedWorkouts.length,
                    itemBuilder: (context, index) {
                      final workout = recommendedWorkouts[index];
                      return Consumer<ReviewProvider>(
                        builder: (context, reviewProvider, child) {
                          final averageRating =
                              reviewProvider.getAverageRating(workout.id);
                          final reviews =
                              reviewProvider.getWorkoutReviews(workout.id);

                          return _buildWorkoutCard(
                              context, workout, averageRating, reviews.length);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRecommendedWorkoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddWorkoutDialog(isRecommended: true);
      },
    );
  }

  Widget _buildWorkoutCard(
      BuildContext context, Workout workout, double rating, int reviewCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutDetailPage(workout: workout),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDifficultyIcon(workout.difficulty),
                      color: Colors.deepPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          workout.description,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(Icons.access_time, '${workout.duration} min'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.bar_chart, workout.difficulty),
                  const SizedBox(width: 8),
                  if (reviewCount > 0) _buildRatingChip(rating, reviewCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Icons.star;
      case 'medio':
        return Icons.favorite;
      case 'difficile':
        return Icons.fitness_center;
      default:
        return Icons.help;
    }
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRatingChip(double rating, int reviewCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} ($reviewCount)',
            style: const TextStyle(
                fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// Tab per allenamenti personali
class PersonalWorkoutsTab extends StatelessWidget {
  const PersonalWorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'I Miei Allenamenti',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (!authProvider.isLoggedIn) {
                  return _buildGuestContent(context);
                }

                return Consumer<WorkoutProvider>(
                  builder: (context, workoutProvider, child) {
                    if (workoutProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final personalWorkouts = workoutProvider.personalWorkouts;

                    if (personalWorkouts.isEmpty) {
                      return _buildEmptyContent(context, authProvider);
                    }

                    return RefreshIndicator(
                      onRefresh: () => workoutProvider.refresh(),
                      child: ListView.builder(
                        itemCount: personalWorkouts.length,
                        itemBuilder: (context, index) {
                          final workout = personalWorkouts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: const Icon(Icons.fitness_center,
                                  color: Colors.deepPurple),
                              title: Text(workout.title),
                              subtitle: Text(
                                  '${workout.duration} min - ${workout.difficulty}'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        WorkoutDetailPage(workout: workout),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(BuildContext context, AuthProvider authProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'Benvenuto, ${authProvider.currentUserEmail?.split('@')[0] ?? 'Utente'}!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Non hai ancora creato allenamenti personalizzati',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tocca il pulsante + per creare\nil tuo primo allenamento',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) =>
                    const AddWorkoutDialog(isRecommended: false),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Crea Allenamento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Accesso Richiesto',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Effettua l\'accesso per creare e gestire\ni tuoi allenamenti personalizzati',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('Accedi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Tab per il profilo
class ProfileTab extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfileTab({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: authProvider.isLoggedIn
                    ? (authProvider.isAdmin ? Colors.orange : Colors.deepPurple)
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
              Text(
                authProvider.isLoggedIn
                    ? (authProvider.currentUserEmail?.split('@')[0] ?? 'Utente')
                    : 'Utente Ospite',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                authProvider.isLoggedIn
                    ? (authProvider.isAdmin
                        ? 'Amministratore'
                        : 'Utente Registrato')
                    : 'Accedi per sincronizzare i tuoi allenamenti',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: authProvider.isLoggedIn
                    ? ElevatedButton.icon(
                        onPressed: authProvider.isLoading ? null : onLogout,
                        icon: authProvider.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                          );
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Accedi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              _buildProfileOption(Icons.settings, 'Impostazioni', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              }),
              _buildProfileOption(Icons.help, 'Aiuto', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpPage()),
                );
              }),
              _buildProfileOption(Icons.info, 'Informazioni', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InfoPage()),
                );
              }),
              if (authProvider.isAdmin) ...[
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Funzioni Amministratore',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                ),
                const SizedBox(height: 10),
                _buildProfileOption(Icons.people, 'Gestione Utenti', () {}),
                _buildProfileOption(
                    Icons.fitness_center, 'Gestione Allenamenti', () {}),
                _buildProfileOption(
                    Icons.star, 'Moderazione Recensioni', () {}),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}

// Dialog per la ricerca
class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final _searchController = TextEditingController();
  String _selectedDifficulty = 'Tutte';
  final List<String> _difficulties = ['Tutte', 'Facile', 'Medio', 'Difficile'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ricerca Allenamenti'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Cerca per titolo o descrizione',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        Consumer<WorkoutProvider>(
          builder: (context, workoutProvider, child) {
            return ElevatedButton(
              onPressed: workoutProvider.isLoading
                  ? null
                  : () {
                      _performSearch();
                      Navigator.of(context).pop();
                    },
              child: workoutProvider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Cerca'),
            );
          },
        ),
      ],
    );
  }

  void _performSearch() {
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      workoutProvider.searchWorkouts(query);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ricerca per "$query" completata')),
      );
    }

    if (_selectedDifficulty != 'Tutte') {
      workoutProvider.filterByDifficulty(_selectedDifficulty);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Filtro per difficoltà "$_selectedDifficulty" applicato')),
      );
    }
  }
}

// Dialog per aggiungere allenamenti
class AddWorkoutDialog extends StatefulWidget {
  final bool isRecommended;

  const AddWorkoutDialog({super.key, required this.isRecommended});

  @override
  State<AddWorkoutDialog> createState() => _AddWorkoutDialogState();
}

class _AddWorkoutDialogState extends State<AddWorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  String _selectedDifficulty = 'Facile';
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
      title: Text(widget.isRecommended
          ? 'Nuovo Allenamento Consigliato'
          : 'Nuovo Allenamento Personale'),
      content: Form(
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
                if (value == null || value.isEmpty) {
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
                if (value == null || value.isEmpty) {
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
                      if (value == null || value.isEmpty) {
                        return 'Inserisci la durata';
                      }
                      if (int.tryParse(value) == null) {
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        Consumer<WorkoutProvider>(
          builder: (context, workoutProvider, child) {
            return ElevatedButton(
              onPressed: workoutProvider.isLoading ? null : _saveWorkout,
              child: workoutProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salva'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    final newWorkout = Workout(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      difficulty: _selectedDifficulty,
      duration: int.parse(_durationController.text),
      exercises: [],
      createdBy: '',
      isRecommended: widget.isRecommended,
      createdAt: DateTime.now(),
    );

    bool success;
    if (widget.isRecommended) {
      success = await workoutProvider.createRecommendedWorkout(newWorkout);
    } else {
      success = await workoutProvider.createPersonalWorkout(newWorkout);
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isRecommended
                ? 'Allenamento consigliato creato con successo!'
                : 'Allenamento personale creato con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                workoutProvider.errorMessage ?? 'Errore durante la creazione'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
