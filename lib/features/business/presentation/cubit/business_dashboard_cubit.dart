// FILE: lib/features/business/presentation/cubit/business_dashboard_cubit.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../data/business_repository.dart';
import '../../data/business_models.dart';

/// States for the business dashboard
abstract class BusinessDashboardState extends Equatable {
  const BusinessDashboardState();

  @override
  List<Object?> get props => [];
}

/// Loading state for the business dashboard
class BusinessDashboardLoading extends BusinessDashboardState {
  const BusinessDashboardLoading();
}

/// Data state containing business information and related data
class BusinessDashboardData extends BusinessDashboardState {
  final Business business;
  final List<BusinessEvent> events;
  final int pendingReviewsCount;
  final bool promotedActive;
  final bool isSaving;
  final String? toast;
  final String verificationStatus;

  const BusinessDashboardData({
    required this.business,
    required this.events,
    this.pendingReviewsCount = 0,
    required this.promotedActive,
    this.isSaving = false,
    this.toast,
    this.verificationStatus = 'none',
  });

  @override
  List<Object?> get props => [
    business,
    events,
    pendingReviewsCount,
    promotedActive,
    isSaving,
    toast,
    verificationStatus,
  ];

  BusinessDashboardData copyWith({
    Business? business,
    List<BusinessEvent>? events,
    int? pendingReviewsCount,
    bool? promotedActive,
    bool? isSaving,
    String? toast,
    String? verificationStatus,
  }) {
    return BusinessDashboardData(
      business: business ?? this.business,
      events: events ?? this.events,
      pendingReviewsCount: pendingReviewsCount ?? this.pendingReviewsCount,
      promotedActive: promotedActive ?? this.promotedActive,
      isSaving: isSaving ?? this.isSaving,
      toast: toast, // Pass the new toast directly (null clears it)
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}

/// Error state containing an error message
class BusinessDashboardError extends BusinessDashboardState {
  final String message;

  const BusinessDashboardError(this.message);

  @override
  List<Object> get props => [message];
}

/// Cubit for managing business dashboard state
class BusinessDashboardCubit extends Cubit<BusinessDashboardState> {
  final BusinessRepository _repository;

  StreamSubscription? _businessSubscription;
  StreamSubscription? _eventsSubscription;
  String? _currentOwnerId;
  String? _currentBusinessId;

  /// Creates a new [BusinessDashboardCubit] instance
  BusinessDashboardCubit({required BusinessRepository repository})
    : _repository = repository,
      super(const BusinessDashboardLoading());

  @override
  Future<void> close() async {
    await _businessSubscription?.cancel();
    await _eventsSubscription?.cancel();
    await _verificationSubscription?.cancel();
    return super.close();
  }

  /// Loads the business dashboard data for the specified owner
  Future<void> loadForOwner(String ownerId) async {
    if (ownerId == _currentOwnerId && state is! BusinessDashboardLoading) {
      return; // Already loaded for this owner (idempotent)
    }

    _currentOwnerId = ownerId;
    emit(const BusinessDashboardLoading());

    try {
      final businesses = await _repository.listOwned(ownerId, limit: 1);

      if (businesses.isEmpty) {
        emit(const BusinessDashboardError('No business found for this owner'));
        return;
      }

      final business = businesses.first;
      _currentBusinessId = business.id;

      // Start listening to business updates
      _startListeningToBusiness(business.id);
    } catch (e) {
      emit(BusinessDashboardError('Failed to load business: ${e.toString()}'));
    }
  }

  /// Saves updates to a business
  Future<void> saveBusiness(Business business) async {
    if (state is! BusinessDashboardData) return;

    final currentState = state as BusinessDashboardData;
    emit(currentState.copyWith(isSaving: true));

    try {
      await _repository.upsertBusiness(business);
      emit(
        currentState.copyWith(
          isSaving: false,
          toast: 'Business details saved successfully',
        ),
      );

      // Clear toast after 3 seconds
      _clearToastAfterDelay();
    } catch (e) {
      emit(
        currentState.copyWith(
          isSaving: false,
          toast: 'Error saving business: ${e.toString()}',
        ),
      );

      // Clear toast after 3 seconds
      _clearToastAfterDelay();
    }
  }

  /// Toggles the promotion status for a business
  Future<void> togglePromotion({
    required bool promoted,
    int? weight,
    DateTime? until,
  }) async {
    if (state is! BusinessDashboardData || _currentBusinessId == null) return;

    final currentState = state as BusinessDashboardData;
    emit(currentState.copyWith(isSaving: true));

    try {
      await _repository.updatePromotion(
        _currentBusinessId!,
        promoted: promoted,
        promotedWeight: weight,
        promotedUntil: until != null ? Timestamp.fromDate(until) : null,
      );

      emit(
        currentState.copyWith(
          isSaving: false,
          toast: promoted ? 'Promotion activated' : 'Promotion deactivated',
        ),
      );

      // Clear toast after 3 seconds
      _clearToastAfterDelay();
    } catch (e) {
      emit(
        currentState.copyWith(
          isSaving: false,
          toast: 'Error updating promotion: ${e.toString()}',
        ),
      );

      // Clear toast after 3 seconds
      _clearToastAfterDelay();
    }
  }

  /// Requests verification for a business
  Future<void> requestVerification({
    required String docsUrl,
    String? note,
  }) async {
    if (state is! BusinessDashboardData || _currentBusinessId == null) return;

    final currentState = state as BusinessDashboardData;
    emit(currentState.copyWith(isSaving: true));

    try {
      await _repository.requestVerification(
        _currentBusinessId!,
        docsUrl: docsUrl,
        note: note,
      );

      emit(
        currentState.copyWith(
          isSaving: false,
          toast: 'Verification request submitted',
        ),
      );

      // Clear toast after 3 seconds
      _clearToastAfterDelay();
    } catch (e) {
      emit(
        currentState.copyWith(
          isSaving: false,
          toast: 'Error requesting verification: ${e.toString()}',
        ),
      );

      // Clear toast after 3 seconds
      _clearToastAfterDelay();
    }
  }

  /// Starts listening to real-time business updates
  StreamSubscription? _verificationSubscription;

  void _startListeningToBusiness(String businessId) {
    // Cancel any existing subscriptions
    _businessSubscription?.cancel();
    _eventsSubscription?.cancel();
    _verificationSubscription?.cancel();

    // Subscribe to business updates
    _businessSubscription = _repository
        .streamBusiness(businessId)
        .listen(
          (business) {
            if (business == null) {
              emit(const BusinessDashboardError('Business no longer exists'));
              return;
            }

            // Check if promotion is active based on current time
            final promotedActive = business.isPromotedActive(DateTime.now());

            if (state is BusinessDashboardData) {
              final currentState = state as BusinessDashboardData;
              emit(
                currentState.copyWith(
                  business: business,
                  promotedActive: promotedActive,
                ),
              );
            } else {
              // Start listening to events
              _startListeningToEvents(businessId);

              // Load pending reviews count
              _loadPendingReviewsCount(businessId);

              // Initial state with the business
              emit(
                BusinessDashboardData(
                  business: business,
                  events: const [],
                  promotedActive: promotedActive,
                ),
              );

              // Start listening to verification status
              _startListeningToVerificationStatus(businessId);
            }
          },
          onError: (error) {
            emit(
              BusinessDashboardError(
                'Error streaming business: ${error.toString()}',
              ),
            );
          },
        );
  }

  /// Starts listening to verification status updates
  void _startListeningToVerificationStatus(String businessId) {
    _verificationSubscription = _repository
        .streamVerificationStatus(businessId)
        .listen(
          (status) {
            if (state is BusinessDashboardData) {
              final currentState = state as BusinessDashboardData;
              emit(currentState.copyWith(verificationStatus: status));
            }
          },
          onError: (error) {
            // Just log the error, don't change the state
            print('Error streaming verification status: $error');
          },
        );
  }

  /// Starts listening to real-time events updates
  void _startListeningToEvents(String businessId) {
    _eventsSubscription = _repository
        .streamEvents(businessId, includeUnpublished: true)
        .listen(
          (events) {
            if (state is BusinessDashboardData) {
              final currentState = state as BusinessDashboardData;
              emit(currentState.copyWith(events: events));
            }
          },
          onError: (error) {
            // Just log the error but don't change state - in production use a proper logging framework
            // ignore: avoid_print
            print('Error streaming events: $error');
          },
        );
  }

  /// Counts pending reviews that need responses
  Future<void> _loadPendingReviewsCount(String businessId) async {
    if (state is! BusinessDashboardData) return;

    try {
      // Get reviews that don't have owner replies
      final reviewsStream = _repository.streamReviews(businessId);
      final reviews = await reviewsStream.first;

      // Count reviews without owner replies (simplified logic - in a real app,
      // you would have an ownerReply field in the review model)
      final pendingCount = reviews.length;

      if (state is BusinessDashboardData) {
        final currentState = state as BusinessDashboardData;
        emit(currentState.copyWith(pendingReviewsCount: pendingCount));
      }
    } catch (e) {
      // Just log the error but don't change state - in production use a proper logging framework
      // ignore: avoid_print
      print('Error loading pending reviews: $e');
    }
  }

  /// Clears the toast message after a delay
  void _clearToastAfterDelay() {
    if (state is! BusinessDashboardData) return;

    Future.delayed(const Duration(seconds: 3), () {
      if (state is BusinessDashboardData) {
        final currentState = state as BusinessDashboardData;
        emit(currentState.copyWith(toast: null));
      }
    });
  }
}
