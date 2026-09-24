import request from "supertest";
import { describe, expect, it } from "vitest";
import { createApp } from "../src/app";

const app = createApp();

describe("health", () => {
  it("répond 200 avec le statut du service", async () => {
    const res = await request(app).get("/api/v1/health");
    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
    expect(res.body.service).toBe("alliya-kalenda-api");
  });
});

describe("404", () => {
  it("rejette les routes inconnues avec l'enveloppe d'erreur", async () => {
    const res = await request(app).get("/api/v1/inexistant");
    expect(res.status).toBe(404);
    expect(res.body.error.message).toMatch(/introuvable/i);
  });
});

describe("auth — garde de connexion", () => {
  it("refuse /projects sans token (401)", async () => {
    const res = await request(app).get("/api/v1/projects");
    expect(res.status).toBe(401);
  });

  it("refuse /auth/me sans token (401)", async () => {
    const res = await request(app).get("/api/v1/auth/me");
    expect(res.status).toBe(401);
  });

  it("refuse un Bearer token falsifié (401)", async () => {
    const res = await request(app)
      .get("/api/v1/projects")
      .set("Authorization", "Bearer jeton.falsifie");
    expect(res.status).toBe(401);
  });
});

describe("validation Zod", () => {
  it("rejette un register sans email valide (422)", async () => {
    const res = await request(app).post("/api/v1/auth/register").send({
      email: "pas-un-email",
      password: "motdepasse",
      fullName: "Test",
    });
    expect(res.status).toBe(422);
    expect(res.body.error.message).toMatch(/invalide/i);
  });

  it("rejette un login sans champs (422)", async () => {
    const res = await request(app).post("/api/v1/auth/login").send({});
    expect(res.status).toBe(422);
  });
});
