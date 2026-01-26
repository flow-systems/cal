# Fix: Card Not Persisting After Move

## Problem
Card "Realtime Test" moves in UI but returns to original column after page refresh.

## Root Cause
**Your frontend is likely using an old API endpoint that doesn't persist correctly.**

## Quick Diagnosis

### Step 1: Check Database State

Run this SQL query to see where the card actually is:

```sql
SELECT 
  c.id,
  c.title,
  c.column_id,
  col.name as column_name,
  c.position,
  c.updated_at
FROM cards c
LEFT JOIN columns col ON col.id = c.column_id
WHERE c.title = 'Realtime Test';
```

**If the card is still in the original column**, the move never persisted to the database.

### Step 2: Check What API is Being Called

1. Open browser DevTools (F12)
2. Go to **Network** tab
3. **Clear** the network log
4. Move the "Realtime Test" card from "test" to "in progress"
5. Look for the API request

**What to check:**
- What endpoint is called? (e.g., `/api/boards/moveCard`, `/api/trpc/viewer.boards.moveCard`)
- What's the request method? (POST, PUT, PATCH?)
- What's the response? (Success? Error?)

### Step 3: Verify New Endpoint Works

Test the new endpoint directly:

```sql
-- Get the card ID and column IDs
SELECT 
  c.id as card_id,
  c.column_id as current_column_id,
  (SELECT id FROM columns WHERE name = 'In Progress' AND board_id = c.board_id LIMIT 1) as target_column_id,
  c.board_id
FROM cards c
WHERE c.title = 'Realtime Test';
```

Then test the function:
```sql
SELECT * FROM move_card_atomic(
  'card-id-from-above'::UUID,
  'target-column-id-from-above'::UUID,
  0::INTEGER,
  'board-id-from-above'::UUID
);
```

## Solution

### If Frontend Uses Old API

Update your frontend to use the new endpoint:

```typescript
import { trpc } from '@calcom/trpc/react'

// Replace old API call with:
const moveCard = trpc.viewer.boards.moveCard.useMutation({
  onSuccess: (data) => {
    // Update UI with affectedCards
    updateCards(data.affectedCards)
  },
  onError: (error) => {
    console.error('Move failed:', error)
    // Revert optimistic update
  }
})

// Use it:
await moveCard.mutateAsync({
  cardId: cardId,
  targetColumnId: targetColumnId,
  targetPosition: targetPosition,
  boardId: boardId
})
```

### If API Call is Failing

Check server logs for errors. The new endpoint should:
- Return `success: true`
- Return `affectedCards` array
- Update the database atomically

## Common Issues

### 1. Authorization Error
If you get "UNAUTHORIZED", check:
- User has access to the board
- `user_id` or `team_id` matches in the boards table

### 2. Column Not Found
If you get "Target column not found":
- Verify column exists: `SELECT id, name FROM columns WHERE name = 'In Progress'`
- Check column belongs to the board

### 3. Old API Still Being Used
If Network tab shows a different endpoint:
- Find the file making the API call
- Replace it with `trpc.viewer.boards.moveCard`

---

**Next Steps:**
1. Run the diagnostic SQL query
2. Check Network tab in DevTools
3. Share what you find and I'll help fix it!