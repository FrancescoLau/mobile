// lib/widgets/review_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/review.dart';
import '../providers/review_provider.dart';
import '../providers/auth_provider.dart';

class ReviewWidget extends StatefulWidget {
  final String workoutId;
  final bool showAddReview;
  final bool showStats;

  const ReviewWidget({
    Key? key,
    required this.workoutId,
    this.showAddReview = true,
    this.showStats = true,
  }) : super(key: key);

  @override
  State<ReviewWidget> createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    reviewProvider.loadWorkoutReviews(widget.workoutId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showStats) _buildStatsSection(),
        if (widget.showAddReview) _buildAddReviewSection(),
        const SizedBox(height: 16),
        _buildReviewsList(),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: reviewProvider.getWorkoutReviewStats(widget.workoutId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Text('Nessuna statistica disponibile');
            }

            final stats = snapshot.data!;
            final totalReviews = stats['totalReviews'] as int;
            final averageRating = stats['averageRating'] as double;
            final ratingDistribution =
                stats['ratingDistribution'] as Map<int, int>;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($totalReviews recensioni)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (totalReviews > 0)
                      ...List.generate(5, (index) {
                        final rating = 5 - index;
                        final count = ratingDistribution[rating] ?? 0;
                        final percentage = totalReviews > 0
                            ? (count / totalReviews) * 100
                            : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text('$rating'),
                              const SizedBox(width: 4),
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[300],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.amber),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$count'),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddReviewSection() {
    return Consumer2<ReviewProvider, AuthProvider>(
      builder: (context, reviewProvider, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Accedi per lasciare una recensione'),
            ),
          );
        }

        return FutureBuilder<bool>(
          future: reviewProvider.hasUserReviewed(
            authProvider.currentUserId ?? '',
            widget.workoutId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final hasReviewed = snapshot.data ?? false;

            if (hasReviewed) {
              return FutureBuilder<Review?>(
                future: reviewProvider.getUserReviewForWorkout(
                  authProvider.currentUserId ?? '',
                  widget.workoutId,
                ),
                builder: (context, reviewSnapshot) {
                  if (reviewSnapshot.hasData) {
                    final existingReview = reviewSnapshot.data!;
                    return _buildEditReviewCard(existingReview);
                  }
                  return const SizedBox();
                },
              );
            }

            return _buildAddReviewCard();
          },
        );
      },
    );
  }

  Widget _buildAddReviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aggiungi una recensione',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildRatingSelector(),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Commento',
                hintText:
                    'Descrivi la tua esperienza con questo allenamento...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Pubblica Recensione'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditReviewCard(Review existingReview) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'La tua recensione',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editReview(existingReview),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteReview(existingReview.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStarRating(existingReview.rating),
            const SizedBox(height: 8),
            Text(existingReview.comment),
            const SizedBox(height: 8),
            Text(
              'Pubblicata ${existingReview.formattedDate}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valutazione',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1.0;
            return GestureDetector(
              onTap: () => setState(() => _rating = starValue),
              child: Icon(
                _rating >= starValue ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          _getRatingText(_rating),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return Icon(
          rating >= starValue ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildReviewsList() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        final reviews = reviewProvider.getWorkoutReviews(widget.workoutId);

        if (reviewProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reviews.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nessuna recensione ancora disponibile'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recensioni (${reviews.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...reviews.map((review) => _buildReviewCard(review)),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(review.userEmail[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userEmail,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        review.formattedDate,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildStarRating(review.rating),
              ],
            ),
            const SizedBox(height: 12),
            Text(review.comment),
            const SizedBox(height: 8),
            _buildReviewActions(review),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewActions(Review review) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) return const SizedBox();

        final isCurrentUser = authProvider.currentUserId == review.userId;
        final isAdmin = authProvider.isAdmin;

        if (!isCurrentUser && !isAdmin) return const SizedBox();

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isCurrentUser) ...[
              TextButton(
                onPressed: () => _editReview(review),
                child: const Text('Modifica'),
              ),
              TextButton(
                onPressed: () => _deleteReview(review.id),
                child: const Text('Elimina'),
              ),
            ],
            if (isAdmin && !isCurrentUser) ...[
              TextButton(
                onPressed: () => _moderateReview(review.id, !review.isHidden),
                child: Text(review.isHidden ? 'Mostra' : 'Nascondi'),
              ),
            ],
          ],
        );
      },
    );
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Pessimo';
      case 2:
        return 'Scarso';
      case 3:
        return 'Sufficiente';
      case 4:
        return 'Buono';
      case 5:
        return 'Eccellente';
      default:
        return '';
    }
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      _showErrorSnackBar('Il commento non può essere vuoto');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);

      final success = await reviewProvider.addReview(
        widget.workoutId,
        authProvider.currentUserId ?? '',
        _rating.toString(),
        double.parse(_commentController.text.trim()),
        '', // Add a fifth argument as needed (e.g., an empty string or appropriate value)
      );

      if (success) {
        _commentController.clear();
        _rating = 5.0;
        _showSuccessSnackBar('Recensione pubblicata con successo!');
        _loadReviews();
      } else {
        _showErrorSnackBar('Errore durante la pubblicazione della recensione');
      }
    } catch (e) {
      _showErrorSnackBar('Errore: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _editReview(Review review) async {
    // Implementa la logica per modificare una recensione
    // Può aprire un dialog o navigare ad una nuova schermata
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica Recensione'),
        content: const Text('Funzionalità in arrivo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Recensione'),
        content: const Text('Sei sicuro di voler eliminare questa recensione?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final success = await reviewProvider.deleteReview(reviewId);

      if (success) {
        _showSuccessSnackBar('Recensione eliminata');
        _loadReviews();
      } else {
        _showErrorSnackBar('Errore durante l\'eliminazione');
      }
    }
  }

  Future<void> _moderateReview(String reviewId, bool hide) async {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    final success = await reviewProvider.moderateReview(reviewId, hide);

    if (success) {
      _showSuccessSnackBar(
          hide ? 'Recensione nascosta' : 'Recensione mostrata');
      _loadReviews();
    } else {
      _showErrorSnackBar('Errore durante la moderazione');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
