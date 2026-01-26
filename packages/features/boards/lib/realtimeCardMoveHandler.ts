/**
 * Realtime Card Move Event Handler
 * 
 * This module handles the single batch realtime event emitted by the PostgreSQL trigger
 * after a card move transaction completes.
 * 
 * Implementation of Option D: Transaction-Based Move with Single Realtime Event
 * - Receives ONE event with all affected cards instead of N individual events
 * - Eliminates race conditions by processing atomic transaction results
 * - Improves scalability by reducing event volume from N to 1
 */

export type CardMoveEvent = {
  board_id: string;
  event_type: "cards_moved";
  affected_card_ids: string[]; // Array of card IDs that were affected
  moved_card_id: string;
  timestamp: string;
};

export type CardMoveEventHandler = (event: CardMoveEvent) => void | Promise<void>;

/**
 * Parse pg_notify payload from PostgreSQL trigger
 * The trigger emits: json_build_object(...)::text
 */
export function parseCardMoveEvent(payload: string): CardMoveEvent | null {
  try {
    const parsed = JSON.parse(payload);
    
    // Validate event structure
    if (
      parsed.board_id &&
      parsed.event_type === "cards_moved" &&
      Array.isArray(parsed.affected_card_ids) &&
      parsed.moved_card_id
    ) {
      return parsed as CardMoveEvent;
    }
    
    return null;
  } catch (error) {
    console.error("Failed to parse card move event:", error);
    return null;
  }
}

/**
 * Process a single batch card move event
 * Fetches full card details and updates UI in a single operation
 * 
 * @param event - The batch event containing affected card IDs
 * @param fetchCards - Function to fetch full card details by IDs
 * @param updateCards - Callback to update cards in the UI state
 */
export async function processCardMoveEvent(
  event: CardMoveEvent,
  fetchCards: (cardIds: string[]) => Promise<Array<{
    id: string;
    column_id: string;
    position: number;
    title: string;
    updated_at: string;
  }>>,
  updateCards: (cards: Array<{
    id: string;
    column_id: string;
    position: number;
    title: string;
    updated_at: string;
  }>) => void
): Promise<void> {
  // Fetch full card details for all affected cards
  const cards = await fetchCards(event.affected_card_ids);
  
  // Sort cards by column and position for consistent ordering
  const sortedCards = [...cards].sort((a, b) => {
    if (a.column_id !== b.column_id) {
      return a.column_id.localeCompare(b.column_id);
    }
    return a.position - b.position;
  });

  // Update all cards in a single batch operation
  // This eliminates the need for N separate updates
  updateCards(sortedCards);
}

/**
 * Example integration with Supabase Realtime or PostgreSQL LISTEN/NOTIFY
 * 
 * For Supabase:
 * ```typescript
 * import { createClient } from '@supabase/supabase-js'
 * 
 * const supabase = createClient(url, key)
 * 
 * supabase
 *   .channel('card-moves')
 *   .on('postgres_changes', {
 *     event: 'NOTIFY',
 *     schema: 'public',
 *     channel: 'card_move'
 *   }, async (payload) => {
 *     const event = parseCardMoveEvent(payload.new.payload)
 *     if (event) {
 *       await processCardMoveEvent(event, fetchCardsByIds, updateCards)
 *     }
 *   })
 *   .subscribe()
 * ```
 * 
 * For direct PostgreSQL LISTEN (server-side):
 * ```typescript
 * import { Client } from 'pg'
 * 
 * const client = new Client({ connectionString: DATABASE_URL })
 * await client.connect()
 * await client.query('LISTEN card_move')
 * 
 * client.on('notification', (msg) => {
 *   const event = parseCardMoveEvent(msg.payload)
 *   if (event) {
 *     // Broadcast via WebSocket, Server-Sent Events, etc.
 *   }
 * })
 * ```
 */