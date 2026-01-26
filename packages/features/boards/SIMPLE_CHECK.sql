-- Simple query to check card state (no joins)

-- Check where "Realtime Test" card is
SELECT 
  id,
  title,
  column_id,
  position,
  board_id,
  updated_at
FROM cards
WHERE title = 'Realtime Test';

-- Check all cards in the same board
SELECT 
  id,
  title,
  column_id,
  position,
  updated_at
FROM cards
WHERE board_id = (
  SELECT board_id FROM cards WHERE title = 'Realtime Test' LIMIT 1
)
ORDER BY column_id, position;