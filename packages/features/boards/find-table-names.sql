-- Helper SQL Script to Find Your Table Names
-- Run this in your PostgreSQL database to find the actual table names

-- Step 1: Find all tables that might be related to boards/cards/columns
SELECT 
  table_name,
  'Possible match' as note
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND (
    table_name ILIKE '%card%' 
    OR table_name ILIKE '%board%' 
    OR table_name ILIKE '%column%'
    OR table_name ILIKE '%kanban%'
  )
ORDER BY table_name;

-- Step 2: Check column structure of potential card table
-- Replace 'cards' with one of the table names from Step 1
-- Uncomment and run for each potential table:

/*
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'cards'  -- CHANGE THIS to your actual table name
ORDER BY ordinal_position;
*/

-- Step 3: Check for foreign key relationships
-- This helps identify which table is which
SELECT
  tc.table_name as table_name,
  kcu.column_name as column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND (
    tc.table_name ILIKE '%card%'
    OR tc.table_name ILIKE '%board%'
    OR tc.table_name ILIKE '%column%'
  )
ORDER BY tc.table_name, kcu.column_name;