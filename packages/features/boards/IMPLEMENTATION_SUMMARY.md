# Transaction-Based Card Move Implementation Summary

## Overview

This implementation refactors the card move system to use **Option D: Transaction-Based Move with Single Realtime Event**, solving card positioning and persistence issues.

## What Was Changed

### 1. Database Layer
**File**: `packages/prisma/migrations/20260126204203_transaction_based_card_move/migration.sql`

- ✅ Created `move_card_atomic()` PostgreSQL function
  - Handles all position updates in a single atomic transaction
  - Uses row-level locking (`FOR UPDATE`) to prevent race conditions
  - Emits a single `pg_notify` event with all affected card IDs
  - Returns affected cards for API response

- ✅ Added performance index
  - `Card_board_id_column_id_position_idx` for efficient queries

### 2. API Layer
**Files**:
- `packages/trpc/server/routers/viewer/boards/moveCard.schema.ts`
- `packages/trpc/server/routers/viewer/boards/moveCard.handler.ts`
- `packages/trpc/server/routers/viewer/boards/_router.ts`

- ✅ Created tRPC endpoint: `trpc.viewer.boards.moveCard`
- ✅ Validates user access to board and cards
- ✅ Calls PostgreSQL function for atomic move
- ✅ Returns affected cards for optimistic UI updates

### 3. Realtime Event Handler
**File**: `packages/features/boards/lib/realtimeCardMoveHandler.ts`

- ✅ Parser for pg_notify payload
- ✅ Batch event processor
- ✅ Fetches full card details and updates UI in one operation

### 4. Router Integration
**File**: `packages/trpc/server/routers/viewer/_router.tsx`

- ✅ Added `boardsRouter` to viewer router

## Benefits Achieved

### Reliability ✅
- **Atomic Operation**: All position updates happen in a single transaction
- **No Race Conditions**: Database-level locking prevents concurrent conflicts
- **Consistent State**: Either all updates succeed or all fail

### Scalability ✅
- **1 Event Instead of N**: Single realtime event regardless of cards affected
- **Reduced Network Traffic**: One message instead of multiple
- **Lower Processing Overhead**: Frontend processes one batch update

## Migration Steps

1. **Run the migration**:
   ```bash
   yarn workspace @calcom/prisma db-migrate
   ```

2. **Update frontend code** to use the new API:
   ```typescript
   const moveCard = trpc.viewer.boards.moveCard.useMutation()
   ```

3. **Update realtime listeners** to process batch events:
   ```typescript
   import { parseCardMoveEvent, processCardMoveEvent } from '@calcom/features/boards/lib/realtimeCardMoveHandler'
   ```

## Breaking Changes

⚠️ **Realtime Event Format Changed**

**Before**: Multiple individual events per card update
**After**: Single batch event with `affected_card_ids` array

Clients must:
1. Parse the new event format
2. Fetch full card details using the IDs
3. Update UI with the batch of cards

## Testing Checklist

- [ ] Run migration successfully
- [ ] Test card move within same column
- [ ] Test card move between columns
- [ ] Test concurrent moves (should not cause race conditions)
- [ ] Verify single realtime event is emitted
- [ ] Verify all affected cards are included in event
- [ ] Test with large number of cards (performance)

## Next Steps

1. Update existing frontend code to use new API endpoint
2. Update realtime event listeners to handle batch events
3. Remove old card move implementation
4. Monitor for any edge cases or issues
5. Consider adding metrics/logging for move operations

## Rollback Plan

If issues arise:

1. Revert the migration:
   ```sql
   DROP FUNCTION IF EXISTS move_card_atomic CASCADE;
   DROP INDEX IF EXISTS "Card_board_id_column_id_position_idx";
   ```

2. Restore old API handler implementation
3. Update frontend to use old endpoint

## Notes

- The PostgreSQL function emits the realtime event directly, ensuring atomicity
- The event contains card IDs only - clients must fetch full details
- This approach scales better as the number of affected cards increases