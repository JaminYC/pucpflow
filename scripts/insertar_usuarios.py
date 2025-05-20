import firebase_admin
from firebase_admin import credentials, firestore

# Cargar clave de Firebase
cred = credentials.Certificate("firebase_key.json")
firebase_admin.initialize_app(cred)

# Cliente Firestore
db = firestore.client()

# Lista de usuarios
usuarios = [
    "Vidal Puma", "Nelson Roldan", "Kalil Powell", "Carlos Medrano",
    "Helbert Galdos", "Tomas Gallegos", "Emilia Machuca", "Gherson Gonzales",
    "Marco Ayllon", "Samuel Saunders", "Joseph Yauri", "Jamin Yauri"
]

# Insertar en Firestore
for nombre in usuarios:
    doc_ref = db.collection("users").document()
    doc_ref.set({
        "full_name": nombre,
        "password": nombre,
        "rol": "empresa",
        "username": nombre
    })

print("✅ Usuarios agregados exitosamente.")
