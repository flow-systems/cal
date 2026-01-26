# Testing Checklist

## Quick Verification (2 minutes)

Run these SQL queries to confirm migration:

```sql
-- Verify function exists
SELECT routine_name FROM information_schema.routines WHERE routine_name = 'move_card_atomic';

-- Verify index exists  
SELECT indexname FROM pg_indexes WHERE tablename = 'cards' AND indexname = 'cards_board_id_column_id_position_idx';
```

Both should return 1 row.

---

## Function Testing (5 minutes)

1. Get test data:
```sql
SELECT c.id, c.column_id, c.position, c.board_id 
FROM cards c 
WHERE c.board_id IS NOT NULL 
LIMIT 1;
```

2. Test function:
```sql
SELECT * FROM move_card_atomic(
  'your-card-id'::UUID,
  'your-column-id'::UUID,
  0::INTEGER,
  'your-board-id'::UUID
);
```

Should return affected cards.

---

## API Testing (5 minutes)

Test via tRPC:
```typescript
trpc.viewer.boards.moveCard.useMutation().mutate({
  cardId: 'uuid',
  targetColumnId: 'uuid',
  targetPosition: 0,
  boardId: 'uuid'
})
```

---

## Integration Testing (10 minutes)

1. ✅ Move card within same column
2. ✅ Move card between columns  
3. ✅ Move multiple cards rapidly (test race conditions)
4. ✅ Verify only ONE realtime event per move
5. ✅ Check all affected cards update correctly

---

**All set!** The implementation is ready to use. 🎉