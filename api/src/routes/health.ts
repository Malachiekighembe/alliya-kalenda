import { Router } from "express";

export const healthRouter = Router();

healthRouter.get("/", (_req, res) => {
  res.json({
    status: "ok",
    service: "alliya-kalenda-api",
    time: new Date().toISOString(),
  });
});
