import { Router } from "express";
import { authRouter } from "./auth.js";
import { usersRouter } from "./users.js";
import { serviceCentersRouter } from "./serviceCenters.js";
import { techniciansRouter } from "./technicians.js";
import { serviceRequestsRouter } from "./serviceRequests.js";
import { invoicesRouter } from "./invoices.js";

export const apiRouter = Router();

apiRouter.use("/auth", authRouter);
apiRouter.use("/users", usersRouter);
apiRouter.use("/service-centers", serviceCentersRouter);
apiRouter.use("/technicians", techniciansRouter);
apiRouter.use("/service-requests", serviceRequestsRouter);
apiRouter.use("/invoices", invoicesRouter);
