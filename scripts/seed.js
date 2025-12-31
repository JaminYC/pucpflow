const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();

const departments = [
  { id: 'tumbes', name: 'Tumbes', region: 'costa', tags: ['playa', 'avistamiento'] },
  { id: 'piura', name: 'Piura', region: 'costa', tags: ['gastronomia', 'playa'] },
  { id: 'lambayeque', name: 'Lambayeque', region: 'costa', tags: ['museos', 'cultura'] },
  { id: 'cajamarca', name: 'Cajamarca', region: 'sierra', tags: ['andino', 'historia'] },
  { id: 'amazonas', name: 'Amazonas', region: 'selva', tags: ['bosque', 'cataratas'] },
  { id: 'la_libertad', name: 'La Libertad', region: 'costa', tags: ['arqueologia', 'costa'] },
  { id: 'ancash', name: 'Ancash', region: 'sierra', tags: ['montana', 'lagunas'] },
  { id: 'san_martin', name: 'San Martin', region: 'selva', tags: ['selva', 'cascadas'] },
  { id: 'loreto', name: 'Loreto', region: 'selva', tags: ['amazonas', 'fauna'] },
  { id: 'ucayali', name: 'Ucayali', region: 'selva', tags: ['rio', 'aventura'] },
  { id: 'lima', name: 'Lima', region: 'costa', tags: ['urbano', 'costa'] },
  { id: 'callao', name: 'Callao', region: 'costa', tags: ['puerto', 'mar'] },
  { id: 'huanuco', name: 'Huanuco', region: 'sierra', tags: ['bosques', 'clima'] },
  { id: 'pasco', name: 'Pasco', region: 'sierra', tags: ['altiplano', 'lagunas'] },
  { id: 'junin', name: 'Junin', region: 'sierra', tags: ['valle', 'tradicion'] },
  { id: 'ica', name: 'Ica', region: 'costa', tags: ['desierto', 'pisco'] },
  { id: 'huancavelica', name: 'Huancavelica', region: 'sierra', tags: ['andino', 'rutas'] },
  { id: 'ayacucho', name: 'Ayacucho', region: 'sierra', tags: ['arte', 'cultura'] },
  { id: 'apurimac', name: 'Apurimac', region: 'sierra', tags: ['caminatas', 'canon'] },
  { id: 'cusco', name: 'Cusco', region: 'sierra', tags: ['incas', 'montanas'] },
  { id: 'arequipa', name: 'Arequipa', region: 'sierra', tags: ['volcan', 'canones'] },
  { id: 'moquegua', name: 'Moquegua', region: 'costa', tags: ['valles', 'vino'] },
  { id: 'tacna', name: 'Tacna', region: 'costa', tags: ['frontera', 'desierto'] },
  { id: 'puno', name: 'Puno', region: 'sierra', tags: ['lago', 'altiplano'] },
  { id: 'madre_de_dios', name: 'Madre de Dios', region: 'selva', tags: ['biodiversidad', 'selva'] },
];

const routeTemplates = [
  { suffix: 'ruta_1', name: 'Circuito esencial', durationDays: 2, difficulty: 'baja' },
  { suffix: 'ruta_2', name: 'Travesia natural', durationDays: 4, difficulty: 'media' },
  { suffix: 'ruta_3', name: 'Exploracion extensa', durationDays: 6, difficulty: 'alta' },
];

function seasonForRegion(region) {
  switch (region) {
    case 'selva':
      return 'may-oct';
    case 'sierra':
      return 'may-sept';
    case 'costa':
      return 'dic-mar';
    default:
      return '--';
  }
}

function isoWeekNumber(date) {
  const target = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const day = target.getUTCDay() || 7;
  target.setUTCDate(target.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(target.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((target.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
  return week;
}

async function seed() {
  let batch = db.batch();
  let writeCount = 0;

  const topRouteSummary = [];

  for (const dept of departments) {
    const deptRef = db.collection('departments').doc(dept.id);
    batch.set(deptRef, {
      name: dept.name,
      region: dept.region,
      tags: dept.tags,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    writeCount++;

    const routeIds = [];
    for (const template of routeTemplates) {
      const routeId = `${dept.id}_${template.suffix}`;
      routeIds.push(routeId);
      const routeRef = db.collection('routes').doc(routeId);
      batch.set(routeRef, {
        deptId: dept.id,
        name: `${dept.name} - ${template.name}`,
        durationDays: template.durationDays,
        difficulty: template.difficulty,
        summary: `Ruta base para ${dept.name}.`,
        tags: ['ruta', dept.region],
      });
      writeCount++;
      topRouteSummary.push({
        id: routeId,
        name: `${dept.name} - ${template.name}`,
        deptId: dept.id,
        durationDays: template.durationDays,
      });
    }

    const statsRef = db.collection('stats').doc(dept.id);
    batch.set(statsRef, {
      routesCount: routeTemplates.length,
      placesCount: 0,
      featuredRouteId: routeIds[0],
      recommendedSeason: seasonForRegion(dept.region),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });
    writeCount++;

    const signalsRef = db.collection('signals').doc(dept.id);
    batch.set(signalsRef, {
      weatherSummary: 'Condiciones estables. Revisa antes de viajar.',
      alerts: [],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    writeCount++;

    if (writeCount >= 400) {
      await batch.commit();
      batch = db.batch();
      writeCount = 0;
    }
  }

  topRouteSummary.sort((a, b) => b.durationDays - a.durationDays);
  const highlightedDepartments = departments.slice(0, 2).map((dept) => dept.id);
  const curationRef = db.collection('curation').doc('currentWeek');
  batch.set(curationRef, {
    week: isoWeekNumber(new Date()),
    highlightedDepartments,
    topRoutes: topRouteSummary.slice(0, 5),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  writeCount++;

  if (writeCount > 0) {
    await batch.commit();
  }

  console.log('Seed data loaded successfully.');
}

seed().catch((error) => {
  console.error('Seed error:', error);
  process.exit(1);
});
