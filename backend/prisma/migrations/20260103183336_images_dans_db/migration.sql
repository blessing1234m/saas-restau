/*
  Warnings:

  - You are about to drop the column `url` on the `ImagePlat` table. All the data in the column will be lost.
  - Added the required column `donnees` to the `ImagePlat` table without a default value. This is not possible if the table is not empty.
  - Added the required column `nomFichier` to the `ImagePlat` table without a default value. This is not possible if the table is not empty.
  - Added the required column `taille` to the `ImagePlat` table without a default value. This is not possible if the table is not empty.
  - Added the required column `typeContenu` to the `ImagePlat` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `ImagePlat` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "ImagePlat" DROP COLUMN "url",
ADD COLUMN     "donnees" BYTEA NOT NULL,
ADD COLUMN     "nomFichier" TEXT NOT NULL,
ADD COLUMN     "taille" INTEGER NOT NULL,
ADD COLUMN     "typeContenu" TEXT NOT NULL,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL;
