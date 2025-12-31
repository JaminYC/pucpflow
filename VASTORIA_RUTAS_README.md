# VASTORIA - Rutas Peru (MVP)

Estructura creada:
- `flutter_app/` -> app Flutter Android/iOS (Mapbox + Firestore)
- `firebase_functions/` -> Cloud Functions (weeklySync) + rules
- `scripts/` -> seed de datos iniciales

## 1) Requisitos
- Flutter SDK
- Node.js 18+
- Firebase CLI (`npm i -g firebase-tools`)
- Cuenta de Mapbox y token

## 2) Firebase (Firestore + apps mobile)
1. Crea un proyecto en Firebase.
2. Habilita Firestore (modo production o test).
3. Agrega apps:
   - Android: package name del proyecto Flutter.
   - iOS: bundle id del proyecto Flutter.
4. Descarga y coloca:
   - `flutter_app/android/app/google-services.json`
   - `flutter_app/ios/Runner/GoogleService-Info.plist`

## 3) Mapbox token
Reemplaza `YOUR_MAPBOX_ACCESS_TOKEN` en:
- `flutter_app/android/app/src/main/AndroidManifest.xml`
- `flutter_app/ios/Runner/Info.plist`

Tambien puedes ejecutar:
```
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=TU_TOKEN
```

## 4) Instalar dependencias Flutter
```
cd flutter_app
flutter pub get
```

## 5) Correr la app
```
cd flutter_app
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=TU_TOKEN
```

## 6) Seed de datos (25 departamentos + rutas + stats + signals)
1. Crea un service account en Firebase (Project Settings -> Service accounts).
2. Descarga el JSON y exporta la variable:
```
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\service-account.json
```
3. Ejecuta el seed:
```
cd scripts
npm install
node seed.js
```

## 7) Cloud Functions (weeklySync)
```
cd firebase_functions
npm install
npm run build
firebase deploy --only functions
```
Notas:
- `weeklySync` corre cada domingo 02:00 America/Lima.
- Asegura que Cloud Scheduler y App Engine esten habilitados en el proyecto.

## 8) Firestore rules
Usa el archivo `firebase_functions/firestore.rules` como base y publicalo en Firebase Console.

## 9) Datos esperados en Firestore (ejemplos)
departments/{deptId}
```
{
  "name": "Cusco",
  "region": "sierra",
  "tags": ["incas", "montanas"]
}
```

routes/{routeId}
```
{
  "deptId": "cusco",
  "name": "Cusco - Circuito esencial",
  "durationDays": 2,
  "difficulty": "baja",
  "summary": "Ruta base para Cusco.",
  "tags": ["ruta", "sierra"]
}
```

stats/{deptId}
```
{
  "routesCount": 3,
  "placesCount": 0,
  "featuredRouteId": "cusco_ruta_1",
  "recommendedSeason": "may-sept",
  "lastUpdated": <timestamp>
}
```

signals/{deptId}
```
{
  "weatherSummary": "Condiciones estables. Revisa antes de viajar.",
  "alerts": [],
  "updatedAt": <timestamp>
}
```

curation/currentWeek
```
{
  "week": 12,
  "highlightedDepartments": ["lima", "cusco"],
  "topRoutes": [
    {"id": "cusco_ruta_3", "deptId": "cusco", "name": "Cusco - Exploracion extensa", "durationDays": 6}
  ],
  "updatedAt": <timestamp>
}
```

## 10) GeoJSON de departamentos
`flutter_app/assets/peru_departments.geojson` es un placeholder de grilla.
Puedes reemplazarlo por un GeoJSON real manteniendo:
- `properties.id` (ej: "cusco")
- `properties.name`
- `properties.region`

