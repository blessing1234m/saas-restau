-- CreateEnum
CREATE TYPE "CategorieEtablissement" AS ENUM ('SIMPLE', 'PRIVILEGE');

-- AlterTable
ALTER TABLE "Etablissement" ADD COLUMN     "categorie" "CategorieEtablissement" NOT NULL DEFAULT 'SIMPLE';
