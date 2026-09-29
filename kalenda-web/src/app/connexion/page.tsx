"use client";

import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import {
  GOOGLE_CLIENT_ID,
  api,
  isApiConfigured,
  type ApiModule,
  type RegisterInput,
} from "@/lib/api";
import { findModule, isAvailable, type KalendaModuleDef } from "@/lib/modules";
import { useKalenda } from "@/context/kalenda-context";

/** Etapes du parcours d'inscription, dans l'ordre. */
const STEPS = ["Identité", "Module", "Métier"] as const;

/** Phrases affichees tant que l'API n'a pas repondu. */
const FALLBACK_PHRASES = [
  "Tableaux, circuits, interventions et consommables.",
  "Un outil par métier, adapté à votre façon de travailler.",
];

declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (config: {
            client_id: string;
            callback: (response: { credential: string }) => void;
          }) => void;
          renderButton: (
            parent: HTMLElement,
            options: Record<string, unknown>,
          ) => void;
        };
      };
    };
  }
}

/**
 * Adapte la reponse de l'API au type attendu par l'ecran. Les `highlights`
 * arrivent comme un tableau de libelles : pas d'icone a maintains ici, on
 * reutilise une puce generique.
 */
function toModule(raw: ApiModule): KalendaModuleDef {
  return {
    id: raw.id,
    label: raw.label,
    status: raw.status,
    promise: raw.promise,
    cover: raw.cover,
    highlights: raw.highlights ?? [],
    fields: (raw.fields ?? []).map((field) => ({
      key: field.key,
      label: field.label,
      type: field.type === "select" ? "select" : "text",
      options: field.options,
      optional: field.optional,
    })),
  };
}

/**
 * Bouton de connexion Google.
 *
 * Avec un Client ID configure, Google Identity Services rend son propre
 * bouton, conforme a la charte graphique Google. Sans Client ID, on garde la
 * meme apparence : l'ecran ne doit pas changer de forme selon la
 * configuration, et le clic explique ce qu'il manque.
 *
 * Google ne renvoie qu'un jeton d'identite : il est envoye au backend, qui
 * verifie la signature et l'audience puis delivre la session Alliya Kalenda.
 */
function GoogleButton({
  credential,
  onCredential,
  onUnavailable,
}: {
  credential: string;
  onCredential: (c: string) => void;
  onUnavailable: () => void;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const configured = credential.trim().length > 0;
  // Evite un saut de mise en page quand le script Google arrive.
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!configured) return;
    const check = window.setInterval(() => {
      if (window.google) {
        setReady(true);
        window.clearInterval(check);
      }
    }, 100);
    return () => window.clearInterval(check);
  }, [configured]);

  useEffect(() => {
    if (!configured || !ref.current) return;
    const start = () => {
      const target = ref.current;
      if (!target || target.childElementCount > 0 || !window.google) return;
      window.google.accounts.id.initialize({
        client_id: credential,
        callback: (response) => onCredential(response.credential),
      });
      window.google.accounts.id.renderButton(target, {
        type: "standard",
        theme: "outline",
        size: "large",
        text: "continue_with",
        width: 360,
        locale: "fr",
      });
    };

    if (window.google) {
      start();
      return;
    }
    const script = document.createElement("script");
    script.src = "https://accounts.google.com/gsi/client";
    script.async = true;
    script.defer = true;
    script.onload = start;
    document.head.appendChild(script);
    return () => {
      script.onload = null;
    };
  }, [credential, configured, onCredential]);

  // Repli tant que le script n'a pas charge, ou s'il n'est pas configure.
  if (!ready) {
    return (
      <button
        type="button"
        onClick={configured ? () => setReady(true) : onUnavailable}
        className="flex w-full items-center justify-center gap-2.5 rounded-lg border border-card-border bg-white px-3 py-2.5 text-[13.5px] font-semibold text-navy/70 transition hover:border-navy/25"
      >
        <GoogleMark />
        Continuer avec Google
      </button>
    );
  }

  return (
    <div className="flex justify-center [&>div]:!w-full [&>div]:!max-w-full">
      <div ref={ref} />
    </div>
  );
}

