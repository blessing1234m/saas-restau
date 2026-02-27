import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  // console.log('Amorçage de la base de données...');

  // Supprimer les anciens SuperAdmin s'ils existent
  try {
    const deleted = await prisma.utilisateur.deleteMany({
      where: { 
        codeAgent: { in: ['SuperAdmin', 'admin', 'SUPER'] }
      },
    });
    if (deleted.count > 0) {
      // console.log(`${deleted.count} utilisateurs supprimés`);
    }
  } catch (e) {
    // Ignorer l'erreur si les utilisateurs n'existent pas
  }

  // Test 1: SuperAdmin 1
  const salt = await bcrypt.genSalt(10);
  const motDePasseHash = await bcrypt.hash('Superad123', salt);

  const superAdmin = await prisma.utilisateur.create({
    data: {
      codeAgent: 'SuperAdmin',
      motDePasse: motDePasseHash,
      role: 'SUPER_ADMIN',
      estActif: true,
    },
  });

  // console.log('SuperAdmin 1 créé:');
  // console.log('Code Agent: SuperAdmin');
  // console.log('   Mot de passe: Superad123');
  // console.log('   Mot de passe hashé:', motDePasseHash);

  // Test 2: 2e SuperAdmin 
  const simpleHash = await bcrypt.hash('SUPERADMIN', salt);
  const testUser = await prisma.utilisateur.create({
    data: {
      codeAgent: 'SUPER',
      motDePasse: simpleHash,
      role: 'SUPER_ADMIN',
      estActif: true,
    },
  });

  // console.log('SuperAdmin 2 créé:');
  // console.log('   Code Agent: SUPER');
  // console.log('   Mot de passe: SUPERADMIN');
}

main()
  .then(async () => {
    await prisma.$disconnect();
    // console.log('Amorçage terminé');
  })
  .catch(async (e) => {
    console.error('Erreur lors de l\'amorçage:', e);
    await prisma.$disconnect();
    process.exit(1);
  });
