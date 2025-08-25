Cloud Functions for Ceylon - verification automation

This folder contains a minimal TypeScript Cloud Function that listens for new
verification requests created under:

  businesses/{businessId}/verification_requests/{reqId}

Behavior:
- Performs basic validation of owner fields (name, email, phone).
- Attempts to verify the uploaded document exists in Firebase Storage and records basic metadata.
- Writes an audit document to businesses/{businessId}/verification_audit/{reqId} containing check results.
- Optionally auto-approves the business (set AUTO_APPROVE env var or update the constant in code).
- If auto-approved, sets businesses/{businessId}.verified = true and increments a daily metric verification_completed.

Deployment:

1) Install dependencies and build (TypeScript):

  cd functions
  npm install
  npm run build

2) Deploy with Firebase CLI:

  firebase deploy --only functions

Admin approval HTTP endpoint

After deployment you'll have an HTTPS endpoint for `adminApproveVerification` (check the functions URL printed by `firebase deploy`).

Example curl call (replace <URL> and <ID_TOKEN> and request fields):

```bash
curl -X POST '<URL>' \
  -H "Authorization: Bearer <ID_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"businessId":"<BUS_ID>","reqId":"<REQ_ID>","approve":true,"note":"Looks good"}'
```

Notes on admin auth

- The function checks the decoded Firebase ID token for an `admin` custom claim. Set this claim for a user via the Firebase Admin SDK or the Firebase Console in a trusted backend.
- Example (one-off) to set claim with Admin SDK:

```js
admin.auth().setCustomUserClaims(uid, { admin: true });
```

Security & next steps:

- Do NOT auto-approve in production without robust checks (document OCR, human review).
- Add notifications (email/SMS) via Pub/Sub or other functions.
- Harden storage & firestore rules to restrict who can upload verification docs.
