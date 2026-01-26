-- Quick Test: Get a card and test moving it
-- Run this query first to get your test data

SELECT 
  c.id as card_id,
  c.column_id as current_column_id,
  c.position as current_position,
  c.board_id,
  c.title
FROM cards c
WHERE c.board_id IS NOT NULL
LIMIT 1;

-- Copy the values from above, then run this (replace with your actual IDs):

SELECT * FROM move_card_atomic(
  'c2044033-5751-4382-9957-a36b280ca642'::UUID,  -- Paste card_id here
  '40fcaaaa-7ee9-4cba-8073-3afbd9b48ba3'::UUID,  -- Paste column_id here (or use same column_id to move within column)
  0::INTEGER,                                     -- Target position (0 = top)
  '83d57e73-e82f-407f-836f-c892993c8c24'::UUID   -- Paste board_id here
);