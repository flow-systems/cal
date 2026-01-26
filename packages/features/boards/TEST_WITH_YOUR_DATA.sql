-- Test the function with your actual card data
-- Card: "test" (position 1 in column a37eb3b7-7baf-4535-a1bb-63d1f599f078)

-- Option 1: Move card to position 0 (top of same column)
SELECT * FROM move_card_atomic(
  'c2044033-5751-4382-9957-a36b280ca642'::UUID,  -- card_id
  'a37eb3b7-7baf-4535-a1bb-63d1f599f078'::UUID,  -- same column_id (moving within column)
  0::INTEGER,                                     -- target position (0 = top)
  '83d57e73-e82f-407f-836f-c892993c8c24'::UUID   -- board_id
);

-- Option 2: Move card to position 2 (further down in same column)
SELECT * FROM move_card_atomic(
  'c2044033-5751-4382-9957-a36b280ca642'::UUID,  -- card_id
  'a37eb3b7-7baf-4535-a1bb-63d1f599f078'::UUID,  -- same column_id
  2::INTEGER,                                     -- target position (2 = third position)
  '83d57e73-e82f-407f-836f-c892993c8c24'::UUID   -- board_id
);

-- Option 3: Move to a different column (get another column ID first)
-- First, get another column in the same board:
SELECT id, name, position 
FROM columns 
WHERE board_id = '83d57e73-e82f-407f-836f-c892993c8c24'::UUID
  AND id != 'a37eb3b7-7baf-4535-a1bb-63d1f599f078'::UUID
LIMIT 1;

-- Then use that column_id in the function:
-- SELECT * FROM move_card_atomic(
--   'c2044033-5751-4382-9957-a36b280ca642'::UUID,  -- card_id
--   'OTHER_COLUMN_ID_HERE'::UUID,                  -- different column_id (from query above)
--   0::INTEGER,                                     -- target position
--   '83d57e73-e82f-407f-836f-c892993c8c24'::UUID   -- board_id
-- );