import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();
const storage = admin.storage();

const AUTO_APPROVE = false; // toggle via env var: AUTO_APPROVE=true

function dayKey(d: Date) {
  const y = d.getFullYear().toString().padStart(4, '0');
  const m = (d.getMonth() + 1).toString().padStart(2, '0');
  const dd = d.getDate().toString().padStart(2, '0');
  return `${y}${m}${dd}`;
}

// Helper to increment daily metric for verification_completed
async function incVerificationCompleted(businessId: string) {
  const now = new Date();
  const key = dayKey(now);
  const ref = db
    .collection('businesses')
    .doc(businessId)
    .collection('metrics')
    .doc('daily')
    .collection('days')
    .doc(key);

  await ref.set({
    date: `${now.getFullYear().toString().padStart(4,'0')}-${(now.getMonth()+1).toString().padStart(2,'0')}-${now.getDate().toString().padStart(2,'0')}`,
    verification_completed: admin.firestore.FieldValue.increment(1),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
}

// Firestore trigger on new verification request
export const onVerificationRequest = functions.firestore
  .document('businesses/{businessId}/verification_requests/{reqId}')
  .onCreate(async (snap: functions.firestore.DocumentSnapshot, ctx: functions.EventContext) => {
    const data = snap.data();
    const businessId = ctx.params.businessId as string;
    const reqId = ctx.params.reqId as string;

    const ownerName = (data?.ownerName as string) ?? '';
    const ownerEmail = (data?.ownerEmail as string) ?? '';
    const ownerPhone = (data?.ownerPhone as string) ?? '';
    const documentUrl = (data?.documentUrl as string) ?? '';

    const auditRef = db.collection('businesses').doc(businessId).collection('verification_audit').doc(reqId);

    const audit: any = {
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      checks: {},
      valid: false,
    };

    // Basic field validation
    audit.checks.ownerName = typeof ownerName === 'string' && ownerName.trim().length > 2;
    audit.checks.ownerEmail = typeof ownerEmail === 'string' && ownerEmail.includes('@');
    audit.checks.ownerPhone = typeof ownerPhone === 'string' && ownerPhone.replace(/\D/g, '').length >= 7;

    // Document existence & simple metadata check
    audit.checks.documentExists = false;
    try {
      if (documentUrl) {
        // Try to map the URL to a storage bucket + path.
        // Support common forms: gs://bucket/path or https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<path>
        let bucketName: string | null = null;
        let filePath: string | null = null;

        if (documentUrl.startsWith('gs://')) {
          // gs://bucket/path
          const parts = documentUrl.replace('gs://', '').split('/');
          bucketName = parts.shift() ?? null;
          filePath = parts.join('/');
        } else if (documentUrl.includes('/o/')) {
          // https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<path>?alt=media
          final: {
            try {
              const u = new URL(documentUrl);
              const segs = u.pathname.split('/');
              const bIdx = segs.indexOf('b');
              if (bIdx >= 0 && segs.length > bIdx + 1) {
                bucketName = segs[bIdx + 1];
                // /o/<path>
                const oIdx = segs.indexOf('o');
                if (oIdx >= 0 && segs.length > oIdx + 1) {
                  filePath = decodeURIComponent(segs[oIdx + 1]);
                }
              }
            } catch (e) {
              // ignore
            }
          }
        }

        if (bucketName && filePath) {
          const file = storage.bucket(bucketName).file(filePath);
          const [meta] = await file.getMetadata();
          audit.checks.documentExists = true;
          audit.checks.documentSize = Number(meta.size || 0);
        }
      }
    } catch (e: any) {
      audit.error = String(e?.message ?? e);
    }

    audit.valid = !!(audit.checks.ownerName && audit.checks.ownerEmail && audit.checks.ownerPhone && audit.checks.documentExists);

    await auditRef.set(audit, { merge: true });

    // Optionally auto-approve when automated checks are sufficient
    const autoApprove = (process.env.AUTO_APPROVE === 'true') || AUTO_APPROVE;
    if (audit.valid && autoApprove) {
      await db.collection('businesses').doc(businessId).set({ verified: true, verifiedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      // increment verification metric
      const now = new Date();
      const day = dayKey(now);
      const dayRef = db.collection('businesses').doc(businessId).collection('metrics').doc('daily').collection('days').doc(day);
      await dayRef.set({
        date: `${now.getFullYear().toString().padStart(4,'0')}-${(now.getMonth()+1).toString().padStart(2,'0')}-${now.getDate().toString().padStart(2,'0')}`,
        verification_completed: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // record a lightweight outcome in audit
      await auditRef.set({ autoApproved: true, autoApprovedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    }

    // No external side-effects (emails/notifications) performed here. Use additional functions for that.
    return null;
  });

// HTTP endpoint for admins to approve or reject verification requests.
// Request must include a valid Firebase ID token in Authorization: Bearer <token>
export const adminApproveVerification = functions.https.onRequest(async (req: functions.https.Request, res: functions.Response) => {
  try {
    if (req.method !== 'POST') { res.status(405).send('Method not allowed'); return; }

    const authHeader = (req.headers.authorization || '') as string;
    if (!authHeader.startsWith('Bearer ')) { res.status(401).send('Missing Authorization header'); return; }
    const idToken = authHeader.split('Bearer ').pop();
    if (!idToken) { res.status(401).send('Missing token'); return; }

    let decoded: admin.auth.DecodedIdToken;
    try {
      decoded = await admin.auth().verifyIdToken(idToken);
    } catch (e) {
      res.status(401).send('Invalid token'); return;
    }

    // require admin custom claim
    if (!(decoded.admin === true || decoded.claims?.admin === true || decoded['admin'] === true)) {
      res.status(403).send('Admin claim required'); return;
    }

  const body = req.body || {};
    const businessId = body.businessId as string | undefined;
    const reqId = body.reqId as string | undefined;
    const approve = body.approve === true;
    const note = body.note as string | undefined;

    if (!businessId || !reqId) { res.status(400).send('businessId and reqId required'); return; }

    const reqRef = db.collection('businesses').doc(businessId).collection('verification_requests').doc(reqId);
    const reqSnap = await reqRef.get();
    if (!reqSnap.exists) { res.status(404).send('Request not found'); return; }

    // update request doc with decision
    const decision: any = {
      status: approve ? 'approved' : 'rejected',
      decidedAt: admin.firestore.FieldValue.serverTimestamp(),
      decidedBy: decoded.uid,
    };
    if (note) decision.decisionNote = note;
    await reqRef.set(decision, { merge: true });

    // write audit note
    const auditRef = db.collection('businesses').doc(businessId).collection('verification_audit').doc(reqId);
    await auditRef.set({
      reviewedBy: decoded.uid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      approved: approve,
      reviewNote: note ?? null,
    }, { merge: true });

    if (approve) {
      // mark business verified
      await db.collection('businesses').doc(businessId).set({ verified: true, verifiedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      // increment daily verification metric
      await incVerificationCompleted(businessId);
    } else {
      // record rejection on business doc if desired
      await db.collection('businesses').doc(businessId).set({ verificationRejectedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    }

    res.status(200).json({ ok: true, approved: approve }); return;
  } catch (e: any) {
    console.error('adminApproveVerification error', e);
    res.status(500).send(String(e)); return;
  }
});
