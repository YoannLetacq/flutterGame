/** Utils & constant for Cloud functions
 * ----------------------------------------------
 * Centralise l'initialisation admin, les constantes metier et les helpers
 * @function calculateEloChanges - Calcule le changement de rating Elo d'un joueur après un match
 * @function sheduler - Crée une tâche planifiée à l'aide de Firebase Functions
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

// Initialisation de l'admin
if (!admin.app.length) {
  admin.initializeApp();
}

// export des instances firebases
export const db = admin.firestore();
export const rtdb = admin.database();

// region par defaut
export const DEFAULT_REGION = "europe-west1";

// constante Elo & jeu
export const K_INIT = 200;
export const K_STANDARD = 60;
export const PLACEMENT_GAME_LIMIT = 5;
export const EPSILON = 1e-6; // pour la precision des calculs
export const MAX_CARDS = 20; // nombre max de cartes par joueur
export const MAX_GAME_SEC = 360; // nombre max de secondes par partie
export const DISCONNECTED_TIMOUT = 60; // nombre de secondes avant de considerer un joueur deconnecte

// types et helpers
export const ALLOWED_PLAYER_STATUS = new Set([
  "in game",
  "finished",
  "disconnected",
  "abandon",
  "waitingOpponent",
]);

export const FINISHED_STATUES = new Set(["finished", "abandon"]);

export const ALLOWED_GAME_RESULT = new Set(["win", "loss", "draw"]);

/** calculateEloChanges
 * @param playerRating - Le rating du joueur
 * @param opponentRating - Le rating de l'adversaire
 * @param score - Le score du joueur (1 pour une victoire, 0.5 pour un match nul, 0 pour une défaite)
 * @param kFactor - Le facteur K utilisé pour le calcul
 * @return {number} Le changement de rating Elo
 * @description
 * Cette fonction calcule le changement de rating Elo d'un joueur après un match en utilisant la formule standard du système Elo.
 * Elle prend en compte le rating du joueur, le rating de l'adversaire, le score du match et le facteur K.
 */
export function calculateEloChanges(
  playerRating: number,
  opponentRating: number,
  score: number,
  kFactor: number,
): number {
  const expectedScore =
    1 / (1 + Math.pow(10, (opponentRating - playerRating) / 400));
  return Math.round(kFactor * (score - expectedScore));
}

/** sheduler
 * @param cron - La chaîne de cron pour la planification
 * @param handler - La fonction à exécuter
 * @description
 * Cette fonction crée une tâche planifiée à l'aide de Firebase Functions.
 */

export function sheduler(cron: string, handler: () => Promise<any>) {
  return functions
    .region(DEFAULT_REGION)
    .pubsub.schedule(cron)
    .timeZone("Europe/Paris")
    .onRun(handler);
}

export {admin, functions};
