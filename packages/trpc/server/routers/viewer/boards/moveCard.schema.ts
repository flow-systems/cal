import { z } from "zod";

export const ZMoveCardInputSchema = z.object({
  cardId: z.string().uuid(),
  targetColumnId: z.string().uuid(),
  targetPosition: z.number().int().min(0),
  boardId: z.string().uuid(),
});

export type TMoveCardInputSchema = z.infer<typeof ZMoveCardInputSchema>;