import bcrypt from 'bcrypt';
import prisma from '../src/prisma';
import { syncSyllabus } from '../src/controllers/course.controller';

// Starter content so a fresh install has something real to learn from.
// Idempotent: anything that already exists (matched by title) is left alone.

const MICRO = {
  title: 'Principles of Microeconomics',
  description:
    'How prices coordinate millions of decisions. Build supply and demand from scratch, measure how strongly markets react, and see what happens when governments step in.',
  instructor: 'AutoLearn Faculty',
  category: 'Microeconomics',
  level: 'beginner',
  duration: 6,
  syllabus: [
    {
      title: 'Markets and prices',
      lessons: [
        {
          title: 'Scarcity and opportunity cost',
          type: 'reading',
          duration: 10,
          content: `Economics starts from one fact: wants are unlimited, resources are not. Every choice therefore has a cost — not just the money you pay, but the best alternative you give up. That is the **opportunity cost**.

If you spend Saturday working a shift that pays 80, the opportunity cost of going to a concert instead is the ticket price *plus* the 80 you didn't earn.

**Why it matters:** people, firms and governments respond to the full cost of a choice, not just the sticker price. Free university tuition still costs students the wages they could have earned.

Try it: list what you gave up to study today. That list is your opportunity cost.`,
        },
        {
          title: 'Demand: why the curve slopes down',
          type: 'reading',
          duration: 12,
          content: `A **demand curve** shows how much of a good buyers want at each price, holding everything else constant.

It slopes **down** because as the price rises:
1. **Substitution effect** — the good is now dearer relative to alternatives, so buyers switch.
2. **Income effect** — the same budget buys less, so buyers can afford less.

A change in price moves you **along** the curve. A change in anything else — income, tastes, the price of substitutes or complements, expectations, number of buyers — **shifts** the whole curve.

Example: if coffee gets more expensive, demand for tea (a substitute) shifts right; demand for coffee filters (a complement) shifts left.`,
        },
        {
          title: 'Supply and market equilibrium',
          type: 'reading',
          duration: 14,
          content: `A **supply curve** shows how much sellers offer at each price. It slopes **up**: higher prices make it worth producing more, even at higher marginal cost.

Where supply meets demand is the **equilibrium**: the price at which the quantity buyers want equals the quantity sellers offer.

- Price above equilibrium → **surplus** (unsold stock) → sellers cut prices.
- Price below equilibrium → **shortage** (queues, empty shelves) → prices get bid up.

To predict what happens after a shock, ask three questions:
1. Does it shift supply, demand, or both?
2. Which direction?
3. What happens to equilibrium price and quantity?

A drought shifts wheat supply left: price rises, quantity falls.`,
        },
        { title: 'Check: supply and demand', type: 'quiz', duration: 8 },
      ],
    },
    {
      title: 'Elasticity',
      lessons: [
        {
          title: 'Price elasticity of demand',
          type: 'reading',
          duration: 14,
          content: `**Price elasticity of demand** measures how strongly quantity demanded responds to price:

  elasticity = % change in quantity demanded ÷ % change in price

- |e| > 1 → **elastic** (buyers are price-sensitive)
- |e| < 1 → **inelastic** (buyers barely react)

Demand is more elastic when there are close substitutes, the good is a big share of the budget, it's a luxury rather than a necessity, and buyers have more time to adjust.

**The revenue rule:** if demand is inelastic, raising the price *increases* total revenue; if elastic, it *decreases* it. That is why petrol taxes raise a lot of money and why airlines discount seats for price-sensitive leisure travellers.`,
        },
        { title: 'Problem set: elasticity in the wild', type: 'assignment', duration: 30 },
      ],
    },
    {
      title: 'When governments intervene',
      lessons: [
        {
          title: 'Price ceilings and floors',
          type: 'reading',
          duration: 12,
          content: `A **price ceiling** is a legal maximum price. If it is set *below* equilibrium, quantity demanded exceeds quantity supplied: a **shortage**. Rent control is the classic example — cheaper rent for those who find a flat, but fewer flats and long waiting lists.

A **price floor** is a legal minimum. Set *above* equilibrium, it creates a **surplus**. Agricultural price supports leave governments buying and storing the excess.

Both create **deadweight loss**: trades that would have benefited buyer and seller simply don't happen.

A ceiling set *above* equilibrium, or a floor set *below* it, is **non-binding** — it changes nothing.`,
        },
        {
          title: 'Taxes and who really pays',
          type: 'reading',
          duration: 12,
          content: `A tax drives a wedge between what buyers pay and what sellers receive. Who bears the burden — the **incidence** — does not depend on who legally hands the money to the government.

**The less elastic side pays more.** If demand is inelastic (cigarettes), buyers absorb most of the tax through higher prices. If supply is inelastic (land), sellers absorb it.

Taxes also shrink the quantity traded, creating deadweight loss. The more elastic supply and demand are, the bigger that loss — one reason economists prefer taxing things people can't easily avoid.`,
        },
        { title: 'Final test', type: 'quiz', duration: 15 },
      ],
    },
  ],
};

