/**
 * Selection de l'indicatif pays pour la connexion par telephone.
 *
 * La liste vient de `world-countries` : tous les pays et territoires
 * reconnus, avec leur nom en francais et leur indicatif telephonique. Une
 * liste saisie a la main oublie des territoires et devient fausse a chaque
 * ajout de pays.
 *
 * L'utilisateur saisit son numero national ; l'indicatif est ajoute par le
 * client avant l'envoi. Le backend normalise ensuite (espaces, tirets,
 * parentheses) avant de comparer au compte, ce qui rend la saisie tolerant.
 */
import countries from "world-countries";

export type Country = {
  /** Code ISO 3166-1 alpha-2. */
  code: string;
  /** Indicatif telephonique international, sans « + ». */
  dial: string;
  label: string;
};

/**
 * Indicatif international d'un pays.
 *
 * Les indicatifs partages par plusieurs pays sont des codes complets a eux
 * seuls : « +1 » pour la zone NANP (Etats-Unis, Canada…) et « +7 » pour
 * la Russie et le Kazakhstan. Leurs `suffixes` sont des codes regionaux, pas
 * des codes nationaux — les lire donnerait « +73 » pour la Russie.
 *
 * Ailleurs, l'indicatif est la racine suivi du suffixe, tronque a trois
 * chiffres, la longueur maximale d'un code ITU.
 */
function dialOf(entry: (typeof countries)[number]): string | null {
  const root = entry.idd?.root;
  if (!root) return null;
  const digits = root.replace(/^\+/, "");
  if (digits === "1" || digits === "7") return digits;
  const suffix = entry.idd?.suffixes?.[0];
  if (!suffix) return /^\d{1,3}$/.test(digits) ? digits : null;
  const dial = `${digits}${suffix}`.slice(0, 3);
  return /^\d{2,3}$/.test(dial) ? dial : null;
}

function buildCountries(): Country[] {
  const list: Country[] = [];
  for (const entry of countries) {
    const dial = dialOf(entry);
    if (!dial) continue;
    const label = entry.translations?.fra?.common ?? entry.name.common;
    list.push({ code: entry.cca2, dial, label });
  }
  // Ordre alphabétique sur le nom francais : l'utilisateur cherche un nom.
  return list.sort((a, b) => a.label.localeCompare(b.label, "fr"));
}

export const COUNTRIES: Country[] = buildCountries();

export const DEFAULT_COUNTRY = "CD";

/** Retire tout ce qui n'est pas un chiffre d'un numero national. */
export function nationalDigits(value: string) {
  return value.replace(/[^\d]/g, "");
}

/**
 * Compose l'identifiant transmis au backend.
 *
 * Un e-mail est renvoye tel quel ; un numero recoit l'indicatif du pays
 * choisi. Si l'utilisateur a deja saisi l'indicatif, on ne l'ajoute pas deux
 * fois.
 */
export function toIdentifier(value: string, dial: string) {
  const trimmed = value.trim();
  if (trimmed.includes("@") || trimmed.startsWith("+")) return trimmed;
  const digits = nationalDigits(trimmed);
  return digits ? `+${dial}${digits}` : trimmed;
}

/**
 * Filtre la liste : sur le nom, l'indicatif ou le code pays.
 *
 * Le nom est compare sans accent ni casse, pour que « cote » trouve
 * « Côte d'Ivoire ».
 */
export function filterCountries(query: string) {
  // Plage de diacritiques combinants. Elle passe par une chaine pour rester
  // lisible dans le source : ecrit en litteral, le motif serait invisible.
  const strip = new RegExp("[\\u0300-\\u036f]", "g");
  const fold = (value: string) =>
    value.trim().toLowerCase().normalize("NFD").replace(strip, "");
  const needle = fold(query);
  if (!needle) return COUNTRIES;
  return COUNTRIES.filter(
    (country) =>
      fold(country.label).includes(needle) ||
      country.code.toLowerCase().includes(needle) ||
      country.dial.includes(needle),
  );
}
