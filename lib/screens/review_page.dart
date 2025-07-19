import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/review_provider.dart';
import '../providers/auth_provider.dart';
import '../models/review.dart';

class ReviewPage extends StatefulWidget {
  final String workoutId;
  final String workoutTitle;

  const ReviewPage({
    Key? key,
    required this.workoutId,
    required this.workoutTitle,
  }) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  @override
  void initState() {
    super.initState();
    // Carica le recensioni all'inizializzazione
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ReviewProvider>(context, listen: false)
            .loadWorkoutReviews(widget.workoutId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recensioni ${widget.workoutTitle}'),
        actions: [
          // Pulsante refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ReviewProvider>(context, listen: false)
                  .loadWorkoutReviews(widget.workoutId);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ReviewProvider>(
          builder: (context, reviewProvider, child) {
            // CORREZIONE: Gestione errori del provider
            if (reviewProvider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Errore durante il caricamento',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reviewProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        reviewProvider.clearError();
                        reviewProvider.loadWorkoutReviews(widget.workoutId);
                      },
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              );
            }

            if (reviewProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final reviews = reviewProvider.getWorkoutReviews(widget.workoutId);
            final stats = reviewProvider.getWorkoutStats(widget.workoutId);

            return RefreshIndicator(
              onRefresh: () =>
                  reviewProvider.loadWorkoutReviews(widget.workoutId),
              child: Column(
                children: [
                  // CORREZIONE: Stats card migliorata con nuovo styling
                  _buildStatsCard(context, stats),

                  // CORREZIONE: Lista recensioni con styling migliorato
                  Expanded(
                    child: reviews.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: reviews.length,
                            itemBuilder: (context, index) =>
                                _buildReviewCard(context, reviews[index]),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isLoggedIn) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => _showAddReviewDialog(context),
            icon: const Icon(Icons.rate_review),
            label: const Text('Scrivi recensione'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          );
        },
      ),
    );
  }

  // CORREZIONE: Stats card con nuovo design
  Widget _buildStatsCard(BuildContext context, Map<String, dynamic> stats) {
    final rating = (stats['rating'] as double).toDouble();
    final count = stats['count'] as int;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              // CORREZIONE: Gestione corretta delle stelle decimali
              _buildStarRating(rating, size: 28),
              const SizedBox(height: 8),
              Text(
                count == 1 ? '1 recensione' : '$count recensioni',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CORREZIONE: Widget per stelle con gestione decimali
  Widget _buildStarRating(double rating, {double size = 20}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData iconData;

        if (rating >= starValue) {
          iconData = Icons.star;
        } else if (rating >= starValue - 0.5) {
          iconData = Icons.star_half;
        } else {
          iconData = Icons.star_border;
        }

        return Icon(
          iconData,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessuna recensione',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sii il primo a lasciare una recensione!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  // CORREZIONE: Card recensioni con design migliorato
  Widget _buildReviewCard(BuildContext context, Review review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(
                    review.userEmail.isNotEmpty
                        ? review.userEmail[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatUserEmail(review.userEmail),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        _formatDate(review.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                // CORREZIONE: Stelle con gestione decimali
                _buildStarRating(review.rating.toDouble()),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            // CORREZIONE: Pulsanti azione per l'autore
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // CORREZIONE: Usa currentUserEmail invece di currentUserId
                if (!authProvider.isLoggedIn ||
                    authProvider.currentUserEmail != review.userEmail) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditReviewDialog(context, review),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Modifica'),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () =>
                            _showDeleteConfirmation(context, review),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Elimina'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // CORREZIONE: Formattazione email utente
  String _formatUserEmail(String email) {
    if (email.contains('@')) {
      return email.split('@')[0];
    }
    return email;
  }

  // CORREZIONE: Formattazione data
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} giorni fa';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ore fa';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuti fa';
    } else {
      return 'Adesso';
    }
  }

  void _showAddReviewDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devi essere loggato per lasciare una recensione'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AddReviewDialog(
        workoutId: widget.workoutId,
        onReviewAdded: () {
          // Il provider gestirà automaticamente l'aggiornamento
        },
      ),
    );
  }

  void _showEditReviewDialog(BuildContext context, Review review) {
    showDialog(
      context: context,
      builder: (context) => EditReviewDialog(review: review),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina recensione'),
        content: const Text('Sei sicuro di voler eliminare questa recensione?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final reviewProvider =
                  Provider.of<ReviewProvider>(context, listen: false);
              final success = await reviewProvider.deleteReview(review.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Recensione eliminata con successo'
                          : 'Errore durante l\'eliminazione',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

// CORREZIONE: Dialog per modificare recensioni
class EditReviewDialog extends StatefulWidget {
  final Review review;

  const EditReviewDialog({Key? key, required this.review}) : super(key: key);

  @override
  State<EditReviewDialog> createState() => _EditReviewDialogState();
}

class _EditReviewDialogState extends State<EditReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _commentController;
  late double _rating;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.review.comment);
    _rating = widget.review.rating.toDouble();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Modifica recensione',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rating selector
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Commento',
                border: OutlineInputBorder(),
                hintText: 'Scrivi la tua opinione...',
              ),
              maxLines: 4,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Inserisci un commento';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        Consumer<ReviewProvider>(
          builder: (context, reviewProvider, child) {
            return FilledButton(
              onPressed: reviewProvider.isLoading ? null : _submitEdit,
              child: reviewProvider.isLoading
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

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    // CORREZIONE: Usa updateReview invece di editReview
    final success = await reviewProvider.updateReview(
      widget.review.id,
      _rating,
      _commentController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Recensione modificata con successo!'
                : reviewProvider.errorMessage ?? 'Errore durante la modifica',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

// CORREZIONE: Dialog per aggiungere recensioni
class AddReviewDialog extends StatefulWidget {
  final String workoutId;
  final VoidCallback onReviewAdded;

  const AddReviewDialog({
    Key? key,
    required this.workoutId,
    required this.onReviewAdded,
  }) : super(key: key);

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 5.0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Scrivi recensione',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rating selector
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Commento',
                border: OutlineInputBorder(),
                hintText: 'Condividi la tua esperienza...',
              ),
              maxLines: 4,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Inserisci un commento';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        Consumer<ReviewProvider>(
          builder: (context, reviewProvider, child) {
            return FilledButton(
              onPressed: reviewProvider.isLoading ? null : _submitReview,
              child: reviewProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pubblica'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // CORREZIONE: Parametri corretti per addReview
    final success = await reviewProvider.addReview(
      widget.workoutId,
      authProvider.currentUserEmail ??
          '', // userId può essere derivato dall'email
      authProvider.currentUserEmail ?? '',
      _rating,
      _commentController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();
      widget.onReviewAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Recensione pubblicata con successo!'
                : reviewProvider.errorMessage ??
                    'Errore durante la pubblicazione',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
