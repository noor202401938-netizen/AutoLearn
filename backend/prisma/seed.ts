import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Start seeding...');
  
  // Check if admin exists
  const existingAdmin = await prisma.user.findUnique({
    where: { email: 'admin@autolearn.com' }
  });

  if (!existingAdmin) {
    const hashedPassword = await bcrypt.hash('admin123', 10);
    const admin = await prisma.user.create({
      data: {
        email: 'admin@autolearn.com',
        password: hashedPassword,
        displayName: 'Super Admin',
        role: 'admin',
      }
    });
    console.log(`Created admin user with id: ${admin.id}`);
  } else {
    console.log('Admin user already exists.');
  }

  console.log('Seeding finished.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
