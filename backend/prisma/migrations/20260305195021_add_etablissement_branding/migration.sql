-- AlterTable
ALTER TABLE "Etablissement" ADD COLUMN     "banniereAffichage" BYTEA,
ADD COLUMN     "banniereNomFichier" TEXT,
ADD COLUMN     "banniereTaille" INTEGER,
ADD COLUMN     "banniereTypeContenu" TEXT,
ADD COLUMN     "logoAffichage" BYTEA,
ADD COLUMN     "logoNomFichier" TEXT,
ADD COLUMN     "logoTaille" INTEGER,
ADD COLUMN     "logoTypeContenu" TEXT;
