-- Transaction-Based Card Move with Single Realtime Event
-- This migration implements Option D: atomic card moves with a single realtime event
-- to eliminate race conditions and improve scalability

-- Step 1: Create function to move card atomically
-- This function handles all position updates in a single transaction
CREATE OR REPLACE FUNCTION move_card_atomic(
  p_card_id UUID,
  p_target_column_id UUID,
  p_target_position INTEGER,
  p_board_id UUID
) RETURNS TABLE(
  affected_card_id UUID,
  new_column_id UUID,
  new_position INTEGER
) AS $$
DECLARE
  v_source_column_id UUID;
  v_source_position INTEGER;
  v_affected_cards UUID[];
BEGIN
  -- Get current card position
  -- NOTE: Update table name if your actual table uses a different name (e.g., "cards", "Cards", etc.)
  SELECT column_id, position INTO v_source_column_id, v_source_position
  FROM cards
  WHERE id = p_card_id AND board_id = p_board_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found: %', p_card_id;
  END IF;

  -- If moving within the same column and position, no-op
  IF v_source_column_id = p_target_column_id AND v_source_position = p_target_position THEN
    RETURN;
  END IF;

  -- Start transaction block (function runs in transaction automatically)
  
  -- Case 1: Moving within the same column
  IF v_source_column_id = p_target_column_id THEN
    -- Shift cards between old and new position
    IF v_source_position < p_target_position THEN
      -- Moving down: shift cards up
      UPDATE cards
      SET position = position - 1,
          updated_at = NOW()
      WHERE column_id = v_source_column_id
        AND position > v_source_position
        AND position <= p_target_position
        AND board_id = p_board_id;
      
      -- Move the card to new position
      UPDATE cards
      SET position = p_target_position,
          updated_at = NOW()
      WHERE id = p_card_id;
    ELSE
      -- Moving up: shift cards down
      UPDATE cards
      SET position = position + 1,
          updated_at = NOW()
      WHERE column_id = v_source_column_id
        AND position >= p_target_position
        AND position < v_source_position
        AND board_id = p_board_id;
      
      -- Move the card to new position
      UPDATE cards
      SET position = p_target_position,
          updated_at = NOW()
      WHERE id = p_card_id;
    END IF;
  ELSE
    -- Case 2: Moving to a different column
    -- Shift cards in source column up (fill gap)
    UPDATE cards
    SET position = position - 1,
        updated_at = NOW()
    WHERE column_id = v_source_column_id
      AND position > v_source_position
      AND board_id = p_board_id;

    -- Shift cards in target column down (make space)
    UPDATE cards
    SET position = position + 1,
        updated_at = NOW()
    WHERE column_id = p_target_column_id
      AND position >= p_target_position
      AND board_id = p_board_id;

    -- Move the card to new column and position
    UPDATE cards
    SET column_id = p_target_column_id,
        position = p_target_position,
        updated_at = NOW()
    WHERE id = p_card_id;
  END IF;

  -- Collect all affected card IDs for the return value and realtime event
  SELECT ARRAY_AGG(id) INTO v_affected_cards
  FROM cards
  WHERE (
    (column_id = v_source_column_id AND position >= LEAST(v_source_position, p_target_position) AND position <= GREATEST(v_source_position, p_target_position))
    OR (column_id = p_target_column_id AND position >= p_target_position AND position <= GREATEST(v_source_position, p_target_position))
  )
  AND board_id = p_board_id;

  -- Emit single realtime event with all affected cards
  -- This happens atomically within the same transaction
  PERFORM pg_notify(
    'card_move',
    json_build_object(
      'board_id', p_board_id,
      'event_type', 'cards_moved',
      'affected_card_ids', v_affected_cards,
      'moved_card_id', p_card_id,
      'timestamp', NOW()
    )::text
  );

  -- Return affected cards
  RETURN QUERY
  SELECT c.id, c.column_id, c.position
  FROM cards c
  WHERE c.id = ANY(v_affected_cards)
  ORDER BY c.column_id, c.position;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Note on realtime events
-- The move_card_atomic function emits the realtime event directly via pg_notify
-- This ensures a single event is emitted per transaction, containing all affected card IDs
-- The client should fetch full card details using the affected_card_ids from the event

-- Step 4: Add index for performance (if not exists)
-- NOTE: Update table name if your actual table uses a different name
CREATE INDEX IF NOT EXISTS cards_board_id_column_id_position_idx 
ON cards(board_id, column_id, position);

-- Step 5: Add comment for documentation
COMMENT ON FUNCTION move_card_atomic IS 'Atomically moves a card and updates all affected card positions in a single transaction. Returns all affected cards.';