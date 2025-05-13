/**
 * index.ts – Point d’entrée Cloud Functions
 * Structure des fichiers :
 *   • utils.ts               → constantes & helpers partagés
 *   • firestoreValidators.ts → validateEloAfterGame, validateGameDocument
 *   • rtdbValidators.ts   → validateGameCreation, validateGameMetadataUpdate, validateGamePlayerUpdate
 *   • watchdogs.ts         → fonctions planifiées (déconnexion, durée, cleanup)
 */

export * from "./firestoreValidator"; // Firestore triggers
export * from "./rtdbValidator"; // Realtime DB triggers
export * from "./watchogTask"; // Scheduled tasks
