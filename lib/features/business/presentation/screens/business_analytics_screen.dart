// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:ceylon/features/business/presentation/bloc/business_dashboard_cubit.dart';
import 'package:ceylon/features/business/data/business_repository.dart';

class BusinessAnalyticsScreen extends StatelessWidget {
  const BusinessAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BusinessDashboardCubit(
        BusinessRepository(FirebaseFirestore.instance, FirebaseAuth.instance),
      )..load(),
      child: const _AnalyticsBody(),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody();

  int _val(Object? o) => (o is num) ? o.toInt() : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: BlocBuilder<BusinessDashboardCubit, BusinessDashboardState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final biz = state.business;
          if (biz == null) {
            return const Center(
              child: Text('No business found for this account.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AnalyticsCard(
                title: 'Yesterday CTA Clicks',
                valueFuture: _fetchDailyTotal(
                  biz.id,
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
              const SizedBox(height: 12),
              _AnalyticsCard(
                title: 'Today CTA Clicks (hourly)',
                valueFuture: _fetchHourlyTotal(biz.id, DateTime.now()),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<int> _fetchDailyTotal(String businessId, DateTime day) async {
    final key = DateFormat('yyyy-MM-dd').format(day.toUtc());
    final ref = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('metrics')
        .doc('daily')
        .collection('days')
        .doc(key);
    final snap = await ref.get();
    final d = snap.data() ?? {};
    return _val(d['cta_call']) +
        _val(d['cta_directions']) +
        _val(d['cta_website']);
  }

  Future<int> _fetchHourlyTotal(String businessId, DateTime when) async {
    final key = DateFormat('yyyy-MM-dd').format(when.toUtc());
    final ref = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('metrics')
        .doc('hourly')
        .collection('days')
        .doc(key)
        .collection('hours');
    final snap = await ref.get();
    int sum = 0;
    for (final d in snap.docs) {
      final m = d.data();
      sum +=
          _val(m['cta_call']) +
          _val(m['cta_directions']) +
          _val(m['cta_website']);
    }
    return sum;
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final Future<int> valueFuture;
  const _AnalyticsCard({required this.title, required this.valueFuture});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<int>(
          future: valueFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${snap.data ?? 0}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