// A subject-neutral course so a fresh install shows AutoLearn is a general LMS.
const STUDY = {
  title: 'Learning How to Learn',
  description: 'Evidence-based study techniques for any subject: how memory works, how to practise, and how to plan your time.',
  instructor: 'AutoLearn Faculty',
  category: 'Study Skills',
  level: 'beginner',
  duration: 2,
  syllabus: [
    {
      title: 'How memory works',
      lessons: [
        {
          title: 'Why rereading feels good but works badly',
          type: 'reading',
          duration: 8,
          content: `Rereading your notes feels productive because the material becomes familiar. But **familiarity is not memory**: recognising something on the page is much easier than recalling it from nothing.

The fix is **retrieval practice** — closing the book and trying to bring the idea back. Every successful recall strengthens the memory; every failed attempt shows you exactly what to study next.

Try it: after this lesson, write down the three main ideas without looking.`,
        },
        {
          title: 'Spacing and interleaving',
          type: 'reading',
          duration: 10,
          content: `**Spacing:** study a topic, leave it, and return later. Forgetting a little between sessions makes the next recall harder — and that effort is what makes it stick.

**Interleaving:** mix different kinds of problems in one session instead of doing twenty of the same type. It feels slower, but it trains you to recognise *which* method a problem needs.

A simple plan:
- Day 1: learn it
- Day 2: recall it
- Day 7: recall it again
- Day 30: one more time`,
        },
        { title: 'Check: study techniques', type: 'quiz', duration: 5 },
      ],
    },
    {
      title: 'Putting it into practice',
      lessons: [
        { title: 'Your study plan', type: 'assignment', duration: 20 },
      ],
    },
  ],
};

const STUDY_QUIZ = [
  {
    questionText: 'Which technique does the research suggest is most effective for long-term memory?',
    options: ['Rereading notes several times', 'Highlighting key sentences', 'Trying to recall the material without looking', 'Copying notes out neatly'],
    correctOptionIndex: 2,
    explanation: 'Retrieval practice strengthens memory far more than re-exposure to the same material.',
  },
  {
    questionText: 'Why does spacing out study sessions help?',
    options: ['It is less tiring', 'The effort of recalling after a gap strengthens memory', 'It means studying less in total', 'It avoids interleaving'],
    correctOptionIndex: 1,
    explanation: 'A little forgetting between sessions makes recall effortful, and effortful recall is what makes learning last.',
  },
  {
    questionText: 'Interleaving means…',
    options: ['Studying one topic until it is perfect', 'Mixing different types of problems in one session', 'Taking breaks every 25 minutes', 'Studying with a partner'],
    correctOptionIndex: 1,
    explanation: 'Mixing problem types trains you to choose the right method, not just to repeat one.',
  },
];

