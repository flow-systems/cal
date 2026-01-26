# Board Card Move - Transaction-Based Implementation

This implementation follows **Option D: Transaction-Based Move with Single Realtime Event** to solve card positioning and persistence issues.

## Architecture

### Database Layer (PostgreSQL)

1. **`move_card_atomic()` Function**
   - Handles all card position updates in a single atomic transaction
   - Returns all affected cards
   - Prevents race conditions with row-level locking (`FOR UPDATE`)

2. **`notify_card_move_batch()` Trigger Function**
   - Emits a single `pg_notify` event after transaction commits
   - Includes all affected cards in one payload
   - Reduces event volume from N to 1

3. **Trigger**
   - Fires after `column_id` or `position` updates
   - Automatically batches events per transaction

### API Layer (tRPC)

**Endpoint**: `trpc.viewer.boards.moveCard`

**Handler**: `packages/trpc/server/routers/viewer/boards/moveCard.handler.ts`

- Validates user access to board
- Calls PostgreSQL function for atomic move
- Returns affected cards for optimistic UI updates

### Realtime Layer

**Event Format**:
```json
{
  "board_id": "uuid",
  "event_type": "cards_moved",
  "affected_card_ids": ["uuid1", "uuid2", "uuid3"],
  "moved_card_id": "uuid1",
  "timestamp": "2026-01-26T20:42:03Z"
}
```

**Note**: The event contains card IDs only. The client should fetch full card details using these IDs to update the UI.

**Handler**: `packages/features/boards/lib/realtimeCardMoveHandler.ts`

## Benefits

### Reliability
- ✅ **Atomic Operation**: All position updates happen in a single transaction
- ✅ **No Race Conditions**: Database-level locking prevents concurrent conflicts
- ✅ **Consistent State**: Either all updates succeed or all fail

### Scalability
- ✅ **1 Event Instead of N**: Single realtime event regardless of cards affected
- ✅ **Reduced Network Traffic**: One message instead of multiple
- ✅ **Lower Processing Overhead**: Frontend processes one batch update

### Complexity
- ⚠️ **Database Logic**: PostgreSQL functions require SQL knowledge
- ⚠️ **Maintenance**: Database migrations for function changes

## Migration

Run the migration to create the PostgreSQL function and trigger:

```bash
yarn workspace @calcom/prisma db-migrate
```

## Usage

### Move a Card (API)

```typescript
import { trpc } from '@calcom/trpc/react'

const moveCard = trpc.viewer.boards.moveCard.useMutation()

moveCard.mutate({
  cardId: 'card-uuid',
  targetColumnId: 'column-uuid',
  targetPosition: 2,
  boardId: 'board-uuid'
})
```

### Listen for Realtime Events

```typescript
import { parseCardMoveEvent, processCardMoveEvent } from '@calcom/features/boards/lib/realtimeCardMoveHandler'

// Example with Supabase
supabase
  .channel('card-moves')
  .on('postgres_changes', {
    event: 'NOTIFY',
    schema: 'public',
    channel: 'card_move'
  }, async (payload) => {
    const event = parseCardMoveEvent(payload.new.payload)
    if (event) {
      await processCardMoveEvent(
        event,
        async (cardIds) => {
          // Fetch full card details from API
          const response = await trpc.viewer.boards.getCardsByIds.query({ cardIds })
          return response.cards
        },
        (cards) => {
          // Update UI state with all affected cards
          setCards(cards)
        }
      )
    }
  })
  .subscribe()
```

## Testing

Test the PostgreSQL function directly:

```sql
SELECT * FROM move_card_atomic(
  'card-uuid'::UUID,
  'target-column-uuid'::UUID,
  2::INTEGER,
  'board-uuid'::UUID
);
```

## Troubleshooting

### Trigger Not Firing
- Check that the trigger exists: `\d+ "Card"` in psql
- Verify trigger function: `\df notify_card_move_batch`

### Events Not Received
- Verify LISTEN is active: `SELECT * FROM pg_listening_channels();`
- Check pg_notify channel name matches: `'card_move'`

### Race Conditions
- Function uses `FOR UPDATE` locking - ensure transactions complete
- Check for long-running transactions blocking updates