import express from "express";
import cors from "cors";
import { corsOrigins } from "./config";
import { errorHandler, notFoundHandler } from "./middleware/error-handler";
import { healthRouter } from "./routes/health";
import { modulesRouter } from "./routes/modules";
import { authRouter } from "./routes/auth";
import { projectsRouter } from "./routes/projects";
import { activitiesRouter } from "./routes/activities";
import { peopleRouter } from "./routes/people";
import { financesRouter } from "./routes/finances";
import { conversationsRouter } from "./routes/conversations";
import { reportsRouter } from "./routes/reports";
import { dashboardRouter } from "./routes/dashboard";

/** Construit l'app Express (testable sans écouter de port). */
export function createApp() {
  const app = express();

  app.use(cors({ origin: corsOrigins }));
  app.use(express.json({ limit: "1mb" }));

  app.use("/api/v1/health", healthRouter);
  // Public : sert le catalogue des modules avant toute session.
  app.use("/api/v1/modules", modulesRouter);
  app.use("/api/v1/auth", authRouter);
  app.use("/api/v1/projects", projectsRouter);
  app.use("/api/v1/activities", activitiesRouter);
  app.use("/api/v1/people", peopleRouter);
  app.use("/api/v1/finances", financesRouter);
  app.use("/api/v1/conversations", conversationsRouter);
  app.use("/api/v1/reports", reportsRouter);
  app.use("/api/v1/dashboard", dashboardRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
