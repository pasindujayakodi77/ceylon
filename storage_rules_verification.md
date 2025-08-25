Suggested Firebase Storage & Firestore security rules for verification workflow

Overview
- Verification documents should be writable only by authenticated owners and readable by a verification service or admin users.
- Business documents should only be updated to `verified: true` by a trusted backend (Cloud Function with admin privileges) or an admin-only path.

Firestore (example rules snippet)

match /databases/{database}/documents {
  match /businesses/{businessId} {
    allow read: if true;
    // Prevent clients from setting `verified` or `verifiedAt` directly
    allow update: if request.auth != null && !('verified' in request.resource.data);

    // Owners may write verification_requests
    match /verification_requests/{reqId} {
      allow create: if request.auth != null && request.auth.uid == request.resource.data.ownerId;
      allow read: if request.auth != null && (request.auth.uid == resource.data.ownerId || request.auth.token.admin == true);
      allow delete: if false; // keep audit trail
    }

    // audit and metrics should be writeable only by server
    match /verification_audit/{auditId} {
      allow write: if request.auth != null && request.auth.token.admin == true;
      allow read: if request.auth != null && (request.auth.uid == resource.data.ownerId || request.auth.token.admin == true);
    }
  }
}

Storage rules (example)

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Verification documents path
    match /verifications/{businessId}/{allPaths=**} {
      // Allow owners to upload their own documents (must check ownerId claim or enforce via signed URL)
      allow write: if request.auth != null && request.auth.uid == resource.metadata.ownerUid;
      // Read allowed to admins and the verification service
      allow read: if request.auth != null && (request.auth.token.admin == true || request.auth.token.verifier == true);
    }
  }
}

Notes
- Storage rules that rely on client-supplied metadata can be spoofed; preferred approach: produce time-limited signed upload URLs from a trusted backend (Cloud Function) so clients cannot write arbitrary paths/metadata.
- Alternatively, accept uploads to a staging bucket and move/scan files server-side before attaching to the business.
