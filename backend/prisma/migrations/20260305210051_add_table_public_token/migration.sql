/*
  Warnings:

  - A unique constraint covering the columns `[tokenPublic]` on the table `Table` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "Table" ADD COLUMN     "tokenPublic" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "Table_tokenPublic_key" ON "Table"("tokenPublic");