const SD_QUIZ = [
  {
    questionText: 'A drought destroys a third of the wheat harvest. What happens in the wheat market?',
    options: ['Demand shifts left; price falls', 'Supply shifts left; price rises', 'Supply shifts right; price falls', 'Nothing — droughts only affect farmers'],
    correctOptionIndex: 1,
    explanation: 'Less wheat is offered at every price, so supply shifts left: equilibrium price rises and quantity falls.',
  },
  {
    questionText: 'The price of coffee rises. What happens to the demand for tea, a substitute?',
    options: ['It shifts right', 'It shifts left', 'It moves along the curve', 'It is unaffected'],
    correctOptionIndex: 0,
    explanation: 'Some coffee drinkers switch to tea, so at every tea price more tea is demanded — the curve shifts right.',
  },
  {
    questionText: 'At the current price, sellers have large unsold stocks. The market price is…',
    options: ['Below equilibrium', 'At equilibrium', 'Above equilibrium', 'Impossible to tell'],
    correctOptionIndex: 2,
    explanation: 'Unsold stock is a surplus, which happens when price is above equilibrium. Sellers will cut prices.',
  },
  {
    questionText: 'Which of these moves you ALONG a demand curve rather than shifting it?',
    options: ['A rise in consumer incomes', 'A change in the good’s own price', 'A new advertising campaign', 'A fall in the price of a complement'],
    correctOptionIndex: 1,
    explanation: 'Only the good’s own price moves you along the curve; everything else shifts it.',
  },
];

const FINAL_QUIZ = [
  ...SD_QUIZ.slice(0, 2),
  {
    questionText: 'Demand for a medicine is very inelastic. If the producer raises its price, total revenue will…',
    options: ['Rise', 'Fall', 'Stay the same', 'Fall to zero'],
    correctOptionIndex: 0,
    explanation: 'With inelastic demand, quantity falls proportionally less than price rises, so revenue goes up.',
  },
  {
    questionText: 'A rent ceiling set below the equilibrium rent will most likely cause…',
    options: ['A surplus of flats', 'A shortage of flats', 'No change', 'Higher rents'],
    correctOptionIndex: 1,
    explanation: 'Below equilibrium, more people want flats than landlords offer — a shortage.',
  },
  {
    questionText: 'A tax is placed on a good with very inelastic demand and elastic supply. Who bears most of the tax?',
    options: ['Sellers', 'Buyers', 'It is split exactly in half', 'The government'],
    correctOptionIndex: 1,
    explanation: 'The less elastic side bears more of the burden — here, buyers.',
  },
  {
    questionText: 'Which good is likely to have the MOST elastic demand?',
    options: ['Table salt', 'Insulin', 'One particular brand of cereal', 'Electricity'],
    correctOptionIndex: 2,
    explanation: 'A single brand has many close substitutes, so buyers switch easily when its price rises.',
  },
];

function toQuestions(qs: typeof SD_QUIZ) {
  return qs.map((q, i) => ({
    questionId: `q${i + 1}`,
    questionText: q.questionText,
    type: 'multiple_choice',
    options: q.options.map((text, j) => ({ optionId: `q${i + 1}o${j + 1}`, text })),
    correctOptionIndex: q.correctOptionIndex,
    explanation: q.explanation,
    points: 1,
  }));
}