/** Logo Google aux couleurs officielles, pour le bouton de repli. */
function GoogleMark() {
  return (
    <svg viewBox="0 0 18 18" className="h-4 w-4 shrink-0" aria-hidden="true">
      <path
        fill="#4285F4"
        d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.92c1.7-1.57 2.68-3.88 2.68-6.62Z"
      />
      <path
        fill="#34A853"
        d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.92-2.26c-.8.54-1.84.86-3.04.86-2.34 0-4.32-1.58-5.03-3.7H.96v2.33A9 9 0 0 0 9 18Z"
      />
      <path
        fill="#FBBC05"
        d="M3.97 10.72a5.4 5.4 0 0 1 0-3.44V4.95H.96a9 9 0 0 0 0 8.1l3.01-2.33Z"
      />
      <path
        fill="#EA4335"
        d="M9 3.58c1.32 0 2.5.46 3.44 1.35l2.58-2.58C13.46.9 11.43 0 9 0A9 9 0 0 0 .96 4.95l3.01 2.33C4.68 5.16 6.66 3.58 9 3.58Z"
      />
    </svg>
  );
}

/** Champ de formulaire : libelle, saisie et styles partages. */
function TextField({
  id,
  label,
  type,
  value,
  onChange,
  placeholder,
  autoComplete,
  field,
  required,
}: {
  id: string;
  label: string;
  type: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  autoComplete?: string;
  field: string;
  required?: boolean;
}) {
  return (
    <div>
      <label htmlFor={id} className="text-[12px] font-bold text-navy">
        {label}
      </label>
      <input
        id={id}
        type={type}
        required={required ?? true}
        minLength={type === "password" ? 8 : undefined}
        autoComplete={autoComplete}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className={field}
        placeholder={placeholder}
      />
    </div>
  );
}

/** Puce d'une fonction du module. */
function Bullet() {
  return (
    <svg
      viewBox="0 0 24 24"
      className="h-3 w-3 shrink-0 fill-accent"
      aria-hidden="true"
    >
      <path d="M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2Z" />
    </svg>
  );
}

/**
 * Phrases qui defilent les unes apres les autres.
 *
 * Sous l'ecran de connexion, une seule ligne Defile plutot qu'une liste :
 * ca tient sur la place d'un slogan et allège l'ecran sur mobile.
 */
function RotatingPhrases({ phrases }: { phrases: string[] }) {
  const [index, setIndex] = useState(0);
  // Hauteur figee : la ligne ne doit pas sauter d'un libelle a l'autre.
  const [visible, setVisible] = useState(true);

  const list = phrases.length > 0 ? phrases : FALLBACK_PHRASES;

  useEffect(() => {
    if (list.length < 2) return;
    // `setInterval` est volontairement espace de la transition : la phrase
    // sort, puis la suivante entre.
    const out = window.setInterval(() => setVisible(false), 3600);
    const swap = window.setTimeout(
      () => {
        setIndex((current) => (current + 1) % list.length);
        setVisible(true);
      },
      4050,
    );
    return () => {
      window.clearInterval(out);
      window.clearTimeout(swap);
    };
  }, [list, index]);

  return (
    <span
      className={
        "block text-[12px] leading-snug text-navy/55 transition-all duration-500 " +
        (visible
          ? "translate-y-0 opacity-100"
          : "-translate-y-1 opacity-0")
      }
    >
      {list[index]}
    </span>
  );
}

/**
 * Logo + nom, repris sur petit ecran ou le panneau etant masque.
 *
 * Le sous-titre annonce l'outil, pas un module : Alliya Kalenda sert d'abord
 * a plusieurs metiers. Le module disponible, lui, est affiche a part, par le
 * panneau et la liste du parcours, toujours a partir de l'API.
 */
function Brand({ compact = false }: { compact?: boolean }) {
  return (
    <div className="flex items-center gap-2">
      <Image
        src="/icon.png"
        alt=""
        width={compact ? 32 : 36}
        height={compact ? 32 : 36}
        priority
        className={
          "rounded-lg object-cover " +
          (compact ? "" : "ring-1 ring-white/25")
        }
      />
      <div className="leading-tight">
        <p
          className={
            "font-extrabold tracking-tight " +
            (compact ? "text-sm text-navy" : "text-[15px] text-white")
          }
        >
          Alliya Kalenda
        </p>
        <p className="text-[10px] font-semibold uppercase tracking-wider text-accent">
          Outil métier
        </p>
      </div>
    </div>
  );
}

