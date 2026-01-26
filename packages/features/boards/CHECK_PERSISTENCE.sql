-- Diagnostic Queries to Check Card Persistence

-- 1. Find the "Realtime Test" card and see its current state
SELECT 
  id,
  title,
  column_id,
  position,
  board_id,
  updated_at
FROM cards
WHERE title = 'Realtime Test'
ORDER BY updated_at DESC;

-- 2. Get column names for reference
SELECT 
  c.id as card_id,
  c.title,
  c.column_id,
  col.name as column_name,
  c.position
FROM cards c
LEFT JOIN columns col ON col.id = c.column_id
WHERE c.title = 'Realtime Test';

-- 3. Check all cards in the board to see their positions
SELECT 
  c.id,
  c.title,
  c.column_id,
  col.name as column_name,
  c.position,
  c.updated_at
FROM cards c
LEFT JOIN columns col ON col.id = c.column_id
WHERE c.board_id = (
  SELECT board_id FROM cards WHERE title = 'Realtime Test' LIMIT 1
)
ORDER BY col.name, c.position;