-- Step 1: Get a test card with all needed IDs
-- This will show you a card with its current position, column, and board
SELECT 
  c.id as card_id,
  c.column_id,
  c.position as current_position,
  c.board_id,
  c.title
FROM cards c
WHERE c.board_id IS NOT NULL
LIMIT 1;

-- Step 2: Get a different column in the same board (for testing column moves)
-- Replace 'YOUR_BOARD_ID_HERE' with the board_id from Step 1
SELECT 
  id as target_column_id,
  name as column_name,
  position as column_position
FROM columns
WHERE board_id = 'YOUR_BOARD_ID_HERE'::UUID
  AND id != 'YOUR_COLUMN_ID_HERE'::UUID  -- Different from current column
LIMIT 1;

-- Step 3: Test the function
-- Replace the UUIDs below with actual values from Steps 1 and 2
SELECT * FROM move_card_atomic(
  'c2044033-5751-4382-9957-a36b280ca642'::UUID,  -- card_id from Step 1
  '40fcaaaa-7ee9-4cba-8073-3afbd9b48ba3'::UUID,  -- target_column_id (can be same or different)
  0::INTEGER,                                     -- target position (0 = top of column)
  '83d57e73-e82f-407f-836f-c892993c8c24'::UUID   -- board_id from Step 1
);

-- Expected result: Returns affected cards with their new positions
-- Example output:
-- affected_card_id | new_column_id | new_position
-- -----------------+--------------+-------------
-- uuid-here        | uuid-here    | 0
-- uuid-here        | uuid-here    | 1