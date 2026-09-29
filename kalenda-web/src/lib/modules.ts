/**
 * Catalogue des modules d'Alliya Kalenda.
 *
 * La source de verite est la base : `GET /api/v1/modules`. Aucun module n'est
 * code en dur, ce fichier se contente de typer la reponse, ce qui fait que le
 * parcours d'inscription s'adapte a tout module ajoute cote API.
 */

/** Champ de specialisation demande au compte, pilote par l'API. */
export type ModuleField = {
  key: string;
  label: string;
  type: "text" | "select";
  options?: string[];
  optional?: boolean;
};

export type KalendaModuleDef = {
  id: string;
  label: string;
  /** `available` = selectionnable, `planned` = annonce mais pas encore livre. */
  status: string;
  promise: string;
  cover: string;
  highlights: string[];
  fields: ModuleField[];
};

/** Un module n'est selectionnable que s'il est livre. */
export function isAvailable(module: KalendaModuleDef) {
  return module.status === "available";
}

export function findModule(
  modules: KalendaModuleDef[],
  id: string | null | undefined,
) {
  return modules.find((module) => module.id === id) ?? null;
}
