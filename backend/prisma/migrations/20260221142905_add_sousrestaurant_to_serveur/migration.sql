-- AlterTable
ALTER TABLE "Serveur" ADD COLUMN     "sousRestaurantId" TEXT;

-- CreateIndex
CREATE INDEX "Serveur_sousRestaurantId_idx" ON "Serveur"("sousRestaurantId");

-- AddForeignKey
ALTER TABLE "Serveur" ADD CONSTRAINT "Serveur_sousRestaurantId_fkey" FOREIGN KEY ("sousRestaurantId") REFERENCES "SousRestaurant"("id") ON DELETE SET NULL ON UPDATE CASCADE;
