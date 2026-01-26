import { Prisma } from "@calcom/prisma";
import { prisma } from "@calcom/prisma";
import type { TrpcSessionUser } from "@calcom/trpc/server/types";

import { TRPCError } from "@trpc/server";

import type { TMoveCardInputSchema } from "./moveCard.schema";

type MoveCardOptions = {
  ctx: {
    user: NonNullable<TrpcSessionUser>;
  };
  input: TMoveCardInputSchema;
};

type AffectedCard = {
  affected_card_id: string;
  new_column_id: string;
  new_position: number;
};

/**
 * Move card using transaction-based PostgreSQL function
 * This implements Option D: atomic operation with single realtime event
 * 
 * Benefits:
 * - Atomic: All position updates happen in a single transaction
 * - Single Event: Trigger emits one realtime event instead of N events
 * - No Race Conditions: Database-level locking prevents concurrent move conflicts
 * - Scalable: 1 realtime event instead of N (where N = cards updated)
 */
export const moveCardHandler = async ({ ctx, input }: MoveCardOptions) => {
  const { user } = ctx;
  const { cardId, targetColumnId, targetPosition, boardId } = input;

  // Verify user has access to the board
  // NOTE: Update model name if your Prisma schema uses a different name
  // Using raw query as fallback - replace with actual Prisma model when schema is available
  const board = await prisma.$queryRaw<Array<{ id: string }>>`
    SELECT id FROM boards
    WHERE id = ${boardId}::UUID
      AND (
        user_id = ${user.id}
        OR team_id IN (
          SELECT team_id FROM "Membership"
          WHERE user_id = ${user.id} AND accepted = true
        )
      )
    LIMIT 1
  `;

  if (!board || board.length === 0) {
    throw new TRPCError({
      code: "UNAUTHORIZED",
      message: "You don't have access to this board",
    });
  }

  // Verify the card exists and belongs to this board
  const card = await prisma.$queryRaw<Array<{ id: string; column_id: string; position: number }>>`
    SELECT id, column_id, position FROM cards
    WHERE id = ${cardId}::UUID AND board_id = ${boardId}::UUID
    LIMIT 1
  `;

  if (!card || card.length === 0) {
    throw new TRPCError({
      code: "NOT_FOUND",
      message: "Card not found",
    });
  }

  const cardData = card[0];

  // Verify target column exists and belongs to this board
  const targetColumn = await prisma.$queryRaw<Array<{ id: string }>>`
    SELECT id FROM columns
    WHERE id = ${targetColumnId}::UUID AND board_id = ${boardId}::UUID
    LIMIT 1
  `;

  if (!targetColumn || targetColumn.length === 0) {
    throw new TRPCError({
      code: "NOT_FOUND",
      message: "Target column not found",
    });
  }

  try {
    // Call PostgreSQL function for atomic card move
    // This function handles all position updates in a single transaction
    // and the trigger automatically emits a single realtime event
    const affectedCards = await prisma.$queryRaw<AffectedCard[]>`
      SELECT 
        affected_card_id,
        new_column_id,
        new_position
      FROM move_card_atomic(
        ${cardId}::UUID,
        ${targetColumnId}::UUID,
        ${targetPosition}::INTEGER,
        ${boardId}::UUID
      )
    `;

    // Fetch full card details for the response
    const cardIds = affectedCards.map((c) => c.affected_card_id);
    const cards = await prisma.$queryRaw<Array<{
      id: string;
      title: string;
      column_id: string;
      position: number;
      updated_at: Date;
    }>>`
      SELECT id, title, column_id, position, updated_at
      FROM cards
      WHERE id = ANY(${cardIds}::UUID[])
        AND board_id = ${boardId}::UUID
      ORDER BY column_id ASC, position ASC
    `;

    return {
      success: true,
      affectedCardsCount: cards.length,
      affectedCards: cards.map((card) => ({
        id: card.id,
        title: card.title,
        column_id: card.column_id,
        position: card.position,
        updated_at: card.updated_at,
      })),
    };
  } catch (error) {
    // Handle PostgreSQL function errors
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      if (error.code === "P0001") {
        // PostgreSQL exception (e.g., card not found)
        throw new TRPCError({
          code: "NOT_FOUND",
          message: error.message,
        });
      }
    }

    // Log unexpected errors
    console.error("Error moving card:", error);

    throw new TRPCError({
      code: "INTERNAL_SERVER_ERROR",
      message: "Failed to move card",
    });
  }
};