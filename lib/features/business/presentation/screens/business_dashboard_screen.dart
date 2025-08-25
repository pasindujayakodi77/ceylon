// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_models.dart';
import 'package:ceylon/features/business/presentation/bloc/business_dashboard_cubit.dart';
import 'package:ceylon/features/business/presentation/widgets/request_verification_sheet.dart';

class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BusinessDashboardCubit(
        BusinessRepository(FirebaseFirestore.instance, FirebaseAuth.instance),
      )..load(),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Dashboard')),
      body: BlocBuilder<BusinessDashboardCubit, BusinessDashboardState>(
        builder: (context, state) {
          if (state.loading)
            return const Center(child: CircularProgressIndicator());
          final biz = state.business;
          if (biz == null)
            return const Center(
              child: Text('No business found for this account.'),
            );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileCard(biz: biz),
              const SizedBox(height: 12),
              _PromotionCard(biz: biz),
              const SizedBox(height: 12),
              _VerificationCard(businessId: biz.id),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Business biz;
  const _ProfileCard({required this.biz});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(biz.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (biz.description != null) Text(biz.description!),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(biz.verified ? 'Verified' : 'Unverified')),
                const SizedBox(width: 8),
                Chip(
                  label: Text(biz.promotedActive ? 'Promoted' : 'Not Promoted'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionCard extends StatefulWidget {
  final Business biz;
  const _PromotionCard({required this.biz});

  @override
  State<_PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<_PromotionCard> {
  bool _active = false;
  final _rankCtrl = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _active = widget.biz.promotedActive;
    _rankCtrl.text = widget.biz.promotedRank.toString();
  }

  @override
  void dispose() {
    _rankCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Promotion', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Active'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            TextField(
              controller: _rankCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rank (higher shows first)',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        final rank = int.tryParse(_rankCtrl.text.trim()) ?? 0;
                        try {
                          await context
                              .read<BusinessDashboardCubit>()
                              .setPromoted(active: _active, rank: rank);
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final String businessId;
  const _VerificationCard({required this.businessId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verification',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Submit your documents and notes to request verification.',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () async {
                  final ok = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        RequestVerificationSheet(businessId: businessId),
                  );
                  if (ok == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification requested.')),
                    );
                  }
                },
                child: const Text('Request Verification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
