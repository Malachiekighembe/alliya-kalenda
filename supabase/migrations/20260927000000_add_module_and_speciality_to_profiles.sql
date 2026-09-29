-- Catalogue des modules d'activite.
--
-- L'application se construit module par module : le catalogue vit en base et
-- non dans le code. Les clients lisent GET /api/v1/modules, y compris avant
-- toute session, pour proposer le choix a l'inscription.
CREATE TABLE IF NOT EXISTS "modules" (
    "id" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'planned',
    "promise" TEXT NOT NULL DEFAULT '',
    "cover" TEXT NOT NULL DEFAULT '',
    "icon" TEXT NOT NULL DEFAULT '',
    "highlights" JSONB NOT NULL DEFAULT '[]'::jsonb,
    "fields" JSONB NOT NULL DEFAULT '[]'::jsonb,
    "position" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "modules_pkey" PRIMARY KEY ("id")
);

-- Catalogue de depart : l'electricite est le premier module livre, les
-- suivants sont annonces mais pas encore selectionnables.
INSERT INTO "modules"
    ("id", "label", "status", "promise", "cover", "icon", "highlights", "fields", "position")
VALUES
    (
        'electricite',
        'Électricité',
        'available',
        'Tableaux, circuits, interventions et consommables, sur un seul poste.',
        '/covers/cover-03.jpg',
        'bolt',
        '["Suivi des tableaux et des circuits", "Interventions, pannes et disponibilité", "Consommables et matériel", "Devis, factures et relances"]',
        '[
            {"key":"jobTitle","label":"Votre métier","type":"select","options":["Électricien d''équipement","Électricien chef de chantier","Automaticien","Technicien CVC","Électrotechnicien","Chef d''équipe électricité","Autre"]},
            {"key":"companyName","label":"Entreprise ou équipe","type":"text","optional":true},
            {"key":"phone","label":"Téléphone","type":"text","optional":true},
            {"key":"certifications","label":"Certifications et habilitations","type":"text","optional":true}
        ]'::jsonb,
        1
    ),
    (
        'plomberie',
        'Plomberie',
        'planned',
        'Réseaux, robinetterie et colonnes, en cours de préparation.',
        '/covers/cover-02.jpg',
        'wrench',
        '["Reseaux et robinetterie", "Consommables"]',
        '[]'::jsonb,
        2
    ),
    (
        'climatisation',
        'Climatisation',
        'planned',
        'Climatisation et ventilation, en cours de préparation.',
        '/covers/cover-04.jpg',
        'wrench',
        '["Entretien et maintenance", "Facturation"]',
        '[]'::jsonb,
        3
    ),
    (
        'peinture',
        'Peinture',
        'planned',
        'Chantiers de finition, en cours de préparation.',
        '/covers/cover-01.jpg',
        'receipt',
        '["Devis et avancement", "Planning des équipes"]',
        '[]'::jsonb,
        4
    )
ON CONFLICT ("id") DO NOTHING;

-- Module d'activite et specialite.
--
-- L'inscription n'est plus un simple formulaire : l'utilisateur choisit un
-- module (electricite en premier) puis son metier, et ces informations
-- orientent ensuite l'outillage de son tableau de bord.
ALTER TABLE "profiles"
    ADD COLUMN IF NOT EXISTS "module" TEXT NOT NULL DEFAULT 'electricite',
    ADD COLUMN IF NOT EXISTS "job_title" TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS "certifications" TEXT NOT NULL DEFAULT '';