async function main() {
  console.log('Start seeding...');

  if (!(await prisma.user.findUnique({ where: { email: 'admin@autolearn.com' } }))) {
    const admin = await prisma.user.create({
      data: {
        email: 'admin@autolearn.com',
        password: await bcrypt.hash(process.env.SEED_ADMIN_PASSWORD || 'admin123', 10),
        displayName: 'Super Admin',
        role: 'admin',
      },
    });
    console.log(`Created admin user with id: ${admin.id}`);
  }

  let course = await prisma.course.findFirst({ where: { title: MICRO.title } });
  if (!course) {
    const { syllabus, ...fields } = MICRO;
    course = await prisma.course.create({ data: { ...fields, isPublished: true, createdBy: 'seed' } });
    await syncSyllabus(course.id, syllabus);

    const lessons = await prisma.lesson.findMany({ where: { module: { courseId: course.id } }, include: { module: true } });
    const byTitle = (t: string) => lessons.find((l) => l.title === t)!;

    for (const [title, qs, desc] of [
      ['Check: supply and demand', SD_QUIZ, 'Four questions on shifts, movements and equilibrium.'],
      ['Final test', FINAL_QUIZ, 'Pass with 70% to earn your certificate.'],
    ] as const) {
      const l = byTitle(title);
      await prisma.quiz.create({
        data: {
          courseId: course.id, moduleId: l.moduleId, lessonId: l.id, title, description: desc,
          questions: toQuestions([...qs]), timeLimit: qs.length * 2, passingScore: 70, createdBy: 'seed',
        },
      });
    }

    const ps = byTitle('Problem set: elasticity in the wild');
    await prisma.assignment.create({
      data: {
        courseId: course.id, moduleId: ps.moduleId, lessonId: ps.id,
        title: 'Elasticity in the wild',
        description: 'Apply price elasticity to two real products.',
        instructions:
          'Pick two products you buy regularly: one you think has elastic demand and one inelastic.\n' +
          '1. For each, explain which determinants of elasticity (substitutes, budget share, necessity, time) apply.\n' +
          '2. If each product’s price rose 10%, what would happen to the seller’s total revenue? Explain using the revenue rule.\n' +
          '3. Which of the two would be the better target for a government tax, and why?\n' +
          'Aim for 250–400 words.',
        dueDate: new Date(Date.now() + 14 * 86_400_000),
        maxPoints: 100,
        createdBy: 'seed',
      },
    });
    console.log(`Created course "${course.title}" with ${lessons.length} lessons`);
  }

  let study = await prisma.course.findFirst({ where: { title: STUDY.title } });
  if (!study) {
    const { syllabus, ...fields } = STUDY;
    study = await prisma.course.create({ data: { ...fields, isPublished: true, createdBy: 'seed' } });
    await syncSyllabus(study.id, syllabus);
    const lessons = await prisma.lesson.findMany({ where: { module: { courseId: study.id } } });
    const byTitle = (t: string) => lessons.find((l) => l.title === t)!;
    const q = byTitle('Check: study techniques');
    await prisma.quiz.create({
      data: {
        courseId: study.id, moduleId: q.moduleId, lessonId: q.id, title: q.title, description: 'Three quick questions.',
        questions: toQuestions(STUDY_QUIZ), timeLimit: 6, passingScore: 70, createdBy: 'seed',
      },
    });
    const a = byTitle('Your study plan');
    await prisma.assignment.create({
      data: {
        courseId: study.id, moduleId: a.moduleId, lessonId: a.id, title: 'Your study plan',
        description: 'Plan the next two weeks of study for a course you are taking.',
        instructions:
          'Choose one subject you are learning.\n' +
          '1. List the topics you need to know.\n' +
          '2. Schedule spaced review sessions for each over two weeks.\n' +
          '3. Describe how you will use retrieval practice in each session (not rereading).\n' +
          'Aim for 150–300 words.',
        dueDate: new Date(Date.now() + 14 * 86_400_000), maxPoints: 50, createdBy: 'seed',
      },
    });
    console.log(`Created course "${study.title}" with ${lessons.length} lessons`);
  }

  if (!(await prisma.learningPath.findFirst({ where: { title: 'Start here' } }))) {
    await prisma.learningPath.create({
      data: {
        title: 'Start here',
        description: 'New to AutoLearn? Learn how to study well, then put it to work on your first subject course.',
        level: 'beginner',
        skills: ['Retrieval practice', 'Spaced study', 'Planning'],
        courseIds: [study.id, course.id],
      },
    });
    console.log('Created learning path "Start here"');
  }

  if (!(await prisma.learningPath.findFirst({ where: { title: 'Economics foundations' } }))) {
    await prisma.learningPath.create({
      data: {
        title: 'Economics foundations',
        description: 'Learn to think like an economist: trade-offs, markets, and how policy changes behaviour.',
        level: 'beginner',
        skills: ['Opportunity cost', 'Supply & demand', 'Elasticity', 'Policy analysis'],
        courseIds: [course.id],
      },
    });
    console.log('Created learning path "Economics foundations"');
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
