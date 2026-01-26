-- Run this SQL query to verify your column names match
-- This will show you the structure of your cards, boards, and columns tables

-- Check cards table structure
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'cards'
  AND column_name IN ('id', 'column_id', 'board_id', 'position', 'title', 'updated_at', 'created_at')
ORDER BY ordinal_position;

-- Check boards table structure  
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'boards'
  AND column_name IN ('id', 'user_id', 'team_id', 'name', 'updated_at', 'created_at')
ORDER BY ordinal_position;

-- Check columns table structure
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'columns'
  AND column_name IN ('id', 'board_id', 'name', 'position', 'updated_at', 'created_at')
ORDER BY ordinal_position;