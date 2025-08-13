# Firestore Composite Index Requirements

## Calendar Events Query Index

When using the Holidays & Events Calendar feature, Firestore will likely request a composite index for the following query pattern:

### Query Pattern
```dart
FirebaseFirestore.instance
  .collectionGroup('events')
  .where('published', isEqualTo: true)
  .where('startsAt', isGreaterThanOrEqualTo: monthStart)
  .where('startsAt', isLessThan: monthEnd)
  .orderBy('startsAt', descending: false)
```

### Required Composite Index

**Collection Group:** `events`

**Fields:**
1. `published` (Ascending)
2. `startsAt` (Ascending)

### Index Configuration

If Firestore requests this index, you can create it through:

1. **Firebase Console:**
   - Go to Firestore Database → Indexes → Composite
   - Collection Group: `events`
   - Fields:
     - `published`: Ascending
     - `startsAt`: Ascending

2. **CLI Command:**
   ```bash
   firebase firestore:indexes
   ```

3. **Manual Index JSON:**
   ```json
   {
     "indexes": [
       {
         "collectionGroup": "events",
         "queryScope": "COLLECTION_GROUP",
         "fields": [
           {
             "fieldPath": "published",
             "order": "ASCENDING"
           },
           {
             "fieldPath": "startsAt",
             "order": "ASCENDING"
           }
         ]
       }
     ]
   }
   ```

### Why This Index Is Needed

The calendar feature queries for:
- **Collection Group:** All `events` subcollections across different businesses
- **Filter:** Only published events (`published == true`)
- **Range:** Events starting within a specific month (`startsAt >= monthStart AND startsAt < monthEnd`)
- **Ordering:** Events sorted by start time (`orderBy startsAt ASC`)

This combination of equality filter + range filter + ordering requires a composite index for optimal performance.

### Performance Considerations

- **Index Size:** Grows with number of published events across all businesses
- **Write Cost:** Each event creation/update will update this index
- **Query Speed:** Near-instant retrieval of monthly events with proper index

### Alternative Query Patterns

If you want to avoid the composite index, you could:

1. **Query per business** (less efficient for global calendar):
   ```dart
   // Query each business individually, then merge results
   businesses.forEach((businessId) {
     firestore.collection('businesses/$businessId/events')
       .where('published', isEqualTo: true)
       .where('startsAt', isGreaterThanOrEqualTo: monthStart)
       .where('startsAt', isLessThan: monthEnd)
       .orderBy('startsAt');
   });
   ```

2. **Client-side filtering** (less efficient):
   ```dart
   // Get all published events, filter dates client-side
   firestore.collectionGroup('events')
     .where('published', isEqualTo: true)
     .get()
     .then((snapshot) => {
       // Filter by date range in Dart code
     });
   ```

The composite index approach is recommended for best performance with the calendar feature.
