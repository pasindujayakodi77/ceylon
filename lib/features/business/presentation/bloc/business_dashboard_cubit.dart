import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/business_models.dart';
import '../../data/business_repository.dart';

class BusinessDashboardState extends Equatable {
  final Business? business;
  final bool loading;
  final String? error;

  const BusinessDashboardState({this.business, this.loading = false, this.error});

  BusinessDashboardState copyWith({Business? business, bool? loading, String? error}) =>
      BusinessDashboardState(
        business: business ?? this.business,
        loading: loading ?? this.loading,
        error: error,
      );

  @override
  List<Object?> get props => [business, loading, error];
}

class BusinessDashboardCubit extends Cubit<BusinessDashboardState> {
  BusinessDashboardCubit(this._repo) : super(const BusinessDashboardState(loading: true));

  final BusinessRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final biz = await _repo.getCurrentUserBusiness();
      emit(state.copyWith(business: biz, loading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }

  Future<void> setPromoted({required bool active, int rank = 0}) async {
    final biz = state.business;
    if (biz == null) return;
    emit(state.copyWith(loading: true));
    try {
      await _repo.updateBusinessProfile(biz.id, promotedActive: active, promotedRank: rank);
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }
}
