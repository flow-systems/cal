import { defaultResponderForAppDir } from "app/api/defaultResponderForAppDir";
import { cookies, headers } from "next/headers";
import { NextRequest, NextResponse } from "next/server";

import { getServerSession } from "@calcom/features/auth/lib/getServerSession";
import { prisma } from "@calcom/prisma";

import { buildLegacyRequest } from "@lib/buildLegacyCtx";

/**
 * REST API endpoint for moving cards
 * Uses the atomic PostgreSQL function for reliable card moves
 * 
 * POST /api/boards/[boardId]/cards/[cardId]/move
 * Body: { targetColumnId: string, targetPosition: number }
 */
async function handler(
  req: NextRequest,
  { params }: { params: Promise<{ boardId: string; cardId: string }> }
) {
  try {
    const { boardId, cardId } = await params;
    
    const session = await getServerSession({ 
      req: buildLegacyRequest(await headers(), await cookies()) 
    });
    
    if (!session?.user?.id) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { boardId, cardId } = params;
    const body = await req.json();
    const { targetColumnId, targetPosition } = body;

    if (!targetColumnId || typeof targetPosition !== "number") {
      return NextResponse.json(
        { error: "Missing targetColumnId or targetPosition" },
        { status: 400 }
      );
    }

    // Verify user has access to the board
    const board = await prisma.$queryRaw<Array<{ id: string }>>`
      SELECT id FROM boards
      WHERE id = ${boardId}::UUID
        AND (
          user_id = ${session.user.id}
          OR team_id IN (
            SELECT team_id FROM "Membership"
            WHERE user_id = ${session.user.id} AND accepted = true
          )
        )
      LIMIT 1
    `;

    if (!board || board.length === 0) {
      return NextResponse.json({ error: "Board not found or access denied" }, { status: 403 });
    }

    // Verify the card exists and belongs to this board
    const card = await prisma.$queryRaw<Array<{ id: string; column_id: string; position: number }>>`
      SELECT id, column_id, position FROM cards
      WHERE id = ${cardId}::UUID AND board_id = ${boardId}::UUID
      LIMIT 1
    `;

    if (!card || card.length === 0) {
      return NextResponse.json({ error: "Card not found" }, { status: 404 });
    }

    // Verify target column exists and belongs to this board
    const targetColumn = await prisma.$queryRaw<Array<{ id: string }>>`
      SELECT id FROM columns
      WHERE id = ${targetColumnId}::UUID AND board_id = ${boardId}::UUID
      LIMIT 1
    `;

    if (!targetColumn || targetColumn.length === 0) {
      return NextResponse.json({ error: "Target column not found" }, { status: 404 });
    }

    // Call PostgreSQL function for atomic card move
    type AffectedCard = {
      affected_card_id: string;
      new_column_id: string;
      new_position: number;
    };

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

    return NextResponse.json({
      success: true,
      affectedCardsCount: cards.length,
      affectedCards: cards.map((card) => ({
        id: card.id,
        title: card.title,
        column_id: card.column_id,
        position: card.position,
        updated_at: card.updated_at,
      })),
    });
  } catch (error) {
    console.error("Error moving card:", error);
    
    // Handle PostgreSQL function errors
    if (error instanceof Error && error.message.includes("Card not found")) {
      return NextResponse.json({ error: error.message }, { status: 404 });
    }

    return NextResponse.json(
      { error: "Failed to move card" },
      { status: 500 }
    );
  }
}

export const POST = defaultResponderForAppDir(handler);