/** Séparation organique entre le panneau de marque et le formulaire. */
function Curve() {
  return (
    <svg
      viewBox="0 0 120 800"
      preserveAspectRatio="none"
      aria-hidden="true"
      className="pointer-events-none absolute inset-y-0 -left-[60px] hidden w-[120px] fill-navy lg:block"
    >
      <path d="M120 0C60 90 90 190 40 280S0 400 10 480s60 90 20 150-70 90-50 170Z" />
    </svg>
  );
}

/**
 * Panneau de presentation : marque, module mis en avant et ce que l'outil
 * sait faire. Les donnees viennent de l'API, pas du code.
 */
function BrandPanel({ modules }: { modules: KalendaModuleDef[] }) {
  const featured =
    modules.find((module) => isAvailable(module)) ?? modules[0] ?? null;

  return (
    <section className="relative hidden overflow-hidden bg-navy lg:flex lg:flex-col lg:justify-center lg:px-10">
      <div className="pointer-events-none absolute -left-20 top-12 h-64 w-64 rounded-full bg-accent/20 blur-3xl" />
      <div className="pointer-events-none absolute -right-8 bottom-16 h-64 w-64 rounded-full bg-amber/10 blur-3xl" />

      <div className="relative">
        <Brand />

        <h1 className="mt-7 max-w-sm text-[26px] font-extrabold leading-tight tracking-tight text-white">
          Tout votre travail,
          <span className="block text-accent">au même endroit.</span>
        </h1>
        <p className="mt-2 max-w-xs text-[12.5px] leading-relaxed text-white/60">
          Un outil par métier. Vous choisissez votre module, on adapte
          l&apos;ensemble à votre façon de travailler.
        </p>

        {/* Phrases rotatives : elles defilent au lieu de s'empiler, ce qui
            garde le panneau court quel que soit le nombre de modules. */}
        <div className="mt-3 h-9 max-w-xs">
          <RotatingPhrases
            phrases={modules.flatMap((module) =>
              module.promise ? [module.promise] : [],
            )}
          />
        </div>
      </div>

      {featured ? (
        <div className="relative mt-7 rounded-xl border border-white/15 bg-white/5 p-3.5">
          <div className="flex items-center gap-2.5">
            {featured.cover ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={featured.cover}
                alt=""
                className="h-9 w-9 rounded-lg object-cover"
              />
            ) : null}
            <p className="text-[13px] font-extrabold text-white">
              {featured.label}
            </p>
            <span className="rounded-full bg-accent/20 px-2 py-0.5 text-[10px] font-bold text-accent">
              Disponible
            </span>
          </div>
          <ul className="mt-2.5 space-y-1.5">
            {featured.highlights.slice(0, 4).map((text) => (
              <li
                key={text}
                className="flex items-center gap-2 text-[11.5px] text-white/70"
              >
                <Bullet />
                {text}
              </li>
            ))}
          </ul>
        </div>
      ) : null}

      {/* Les modules a venir, pour montrer que l'outil s'etend. */}
      {modules.length > 1 ? (
        <div className="relative mt-4">
          <p className="text-[10px] font-semibold uppercase tracking-wider text-white/35">
            Prochainement
          </p>
          <div className="mt-1.5 flex flex-wrap gap-1.5">
            {modules
              .filter((module) => !isAvailable(module))
              .map((module) => (
                <span
                  key={module.id}
                  className="rounded-full border border-white/10 px-2.5 py-1 text-[10.5px] font-semibold text-white/45"
                >
                  {module.label}
                </span>
              ))}
          </div>
        </div>
      ) : null}
    </section>
  );
}

