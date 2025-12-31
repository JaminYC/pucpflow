import { onSchedule } from 'firebase-functions/v2/scheduler';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

initializeApp();
const db = getFirestore();

type DeptStatPreview = { deptId: string; routesCount: number };

export const weeklySync = onSchedule(
  { schedule: '0 2 * * 0', timeZone: 'America/Lima' },
  async () => {
    const departmentsSnap = await db.collection('departments').get();
    const deptStats: DeptStatPreview[] = [];

    for (const deptDoc of departmentsSnap.docs) {
      const deptId = deptDoc.id;
      const region = (deptDoc.data().region ?? 'sierra').toString();

      const routesSnap = await db
        .collection('routes')
        .where('deptId', '==', deptId)
        .get();

      const routesCount = routesSnap.size;
      let featuredRouteId = '';
      let topDuration = -1;
      for (const routeDoc of routesSnap.docs) {
        const duration = Number(routeDoc.data().durationDays ?? 0);
        if (duration > topDuration) {
          topDuration = duration;
          featuredRouteId = routeDoc.id;
        }
      }

      const placesSnap = await db
        .collection('places')
        .where('deptId', '==', deptId)
        .get();

      const placesCount = placesSnap.size;
      const recommendedSeason = seasonForRegion(region);

      await db.collection('stats').doc(deptId).set(
        {
          routesCount,
          placesCount,
          featuredRouteId,
          recommendedSeason,
          lastUpdated: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      deptStats.push({ deptId, routesCount });
    }

    deptStats.sort((a, b) => b.routesCount - a.routesCount);
    const highlightedDepartments = deptStats.slice(0, 2).map((d) => d.deptId);

    const topRoutesSnap = await db
      .collection('routes')
      .orderBy('durationDays', 'desc')
      .limit(5)
      .get();

    const topRoutes = topRoutesSnap.docs.map((doc) => ({
      id: doc.id,
      name: (doc.data().name ?? doc.id).toString(),
      deptId: (doc.data().deptId ?? '').toString(),
      durationDays: Number(doc.data().durationDays ?? 0),
    }));

    await db.collection('curation').doc('currentWeek').set(
      {
        week: isoWeekNumber(new Date()),
        highlightedDepartments,
        topRoutes,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);

function seasonForRegion(region: string): string {
  switch (region.toLowerCase()) {
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

function isoWeekNumber(date: Date): number {
  const target = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const day = target.getUTCDay() || 7;
  target.setUTCDate(target.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(target.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((target.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
  return week;
}
