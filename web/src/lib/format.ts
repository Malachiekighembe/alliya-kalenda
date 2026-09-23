/// Formatage à la française, calqué sur lib/core/formatting.dart (Flutter).

export function money(value: number): string {
  return new Intl.NumberFormat("fr-FR", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(value);
}

/// Montant compact pour les cartes, ex. `18,5 k $`.
export function compactMoney(value: number): string {
  const abs = Math.abs(value);
  const trim = (v: number) => {
    const rounded = Math.round(v * 10) / 10;
    return Number.isInteger(rounded) ? String(rounded) : rounded.toFixed(1);
  };
  if (abs >= 1_000_000) return `${trim(value / 1_000_000)} M $`;
  if (abs >= 1_000) return `${trim(value / 1_000)} k $`;
  return money(value);
}

/// Libellé relatif d'un message : `14:32` aujourd'hui, `Hier`, `il y a 3 j`.
export function clockLabel(time: Date): string {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const day = new Date(time.getFullYear(), time.getMonth(), time.getDate());
  const diff = Math.round((today.getTime() - day.getTime()) / 86_400_000);
  if (diff <= 0) {
    return `${String(time.getHours()).padStart(2, "0")}:${String(
      time.getMinutes(),
    ).padStart(2, "0")}`;
  }
  if (diff === 1) return "Hier";
  if (diff < 7) return `il y a ${diff} j`;
  return new Intl.DateTimeFormat("fr-FR", {
    day: "2-digit",
    month: "2-digit",
  }).format(time);
}

/// Deux lettres initiales pour les avatars.
export function initials(name: string): string {
  const parts = name.split(" ").filter(Boolean);
  if (parts.length === 0) return "?";
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
}

/// Date courte, ex. `3 nov. 2026`.
export function formatDate(value: Date): string {
  return new Intl.DateTimeFormat("fr-FR", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(value);
}

/// Urgence d'une échéance, ex. `dans 48 j` ou `en retard de 12 j`.
export function deadlineHint(value: Date): string {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const target = new Date(value.getFullYear(), value.getMonth(), value.getDate());
  const days = Math.round((target.getTime() - today.getTime()) / 86_400_000);
  if (days === 0) return "aujourd’hui";
  if (days > 0) return `dans ${days} j`;
  return `dépassée de ${Math.abs(days)} j`;
}