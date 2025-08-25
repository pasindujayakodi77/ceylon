import 'package:flutter/material.dart';
import 'package:ceylon/features/business/presentation/widgets/request_verification_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final String label; // e.g., "Verified"
  final DateTime? lastVerified;
  final String? businessId;

  const VerifiedBadge({
    super.key,
    this.size = 18,
    this.label = 'Verified',
    this.businessId,
    this.lastVerified,
  });

  @override
  Widget build(BuildContext context) {
    // If no businessId, render the simple static badge
    if (businessId == null) {
      return Semantics(
        label: label,
        button: true,
        child: InkWell(
          onTap: null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: size,
                  color: const Color(0xFF1E88E5),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (lastVerified != null)
                      Text(
                        'Verified ${lastVerified!.toLocal().toString().split(' ').first}',
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If Firebase hasn't been initialized (tests or early boot), avoid accessing Firestore
    if (Firebase.apps.isEmpty) {
      // Fallback to a neutral 'Verification' badge without live status
      return Semantics(
        label: label,
        button: true,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => RequestVerificationSheet(businessId: businessId!),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: size,
                  color: const Color(0xFF1E88E5),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Live status from Firestore
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) {
          return const SizedBox.shrink();
        }
        final data = snap.data!.data() ?? {};
        final verified = data['verified'] == true;
        final status =
            (data['verificationStatus'] ?? (verified ? 'approved' : 'none'))
                .toString();
        final verifiedAt = (data['verifiedAt'] is Timestamp)
            ? (data['verifiedAt'] as Timestamp).toDate()
            : null;

        if (verified || status == 'approved') {
          return Semantics(
            label: 'Verified',
            button: true,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      RequestVerificationSheet(businessId: businessId!),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF90CAF9)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: size,
                      color: const Color(0xFF1E88E5),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified',
                          style: const TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (verifiedAt != null)
                          Text(
                            'Verified ${verifiedAt.toLocal().toString().split(' ').first}',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (status == 'pending') {
          return Semantics(
            label: 'Verification requested',
            button: true,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      RequestVerificationSheet(businessId: businessId!),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: size,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Verification requested',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (status == 'rejected') {
          return Semantics(
            label: 'Verification rejected',
            button: true,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      RequestVerificationSheet(businessId: businessId!),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: size, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      'Verification rejected',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // default fallback
        return Semantics(
          label: label,
          button: true,
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    RequestVerificationSheet(businessId: businessId!),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    size: size,
                    color: const Color(0xFF1E88E5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
