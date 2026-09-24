"use client";

import { useEffect, useState } from "react";
import { compactMoney } from "@/lib/format";

/// Compteur animé — équivalent web de `AnimatedCounter` Flutter : la valeur
/// monte de 0 à `value` avec une courbe ease-out-cubic (~850 ms).
///
/// `format` est une clé (et pas une fonction) car les props passées depuis un
/// server component doivent rester sérialisables (RSC).
export function Counter({
  value,
  format = "int",
  duration = 850,
  className = "",
}: {
  value: number;
  format?: "int" | "money" | "compact";
  duration?: number;
  className?: string;
}) {
  const [display, setDisplay] = useState(0);

  useEffect(() => {
    let raf = 0;
    const start = performance.now();
    const tick = (now: number) => {
      const t = Math.min((now - start) / duration, 1);
      const eased = 1 - Math.pow(1 - t, 3); // easeOutCubic
      setDisplay(value * eased);
      if (t < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [value, duration]);

  const label =
    format === "compact"
      ? compactMoney(display)
      : format === "money"
        ? `$${Math.round(display).toLocaleString("fr-FR")}`
        : String(Math.round(display));

  return <span className={className}>{label}</span>;
}