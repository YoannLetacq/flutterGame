/**
 *  RTDB Validator - Valide les données et les operations de la base de données en temps réel
 */

import {
  DEFAULT_REGION,
  ALLOWED_GAME_RESULT,
  ALLOWED_PLAYER_STATUS,
  FINISHED_STATUES,
  MAX_CARDS,
  MAX_GAME_SEC,
} from "./utils";
import * as functions from "firebase-functions/v1";

/**
 * @function validateGameCreation - Valide la création d'une partie dans la rtdb
 * @argument DEFAULT_REGION - La région par défaut de la base de données
 * @argument refpath - Le chemin de la référence de la base de données*/

export const validateGameCreation = functions
  .region(DEFAULT_REGION)
  .database.ref("games/{gameId}")
  .onCreate(async (snapshot, ctx) => {
    const game = snapshot.val();
    let valid = true;
    let reason = "";

    // Vérifie que le nombre de joueur dans la partie
    if (Object.keys(game.players ?? {}).length !== 2) {
      valid = false;
      reason = "Il doit y avoir 2 joueurs dans la partie";
    }

    // Vérifie que le nombre de cartes dans la partie
    if ((game.cards ?? []).length < 20) {
      valid = false;
      reason = "≥20 cartes requises";
    }

    // Verfie les status des joueurs et la listes des cartes
    for (const pid of Object.keys(game.players ?? {})) {
      const p = game.players[pid];
      if (!Array.isArray(p.cardsOrder) || p.cardsOrder.length !== MAX_CARDS) {
        valid = false;
        reason = "cardsOrder invalide";
        break;
      }
      if (p.status !== "in game" || p.currentCardIndex !== 0 || p.score !== 0) {
        valid = false;
        reason = "état initial invalide";
        break;
      }
    }

    // Verifie le format du mode de la partie
    if (!["ranked", "casual"].includes(game.mode)) {
      valid = false;
      reason = "mode invalide";
    }

    // Update la db avec le status de validation
    // pour assurer le passage de la verification serveur
    await snapshot.ref.update({validation: {valid}});
    if (!valid) {
      console.warn(
        "[validateGameCreation] Invalide",
        ctx.params.gameId,
        reason,
      );
    }
  });

/**
 * @function validateGameResult - Valide les mises a jour de donnees de la partie
 * @argument DEFAULT_REGION - La région par défaut de la base de données
 * @argument {String} ref path - Le chemin de la référence de la base de données
 */

export const validateGameMetadataUpdate = functions
  .region(DEFAULT_REGION)
  .database.ref("/games/{gameId}")
  .onUpdate(async (change) => {
    const before = change.before.val();
    const after = change.after.val();

    const updates: Record<string, any> = {};
    let valid = true;
    let reason = "";

    // Verfie les donnes mise a jour pendant la partie et block les changements incoherents
    if (
      before.startTime !== undefined &&
      before.startTime !== after.startTime
    ) {
      valid = false;
      reason = "startTime immuable";
      updates["startTime"] = before.startTime;
    }
    if (before.modeSpeedUp === true && after.modeSpeedUp === false) {
      valid = false;
      reason = "modeSpeedUp ne peut repasser à false";
      updates["modeSpeedUp"] = true;
    }
    if (before.mode !== after.mode) {
      valid = false;
      reason = "mode immuable";
      updates["mode"] = before.mode;
    }
    if (JSON.stringify(before.cards) !== JSON.stringify(after.cards)) {
      valid = false;
      reason = "cards immuables";
      updates["cards"] = before.cards;
    }
    if (!valid) {
      updates["validation"] = {valid: false, reason};
      await change.after.ref.update(updates);
    }
  });

/**
 * @function validateGamePlayerUpdate - Valide les mises a jour de donnees des joueurs
 * @argument DEFAULT_REGION - La région par défaut de la base de données
 * @argument {String} ref path - Le chemin de la référence de la base de données
 * @argument {String} gameId - L'identifiant de la partie
 * @argument {String} playerId - L'identifiant du joueur
 */

export const validateGamePlayerUpdate = functions
  .region(DEFAULT_REGION)
  .database.ref("/games/{gameId}/players/{playerId}")
  .onWrite(async (change) => {
    const before = change.before.exists() ? change.before.val() : null;
    const after = change.after.exists() ? change.after.val() : null;

    if (!after) return null;
    let valid = true;
    let reason = "";
    const updates: Record<string, any> = {};

    // Verifie la validite des status des joueurs
    if (!ALLOWED_PLAYER_STATUS.has(after.status)) {
      valid = false;
      reason = "status interdit";
    }

    if (before) {
      const okTrans =
        (before.status === "in game" &&
          ["waitingOpponent", "abandon", "disconnected", "finished"].includes(
            after.status,
          )) ||
        (before.status === "waitingOpponent" && after.status === "finished") ||
        before.status === after.status;
      if (!okTrans) {
        valid = false;
        reason = "transition status invalide";
      }
    }

    // Verifie la validite des informations des joueurs (currentCardIndex, elapsedTime, score)
    if (after.currentCardIndex < 0 || after.currentCardIndex >= MAX_CARDS) {
      valid = false;
      reason = "index hors bornes";
    }
    if (before && after.currentCardIndex < before.currentCardIndex) {
      valid = false;
      reason = "index régresse";
    }
    if (after.currentCardIndex - (before?.currentCardIndex ?? 0) > 1) {
      valid = false;
      reason = "index saute >1";
    }
    if (after.elapsedTime < 0 || after.elapsedTime > MAX_GAME_SEC) {
      valid = false;
      reason = "elapsedTime hors bornes";
    }
    if (before && after.elapsedTime < before.elapsedTime) {
      valid = false;
      reason = "elapsedTime régresse";
    }
    if (
      !Number.isInteger(after.score) ||
      after.score < 0 ||
      after.score > MAX_CARDS
    ) {
      valid = false;
      reason = "score invalide";
    }
    if (after.score > after.currentCardIndex) {
      valid = false;
      reason = "score > index";
    }
    if (
      before &&
      FINISHED_STATUES.has(before.status) &&
      after.score !== before.score
    ) {
      valid = false;
      reason = "modif score après fin";
    }
    if (before && before.gameResult && before.gameResult !== after.gameResult) {
      valid = false;
      reason = "gameResult immuable";
    }
    if (after.gameResult && !ALLOWED_GAME_RESULT.has(after.gameResult)) {
      valid = false;
      reason = "gameResult invalide";
    }

    if (!valid) {
      updates["validation"] = {valid: false, reason};
      await change.after.ref.update(updates);
    } else if (!after.validation?.valid) {
      await change.after.ref.update({validation: {valid: true}});
    }
    return null;
  });
