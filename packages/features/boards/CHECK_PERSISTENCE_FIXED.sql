-- Fixed Diagnostic Queries

-- 1. First, check what columns exist in the columns table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'columns'
ORDER BY ordinal_position;

-- 2. Find the "Realtime Test" card and see its current state (without column name)
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

-- 3. Check all cards in the board to see their positions
-- (Replace 'YOUR_BOARD_ID' with actual board_id from query 2)
SELECT 
  c.id,
  c.title,
  c.column_id,
  c.position,
  c.updated_at
FROM cards c
WHERE c.board_id = (
  SELECT board_id FROM cards WHERE title = 'Realtime Test' LIMIT 1
)
ORDER BY c.column_id, c.position;

-- 4. Get column IDs and their details (if columns table has different column names)
SELECT 
  id,
  -- Try common column name variations:
  -- name, title, label, column_name
  *
FROM columns
WHERE board_id = (
  SELECT board_id FROM cards WHERE title = 'Realtime Test' LIMIT 1
)
ORDER BY position;