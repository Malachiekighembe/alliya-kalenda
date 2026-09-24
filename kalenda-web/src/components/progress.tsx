"use client";

import { useEffect, useState } from "react";

/// Barre de progression animée — équivalent web du `TweenAnimationBuilder`
/// Flutter : le remplissage part de 0 et rejoint `value` en ease-out-cubic
/// (~900 ms, cf. classe `.progress-fill` dans globals.css).
export function Progress({
  value,
  className = "",
  fillClassName = "bg-accent",
}: {
  value: number;
  className?: string;
  fillClassName?: string;
}) {
  const [width, setWidth] = useState(0);

  useEffect(() => {
    // Double rAF : le premier frame peint la largeur 0, le second déclenche
    // réellement la transition CSS vers la valeur cible.
    let inner = 0;
    const outer = requestAnimationFrame(() => {
      inner = requestAnimationFrame(() => setWidth(value));
    });
    return () => {
      cancelAnimationFrame(outer);
      cancelAnimationFrame(inner);
    };
  }, [value]);

  return (
    <div
      className={`overflow-hidden ${className}`.trim()}
      role="progressbar"
      aria-valuenow={Math.round(value)}
      aria-valuemin={0}
      aria-valuemax={100}
    >
      <div
        className={`progress-fill h-full rounded-full ${fillClassName}`.trim()}
        style={{ width: `${width}%` }}
      />
    </div>
  );
}