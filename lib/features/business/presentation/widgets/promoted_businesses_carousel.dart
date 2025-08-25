// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_models.dart';

class PromotedBusinessesCarousel extends StatelessWidget {
  final String title;
  final int pageSize;
  const PromotedBusinessesCarousel({
    super.key,
    required this.title,
    this.pageSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final repo = BusinessRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 210,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: repo.promotedBusinessesQuery(limit: pageSize).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(child: Text('No promoted businesses'));
              }
              final items = snap.data!.docs
                  .map((d) => Business.fromDoc(d))
                  .toList();
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final b = items[i];
                  return SizedBox(
                    width: 300,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          // TODO: navigate to detail with b.id
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (b.photoUrl != null && b.photoUrl!.isNotEmpty)
                              SizedBox(
                                height: 120,
                                width: double.infinity,
                                child: Image.network(
                                  b.photoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              const SizedBox(
                                height: 120,
                                child: ColoredBox(color: Colors.black12),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                b.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
