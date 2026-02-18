/*
  Warnings:

  - The `photoAffichage` column on the `Categorie` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- AlterTable
ALTER TABLE "Categorie" ADD COLUMN     "photoNomFichier" TEXT,
ADD COLUMN     "photoTaille" INTEGER,
ADD COLUMN     "photoTypeContenu" TEXT,
DROP COLUMN "photoAffichage",
ADD COLUMN     "photoAffichage" BYTEA;
