import { PrismaClient } from '@prisma/client';

// Singleton PrismaClient instance — avoids creating multiple connection pools
// across controllers. In production, PrismaClient should be instantiated once.
const prisma = new PrismaClient();

export default prisma;
