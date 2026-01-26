import { authedProcedure } from "../../../procedures/authedProcedure";
import { router } from "../../../trpc";
import { moveCardHandler } from "./moveCard.handler";
import { ZMoveCardInputSchema } from "./moveCard.schema";

export const boardsRouter = router({
  moveCard: authedProcedure.input(ZMoveCardInputSchema).mutation(async ({ ctx, input }) => {
    return moveCardHandler({ ctx, input });
  }),
});