/*
  Warnings:

  - You are about to drop the column `adresse` on the `Etablissement` table. All the data in the column will be lost.
  - You are about to drop the column `codePostal` on the `Etablissement` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Etablissement" DROP COLUMN "adresse",
DROP COLUMN "codePostal";
