-- CreateEnum
CREATE TYPE "Role" AS ENUM ('SUPER_ADMIN', 'ADMIN_ETABLISSEMENT', 'SERVEUR');

-- CreateEnum
CREATE TYPE "StatutCommande" AS ENUM ('EN_ATTENTE', 'EN_PREPARATION', 'SERVIE');

-- CreateTable
CREATE TABLE "Utilisateur" (
    "id" TEXT NOT NULL,
    "codeAgent" TEXT NOT NULL,
    "motDePasse" TEXT NOT NULL,
    "role" "Role" NOT NULL,
    "estActif" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Utilisateur_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Etablissement" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "adresse" TEXT NOT NULL,
    "ville" TEXT NOT NULL,
    "codePostal" TEXT NOT NULL,
    "telephone" TEXT,
    "email" TEXT,
    "estActif" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Etablissement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdminEtablissement" (
    "id" TEXT NOT NULL,
    "utilisateurId" TEXT NOT NULL,
    "etablissementId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AdminEtablissement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SousRestaurant" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "etablissementId" TEXT NOT NULL,
    "estActif" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SousRestaurant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Table" (
    "id" TEXT NOT NULL,
    "numero" INTEGER NOT NULL,
    "capacite" INTEGER NOT NULL DEFAULT 2,
    "sousRestaurantId" TEXT NOT NULL,
    "estActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Table_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Categorie" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "photoAffichage" TEXT,
    "ordre" INTEGER NOT NULL DEFAULT 0,
    "sousRestaurantId" TEXT NOT NULL,
    "estActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Categorie_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Plat" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "prix" DOUBLE PRECISION NOT NULL,
    "categorieId" TEXT NOT NULL,
    "estActif" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Plat_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ImagePlat" (
    "id" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "ordre" INTEGER NOT NULL DEFAULT 0,
    "platId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ImagePlat_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Serveur" (
    "id" TEXT NOT NULL,
    "utilisateurId" TEXT NOT NULL,
    "etablissementId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Serveur_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Commande" (
    "id" TEXT NOT NULL,
    "tableId" TEXT NOT NULL,
    "sousRestaurantId" TEXT NOT NULL,
    "serveurId" TEXT NOT NULL,
    "statut" "StatutCommande" NOT NULL DEFAULT 'EN_ATTENTE',
    "totalCommande" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Commande_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ItemCommande" (
    "id" TEXT NOT NULL,
    "commandeId" TEXT NOT NULL,
    "platId" TEXT NOT NULL,
    "quantite" INTEGER NOT NULL DEFAULT 1,
    "prixUnitaire" DOUBLE PRECISION NOT NULL,
    "sousTotal" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ItemCommande_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Utilisateur_codeAgent_key" ON "Utilisateur"("codeAgent");

-- CreateIndex
CREATE INDEX "Utilisateur_codeAgent_idx" ON "Utilisateur"("codeAgent");

-- CreateIndex
CREATE INDEX "Etablissement_nom_idx" ON "Etablissement"("nom");

-- CreateIndex
CREATE UNIQUE INDEX "AdminEtablissement_utilisateurId_key" ON "AdminEtablissement"("utilisateurId");

-- CreateIndex
CREATE INDEX "AdminEtablissement_etablissementId_idx" ON "AdminEtablissement"("etablissementId");

-- CreateIndex
CREATE INDEX "SousRestaurant_etablissementId_idx" ON "SousRestaurant"("etablissementId");

-- CreateIndex
CREATE UNIQUE INDEX "SousRestaurant_etablissementId_nom_key" ON "SousRestaurant"("etablissementId", "nom");

-- CreateIndex
CREATE INDEX "Table_sousRestaurantId_idx" ON "Table"("sousRestaurantId");

-- CreateIndex
CREATE UNIQUE INDEX "Table_sousRestaurantId_numero_key" ON "Table"("sousRestaurantId", "numero");

-- CreateIndex
CREATE INDEX "Categorie_sousRestaurantId_idx" ON "Categorie"("sousRestaurantId");

-- CreateIndex
CREATE UNIQUE INDEX "Categorie_sousRestaurantId_nom_key" ON "Categorie"("sousRestaurantId", "nom");

-- CreateIndex
CREATE INDEX "Plat_categorieId_idx" ON "Plat"("categorieId");

-- CreateIndex
CREATE INDEX "ImagePlat_platId_idx" ON "ImagePlat"("platId");

-- CreateIndex
CREATE UNIQUE INDEX "Serveur_utilisateurId_key" ON "Serveur"("utilisateurId");

-- CreateIndex
CREATE INDEX "Serveur_etablissementId_idx" ON "Serveur"("etablissementId");

-- CreateIndex
CREATE INDEX "Commande_tableId_idx" ON "Commande"("tableId");

-- CreateIndex
CREATE INDEX "Commande_sousRestaurantId_idx" ON "Commande"("sousRestaurantId");

-- CreateIndex
CREATE INDEX "Commande_serveurId_idx" ON "Commande"("serveurId");

-- CreateIndex
CREATE INDEX "Commande_statut_idx" ON "Commande"("statut");

-- CreateIndex
CREATE INDEX "ItemCommande_commandeId_idx" ON "ItemCommande"("commandeId");

-- CreateIndex
CREATE INDEX "ItemCommande_platId_idx" ON "ItemCommande"("platId");

-- AddForeignKey
ALTER TABLE "AdminEtablissement" ADD CONSTRAINT "AdminEtablissement_utilisateurId_fkey" FOREIGN KEY ("utilisateurId") REFERENCES "Utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AdminEtablissement" ADD CONSTRAINT "AdminEtablissement_etablissementId_fkey" FOREIGN KEY ("etablissementId") REFERENCES "Etablissement"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SousRestaurant" ADD CONSTRAINT "SousRestaurant_etablissementId_fkey" FOREIGN KEY ("etablissementId") REFERENCES "Etablissement"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Table" ADD CONSTRAINT "Table_sousRestaurantId_fkey" FOREIGN KEY ("sousRestaurantId") REFERENCES "SousRestaurant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Categorie" ADD CONSTRAINT "Categorie_sousRestaurantId_fkey" FOREIGN KEY ("sousRestaurantId") REFERENCES "SousRestaurant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Plat" ADD CONSTRAINT "Plat_categorieId_fkey" FOREIGN KEY ("categorieId") REFERENCES "Categorie"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ImagePlat" ADD CONSTRAINT "ImagePlat_platId_fkey" FOREIGN KEY ("platId") REFERENCES "Plat"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Serveur" ADD CONSTRAINT "Serveur_utilisateurId_fkey" FOREIGN KEY ("utilisateurId") REFERENCES "Utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Serveur" ADD CONSTRAINT "Serveur_etablissementId_fkey" FOREIGN KEY ("etablissementId") REFERENCES "Etablissement"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Commande" ADD CONSTRAINT "Commande_tableId_fkey" FOREIGN KEY ("tableId") REFERENCES "Table"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Commande" ADD CONSTRAINT "Commande_sousRestaurantId_fkey" FOREIGN KEY ("sousRestaurantId") REFERENCES "SousRestaurant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Commande" ADD CONSTRAINT "Commande_serveurId_fkey" FOREIGN KEY ("serveurId") REFERENCES "Serveur"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ItemCommande" ADD CONSTRAINT "ItemCommande_commandeId_fkey" FOREIGN KEY ("commandeId") REFERENCES "Commande"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ItemCommande" ADD CONSTRAINT "ItemCommande_platId_fkey" FOREIGN KEY ("platId") REFERENCES "Plat"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