export default function LoginPage() {
  const { login, register, loginWithGoogle, completeGoogleSignup, user, isOnline } =
    useKalenda();
  const router = useRouter();
  const pathname = usePathname();

  const [mode, setMode] = useState<"login" | "register">("login");
  // Un seul champ : e-mail ou numero. Le backend decide via la presence
  // d'un « @ », et nous n'imposons pas de choisir a l'avance.
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [passwordConfirm, setPasswordConfirm] = useState("");
  const [fullName, setFullName] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Catalogue : charge depuis l'API, jamais code en dur.
  const [modules, setModules] = useState<KalendaModuleDef[]>([]);
  const [modulesError, setModulesError] = useState(false);

  // Parcours d'inscription : etape, module choisi, specialite.
  const [step, setStep] = useState(0);
  const [moduleId, setModuleId] = useState<string | null>(null);
  const [speciality, setSpeciality] = useState<Record<string, string>>({});

  /**
   * Jeton Google en attente : quand une identite Google n'est pas encore
   * connue, l'ecran bascule sur le parcours et conserve le jeton pour
   * l'nregistrer a la fin. Sans cela, l'utilisateur devrait rejouer la
   * selection Google apres avoir choisi son module.
   */
  const [pendingGoogle, setPendingGoogle] = useState<{
    credential: string;
    message: string;
  } | null>(null);

  const selectedModule = findModule(modules, moduleId);

  useEffect(() => {
    if (!isApiConfigured()) return;
    // Annule la reponse si l'utilisateur quitte l'ecran entre-temps.
    let active = true;
    api.modules
      .list()
      .then((rows) => {
        if (!active) return;
        setModules(rows.map(toModule));
        setModulesError(false);
      })
      .catch(() => {
        if (!active) return;
        setModulesError(true);
      });
    return () => {
      active = false;
    };
  }, []);

  // Une session deja ouverte n'a rien a faire ici.
  useEffect(() => {
    if (user && isOnline && pathname === "/connexion") router.replace("/");
  }, [user, isOnline, pathname, router]);

  if (user && isOnline) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-navy p-6 text-sm font-semibold text-white/70">
        Redirection vers le tableau de bord…
      </div>
    );
  }

  const signInWithGoogle = async (credential: string) => {
    setBusy(true);
    setError(null);
    try {
      const result = await loginWithGoogle(credential);
      if (result.linked) {
        router.push("/");
        return;
      }
      // Compte Google inconnu : aucun jeton n'a ete emis. On bascule sur le
      // parcours en gardant le jeton, et l'e-mail Google est propose.
      setPendingGoogle({ credential, message: result.signup.message });
      setMode("register");
      setStep(0);
      setModuleId(null);
      setSpeciality({});
      setPassword("");
      setPasswordConfirm("");
      setError(result.signup.message);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Connexion impossible.");
    } finally {
      setBusy(false);
    }
  };

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!isApiConfigured()) {
      setError(
        "Aucune API configurée. Renseignez NEXT_PUBLIC_API_URL pour pointer " +
          "l'application vers le backend Alliya Kalenda.",
      );
      return;
    }
    // Le mot de passe se tape deux fois : une faute de frappe dans un
    // identifiant est irreversible si elle n'est pas vue.
    if (mode === "register" && password !== passwordConfirm) {
      setError("Les deux mots de passe ne correspondent pas.");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      if (mode === "login") {
        await login(identifier.trim(), password);
      } else if (pendingGoogle) {
        // Le compte vient de Google : on ne redemande ni e-mail ni nom, qui
        // sont deja connus et verifies.
        await completeGoogleSignup(pendingGoogle.credential, {
          password,
          module: moduleId ?? "",
          jobTitle: speciality.jobTitle ?? "",
          companyName: speciality.companyName ?? "",
          certifications: speciality.certifications ?? "",
          ...(speciality.phone ? { phone: speciality.phone } : {}),
        });
      } else {
        const isEmail = identifier.includes("@");
        const payload: RegisterInput = {
          ...(isEmail ? { email: identifier.trim() } : { phone: identifier.trim() }),
          password,
          fullName: fullName.trim(),
          module: moduleId ?? "",
          jobTitle: speciality.jobTitle ?? "",
          companyName: speciality.companyName ?? "",
          certifications: speciality.certifications ?? "",
        };
        await register(payload);
      }
      setPendingGoogle(null);
      router.push("/");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Connexion impossible.");
    } finally {
      setBusy(false);
    }
  };

  // Champs denses mais confortables au doigt : py-2.5 et une taille de texte
  // lisible restent acceptables sur telephone, ou l'on tape avec le pouce.
  const field =
    "mt-1 w-full rounded-lg border border-card-border bg-surface-low px-3 py-2.5 text-[14px] font-medium text-navy outline-none transition focus:border-accent focus:bg-white focus:ring-2 focus:ring-accent/20";

  const switchMode = () => {
    setMode(mode === "login" ? "register" : "login");
    setStep(0);
    setModuleId(null);
    setSpeciality({});
    setPasswordConfirm("");
    // Quitter le parcours Google abandonne aussi le jeton en attente.
    setPendingGoogle(null);
    setError(null);
  };

  return (
    // `overflow-hidden` est reserve au grand ecran : sur mobile il couperait
    // le defilement du formulaire sur les petits telephones.
    <main className="relative min-h-screen bg-app lg:grid lg:grid-cols-[1fr_1fr] lg:overflow-hidden lg:bg-navy">
      <BrandPanel modules={modules} />

      {/* `min-h-screen` est indispensable : sans hauteur, `items-center` n'a
          rien a centrer et le formulaire reste colle en haut. */}
      <section className="relative flex min-h-screen justify-center bg-app px-5 pb-10 pt-6 sm:items-center sm:py-8 lg:min-h-0 lg:px-8">
        <Curve />
        <div className="flex w-full max-w-[380px] flex-col justify-center">
          {/* Sur mobile, la marque se place en haut, hors du flux du formulaire
              pour rester visible pendant que l'utilisateur descend. */}
          <div className="mb-5 lg:hidden">
            <Brand compact />
          </div>

          {/* Titre et bascule. Le lien reste visible dans les deux sens :
              masquer celui de retour piegeait l'utilisateur dans le parcours
              d'inscription, sans moyen d'en sortir. */}
          <div className="flex items-start justify-between gap-3">
            <div>
              <h2 className="text-lg font-extrabold tracking-tight text-navy">
                {mode === "login" ? "Connexion" : "Créer un compte"}
              </h2>
              <p className="mt-0.5 text-[12.5px] text-navy/55">
                {mode === "login"
                  ? "Accédez à votre module et vos données."
                  : "Choisissez votre module, on adapte l'outil."}
              </p>
            </div>
            <button
              type="button"
              onClick={switchMode}
              className="shrink-0 py-1 text-[12.5px] font-bold text-accent"
            >
              {mode === "login" ? "Créer un compte" : "J'ai déjà un compte"}
            </button>
          </div>

          {/* Identité Google reconnue mais compte inconnu : on explique ce
              qu'il reste à faire plutôt que d'afficher une erreur. */}
          {pendingGoogle ? (
            <p className="mt-3 rounded-lg border border-accent/25 bg-accent/5 px-3 py-2 text-[12px] font-semibold text-navy/70">
              {pendingGoogle.message} Choisissez votre module et créez votre
              mot de passe.
            </p>
          ) : null}

          {/* Phrases rotatives : allègent l'ecran et montrent les modules.
              Reserve au mobile, le panneau desktop les affiche deja. */}
          <div className="mt-3 rounded-lg border border-accent/20 bg-accent/5 px-3 py-2 lg:hidden">
            <RotatingPhrases
              phrases={modules.flatMap((module) =>
                module.promise ? [module.promise] : [],
              )}
            />
          </div>
          {mode === "register" ? (
            <ol className="mt-4 flex items-center gap-1.5" aria-label="Étapes d'inscription">
              {STEPS.map((label, index) => (
                <li key={label} className="flex flex-1 items-center gap-1.5">
                  <span
                    aria-current={index === step ? "step" : undefined}
                    className={
                      "flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-[10px] font-extrabold " +
                      (index <= step
                        ? "bg-accent text-white"
                        : "bg-surface-high text-navy/40")
                    }
                  >
                    {index < step ? "✓" : index + 1}
                  </span>
                  <span
                    className={
                      "text-[11.5px] font-bold " +
                      (index <= step ? "text-navy" : "text-navy/35")
                    }
                  >
                    {label}
                  </span>
                </li>
              ))}
            </ol>
          ) : null}

          <form onSubmit={submit} className="mt-4 flex flex-col gap-3">
            {/* Le bouton Google reste toujours visible : c'est l'entree en
                matiere. Sans Client ID configure, il explique ce qu'il
                manque au lieu de disparaitre, ce qui donnait l'impression
                d'une fonctionnalite absente. */}
            {mode === "login" ? (
              <GoogleButton
                credential={GOOGLE_CLIENT_ID}
                onCredential={signInWithGoogle}
                onUnavailable={() =>
                  setError(
                    "Connexion Google non configurée. Renseignez " +
                      "NEXT_PUBLIC_GOOGLE_CLIENT_ID.",
                  )
                }
              />
            ) : null}

            {/* L'authentification par e-mail est toujours proposee, en
                connexion comme en inscription : le separateur ne depend pas
                de la presence du bouton Google. */}
            {mode === "login" ? (
              <div className="flex items-center gap-2">
                <span className="h-px flex-1 bg-card-border" />
                <span className="text-[11.5px] font-semibold text-navy/40">
                  ou par e-mail / téléphone
                </span>
                <span className="h-px flex-1 bg-card-border" />
              </div>
            ) : (
              <p className="text-[11.5px] font-semibold uppercase tracking-wide text-navy/40">
                Par e-mail ou téléphone
              </p>
            )}

            {/* Etape 1 — qui vous etes. Quand l'identite vient de Google,
                e-mail et nom sont deja connus : on ne les redemande pas. */}
            {mode === "login" || step === 0 ? (
              <>
                {mode === "register" && !pendingGoogle ? (
                  <TextField
                    id="fullName"
                    label="Nom complet"
                    type="text"
                    value={fullName}
                    onChange={setFullName}
                    placeholder="ex. Malachie Kighembe"
                    autoComplete="name"
                    field={field}
                  />
                ) : null}
                {mode === "register" && pendingGoogle ? null : (
                  <TextField
                    id="identifier"
                    label="E-mail ou numéro de téléphone"
                    type="text"
                    value={identifier}
                    onChange={setIdentifier}
                    placeholder="ex. contact@alliyakalenda.cd ou +243 81 000 0000"
                    autoComplete="username"
                    field={field}
                  />
                )}
                <TextField
                  id="password"
                  label="Mot de passe"
                  type="password"
                  value={password}
                  onChange={setPassword}
                  placeholder={
                    mode === "login"
                      ? "Votre mot de passe"
                      : "8 caractères minimum"
                  }
                  autoComplete={
                    mode === "login" ? "current-password" : "new-password"
                  }
                  field={field}
                />
                {/* A l'inscription, le mot de passe se tape deux fois : une
                    faute de frappe dans un identifiant est irreversible. */}
                {mode === "register" ? (
                  <TextField
                    id="passwordConfirm"
                    label="Confirmer le mot de passe"
                    type="password"
                    value={passwordConfirm}
                    onChange={setPasswordConfirm}
                    placeholder="Retapez votre mot de passe"
                    autoComplete="new-password"
                    field={field}
                  />
                ) : null}
              </>
            ) : null}

            {/* Etape 2 — le module d'activite, servi par l'API. */}
            {mode === "register" && step === 1 ? (
              <fieldset className="flex flex-col gap-1.5">
                <legend className="text-[12px] font-bold text-navy">
                  Quel module utilisez-vous ?
                </legend>
                {modulesError ? (
                  <p className="rounded-lg bg-amber/10 px-2.5 py-1.5 text-[11px] font-semibold text-amber-700">
                    Catalogue indisponible. Vérifiez que l&apos;API répond.
                  </p>
                ) : null}
                {modules.length === 0 && !modulesError ? (
                  <p className="text-[11.5px] text-navy/45">Chargement…</p>
                ) : null}
                {modules.map((module) => {
                  const planned = !isAvailable(module);
                  const active = moduleId === module.id;
                  return (
                    <button
                      key={module.id}
                      type="button"
                      disabled={planned}
                      aria-pressed={active}
                      onClick={() => setModuleId(module.id)}
                      className={
                        "flex items-center gap-2.5 rounded-lg border px-2.5 py-2 text-left transition " +
                        (active
                          ? "border-accent bg-accent/5 ring-2 ring-accent/20"
                          : planned
                            ? "cursor-not-allowed border-card-border bg-surface-low opacity-60"
                            : "border-card-border bg-surface-low hover:border-accent/40")
                      }
                    >
                      {module.cover ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={module.cover}
                          alt=""
                          className="h-8 w-8 shrink-0 rounded-md object-cover"
                        />
                      ) : null}
                      <span className="min-w-0 flex-1">
                        <span className="flex items-center gap-1.5">
                          <span className="text-[13px] font-extrabold text-navy">
                            {module.label}
                          </span>
                          {planned ? (
                            <span className="rounded-full bg-surface-high px-1.5 py-0.5 text-[9px] font-bold text-navy/50">
                              Bientôt
                            </span>
                          ) : null}
                        </span>
                        <span className="mt-0.5 block text-[11.5px] leading-snug text-navy/50">
                          {module.promise}
                        </span>
                      </span>
                    </button>
                  );
                })}
              </fieldset>
            ) : null}

            {/* Etape 3 — la specialite, pilotee par la definition du module. */}
            {mode === "register" && step === 2 && selectedModule ? (
              <>
                <ul className="rounded-lg border border-accent/20 bg-accent/5 p-2.5">
                  {selectedModule.highlights.slice(0, 4).map((text) => (
                    <li
                      key={text}
                      className="flex items-center gap-1.5 py-0.5 text-[12px] text-navy/70"
                    >
                      <Bullet />
                      {text}
                    </li>
                  ))}
                </ul>

                {selectedModule.fields.map((item) =>
                  item.type === "select" ? (
                    <div key={item.key}>
                      <label
                        htmlFor={item.key}
                        className="text-[11px] font-bold text-navy"
                      >
                        {item.label}
                      </label>
                      <select
                        id={item.key}
                        required={!item.optional}
                        value={speciality[item.key] ?? ""}
                        onChange={(e) =>
                          setSpeciality((prev) => ({
                            ...prev,
                            [item.key]: e.target.value,
                          }))
                        }
                        className={field}
                      >
                        <option value="">Choisir…</option>
                        {(item.options ?? []).map((option) => (
                          <option key={option} value={option}>
                            {option}
                          </option>
                        ))}
                      </select>
                    </div>
                  ) : (
                    <TextField
                      key={item.key}
                      id={item.key}
                      label={
                        item.optional
                          ? `${item.label} (facultatif)`
                          : item.label
                      }
                      type="text"
                      value={speciality[item.key] ?? ""}
                      onChange={(value) =>
                        setSpeciality((prev) => ({
                          ...prev,
                          [item.key]: value,
                        }))
                      }
                      field={field}
                      required={!item.optional}
                    />
                  ),
                )}
              </>
            ) : null}

            {/* Sous la connexion : sans bouton Google configure, il ne resterait
                que deux champs et un bouton, ce qui donne un formulaire vide. */}
            {mode === "login" ? (
              <div className="-mt-1 flex justify-end">
                <button
                  type="button"
                  onClick={() =>
                    setError(
                      "La réinitialisation arrive bientôt. Écrivez-nous si besoin.",
                    )
                  }
                  className="py-1 text-[12.5px] font-bold text-accent"
                >
                  Mot de passe oublié ?
                </button>
              </div>
            ) : null}

            {error ? (
              <p
                role="alert"
                className="rounded-lg bg-red-50 px-2.5 py-1.5 text-[11px] font-semibold text-red-700"
              >
                {error}
              </p>
            ) : null}

            {/* Navigation : les etapes intermediaires ne creent pas le compte. */}
            {mode === "register" ? (
              <div className="flex gap-2">
                {step > 0 ? (
                  <button
                    type="button"
                    onClick={() => {
                      setStep(step - 1);
                      setError(null);
                    }}
                    className="rounded-lg border border-card-border bg-white px-3 py-2 text-[13px] font-bold text-navy/70 transition hover:border-accent hover:text-accent"
                  >
                    Retour
                  </button>
                ) : null}
                {step < STEPS.length - 1 ? (
                  <button
                    type="button"
                    onClick={() => {
                      // Google fournit deja nom et e-mail : on ne les exige pas.
                      const missingIdentity = pendingGoogle
                        ? false
                        : !fullName.trim() || !identifier.trim();
                      if (missingIdentity || password.length < 8) {
                        setError(
                          "Renseignez votre identité et un mot de passe " +
                            "d'au moins 8 caractères.",
                        );
                        return;
                      }
                      if (password !== passwordConfirm) {
                        setError("Les deux mots de passe ne correspondent pas.");
                        return;
                      }
                      if (step === 1 && !moduleId) {
                        setError(
                          "Choisissez le module qui correspond à votre métier.",
                        );
                        return;
                      }
                      setError(null);
                      setStep(step + 1);
                    }}
                    className="flex-1 rounded-lg bg-accent px-3 py-2 text-[13px] font-bold text-white shadow-sm transition hover:bg-accent/90"
                  >
                    Continuer
                  </button>
                ) : null}
              </div>
            ) : null}

            {mode === "login" || step === STEPS.length - 1 ? (
              <button
                type="submit"
                disabled={busy}
                className="rounded-lg bg-accent px-3 py-2.5 text-[13px] font-bold text-white shadow-sm transition hover:bg-accent/90 disabled:opacity-60"
              >
                {busy
                  ? "Connexion…"
                  : mode === "login"
                    ? "Se connecter"
                    : "Créer mon compte"}
              </button>
            ) : null}
          </form>

        </div>
      </section>
    </main>
  );
}