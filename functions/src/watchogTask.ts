/**
 * watchdogTasks.ts – Fonctions planifiées (Pub/Sub)
 * -------------------------------------------------
 *  • @function watchdogDisconnected    – Convertit un joueur "disconnected" > 60 s en abandon/défaite
 *  • @function watchdogElapsedTime     – Force la fin d’une partie après 6 minutes
 *  • @function  cleanupFinishedGames   – Supprime les nœuds /games/{id} entièrement terminés
 */

import {
  rtdb,
  FINISHED_STATUES,
  DISCONNECTED_TIMOUT,
  MAX_GAME_SEC,
  sheduler,
} from "./utils";

/**
 * @function isOlderThan - Vérifie si un timestamp UNIX (ms) est plus vieux qu'un délai donné.
 * @param {number | undefined} ts - Le timestamp UNIX (ms) à vérifier.
 * @param {number} delaySec - Le délai en secondes.
 * @param {number} now - Le timestamp UNIX (ms) actuel (par défaut, Date.now()).
 * @returns {functions.pubsub.SchedulerTrigger} - Renvoie true si le timestamp UNIX (ms) `ts` est plus vieux que `delaySec`.
 */

function isOlderThan(
  ts: number | undefined,
  delaySec: number,
  now = Date.now(),
): boolean {
  return typeof ts === "number" && now - ts > delaySec * 1000;
}

/**
 * @function sheduler - Crée une tâche planifiée pour la région par défaut.
 * @param {string} schedule - La planification de la tâche (ex. "every 1 minutes").
 * @returns {functions.pubsub.SchedulerTrigger} - Renvoie une tâche planifiée.
 */

export const watchdogDisconnected = sheduler("every 1 minutes", async () => {
  const now = Date.now();
  const snap = await rtdb.ref("/games").once("value");
  const games = snap.val() ?? {};
  const updates: Record<string, any> = {};

  for (const [gid, game] of Object.entries<any>(games)) {
    const players = game.players ?? {};
    for (const [uid, p] of Object.entries<any>(players)) {
      if (
        p.status === "disconnected" &&
        isOlderThan(p.statusSince ?? p.disconnectedAt, DISCONNECTED_TIMOUT, now)
      ) {
        updates[`/games/${gid}/players/${uid}/status`] = "abandon";
        updates[`/games/${gid}/players/${uid}/gameResult`] = "loss";
      }
    }
  }
  if (Object.keys(updates).length) await rtdb.ref().update(updates);
});

/**
 * @function watchdogElapsedTime - Force la fin d’une partie après 6 minutes.
 * @returns {functions.pubsub.SchedulerTrigger} - Renvoie une tâche planifiée.
 */

export const watchdogElapsedTime = sheduler("every 1 minutes", async () => {
  const now = Date.now();
  const gamesSnap = await rtdb.ref("/games").once("value");
  const updates: Record<string, any> = {};

  for (const [gid, game] of Object.entries<any>(gamesSnap.val() ?? {})) {
    if (!game.startTime) continue;
    if (now - game.startTime > MAX_GAME_SEC * 1000) {
      const players = game.players ?? {};
      for (const [uid, p] of Object.entries<any>(players)) {
        if (!FINISHED_STATUES.has(p.status)) {
          updates[`/games/${gid}/players/${uid}/status`] = "finished";
          // Attribution du résultat : si l’adversaire a déjà fini, celui‑ci perd.
          updates[`/games/${gid}/players/${uid}/gameResult`] =
            p.status === "waitingOpponent" ? "win" : "loss";
        }
      }
    }
  }
  if (Object.keys(updates).length) await rtdb.ref().update(updates);
});

/**
 * @function cleanupFinishedGames - Supprime les nœuds /games/{id} entièrement terminés.
 * @returns {functions.pubsub.SchedulerTrigger} - Renvoie une tâche planifiée.
 */
export const cleanupFinishedGames = sheduler("every 5 minutes", async () => {
  const snap = await rtdb.ref("/games").once("value");
  const games = snap.val() ?? {};
  for (const [gid, game] of Object.entries<any>(games)) {
    const players = game.players ?? {};
    const everyoneDone = Object.values<any>(players).every((p) =>
      FINISHED_STATUES.has(p.status),
    );
    if (everyoneDone) {
      await rtdb.ref(`/games/${gid}`).remove();
    }
  }
});
