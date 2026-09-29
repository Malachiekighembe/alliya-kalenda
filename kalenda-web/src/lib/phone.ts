/**
 * Selection de l'indicatif pays pour la connexion par telephone.
 *
 * L'utilisateur saisit son numero national ; l'indicatif est ajoute par le
 * client avant l'envoi. Le backend normalise ensuite (espaces, tirets,
 * parentheses) avant de comparer au compte, ce qui rend la saisie tolerant.
 */

export type Country = {
  /** Code ISO 3166-1 alpha-2. */
  code: string;
  /** Indicatif telephonique international, sans « + ». */
  dial: string;
  label: string;
};

/**
 * Liste volontairement restreinte aux pays francophones et voisins, plus
 * quelques pays frequents. Un numero hors liste reste saisissable en ecrivant
 * l'indicatif complet dans le champ.
 */
export const COUNTRIES: Country[] = [
  { code: "CD", dial: "243", label: "République démocratique du Congo" },
  { code: "CG", dial: "242", label: "Congo" },
  { code: "CI", dial: "225", label: "Côte d'Ivoire" },
  { code: "CM", dial: "237", label: "Cameroun" },
  { code: "CF", dial: "236", label: "République centrafricaine" },
  { code: "GA", dial: "241", label: "Gabon" },
  { code: "GQ", dial: "240", label: "Guinée équatoriale" },
  { code: "TD", dial: "235", label: "Tchad" },
  { code: "AO", dial: "244", label: "Angola" },
  { code: "ZM", dial: "260", label: "Zambie" },
  { code: "MA", dial: "212", label: "Maroc" },
  { code: "DZ", dial: "213", label: "Algérie" },
  { code: "TN", dial: "216", label: "Tunisie" },
  { code: "SN", dial: "221", label: "Sénégal" },
  { code: "ML", dial: "223", label: "Mali" },
  { code: "BF", dial: "226", label: "Burkina Faso" },
  { code: "NE", dial: "227", label: "Niger" },
  { code: "BJ", dial: "229", label: "Bénin" },
  { code: "GN", dial: "224", label: "Guinée" },
  { code: "RW", dial: "250", label: "Rwanda" },
  { code: "BI", dial: "257", label: "Burundi" },
  { code: "UG", dial: "256", label: "Ouganda" },
  { code: "KE", dial: "254", label: "Kenya" },
  { code: "TZ", dial: "255", label: "Tanzanie" },
  { code: "MG", dial: "261", label: "Madagascar" },
  { code: "MU", dial: "230", label: "Maurice" },
  { code: "FR", dial: "33", label: "France" },
  { code: "BE", dial: "32", label: "Belgique" },
  { code: "CH", dial: "41", label: "Suisse" },
  { code: "CA", dial: "1", label: "Canada" },
];

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
