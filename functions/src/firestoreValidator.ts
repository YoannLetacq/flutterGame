/**
 * firestoreValidators.ts – valide les operations Firestore
 * ---------------------------------------
 * @function validateEloAfterGame -  gameResults/{gameId}
 * @function validateGameDocument -  games/{gameId}
 */

import {
  DEFAULT_REGION,
  db,
  calculateEloChanges,
  K_INIT,
  K_STANDARD,
  PLACEMENT_GAME_LIMIT,
  EPSILON,
} from "./utils";
import * as functions from "firebase-functions/v1";

/**
 * @function  validateEloAfterGame
 * @param {string} gameId - ID de la partie
 * @param { QueryDocumentSnapshot } snap - Données de la partie
 * @description Recalcule l’Elo serveur, corrige si le client a déjà
 * touché users/{uid}.elo et journalise la variation.
 */
export const validateEloAfterGame = functions
  .region(DEFAULT_REGION)
  .firestore.document("gameResults/{gameId}")
  .onCreate(async (snap) => {
    const game = snap.data();
    const required = [
      "playerId",
      "opponentId",
      "playerScore",
      "opponentScore",
    ] as const;
    for (const f of required) {
      if (game[f] === undefined) {
        await snap.ref.update({
          validation: {valid: false, reason: `Champ manquant : ${f}`},
        });
        return;
      }
    }

    const {playerId, opponentId, playerScore, opponentScore} = game;

    await db.runTransaction(async (tx) => {
      // 1) Elo AVANT la partie (état actuel en base avant modif serveur)
      const pRef = db.collection("users").doc(playerId);
      const oRef = db.collection("users").doc(opponentId);
      const [pSnapBefore, oSnapBefore] = await Promise.all([
        tx.get(pRef),
        tx.get(oRef),
      ]);

      const pEloBefore = (pSnapBefore.data()?.elo ?? 1000) as number;
      const oEloBefore = (oSnapBefore.data()?.elo ?? 1000) as number;

      // 2) Recalcul variation attendue côté serveur
      const pPlacement = (pSnapBefore.data()?.placementGamesPlayed ??
        PLACEMENT_GAME_LIMIT) as number;
      const oPlacement = (oSnapBefore.data()?.placementGamesPlayed ??
        PLACEMENT_GAME_LIMIT) as number;
      const kP = pPlacement < PLACEMENT_GAME_LIMIT ? K_INIT : K_STANDARD;
      const kO = oPlacement < PLACEMENT_GAME_LIMIT ? K_INIT : K_STANDARD;

      const deltaP = calculateEloChanges(
        pEloBefore,
        oEloBefore,
        playerScore,
        kP,
      );
      const deltaO = calculateEloChanges(
        oEloBefore,
        pEloBefore,
        opponentScore,
        kO,
      );

      const expectedPEloAfter = pEloBefore + deltaP;
      const expectedOEloAfter = oEloBefore + deltaO;

      // 3) Relecture « après » : si le client a déjà touché à elo, on le verra ici.
      const [pSnapNow, oSnapNow] = await Promise.all([
        tx.get(pRef),
        tx.get(oRef),
      ]);
      const pEloNow = (pSnapNow.data()?.elo ?? 1000) as number;
      const oEloNow = (oSnapNow.data()?.elo ?? 1000) as number;

      const obsDeltaP = pEloNow - pEloBefore;
      const obsDeltaO = oEloNow - oEloBefore;

      const pOk = Math.abs(obsDeltaP - deltaP) < EPSILON;
      const oOk = Math.abs(obsDeltaO - deltaO) < EPSILON;

      if (!pOk || !oOk) {
        // Incohérence : on corrige les Elo et marque invalide
        tx.update(pRef, {elo: expectedPEloAfter});
        tx.update(oRef, {elo: expectedOEloAfter});
        tx.update(snap.ref, {
          validation: {
            valid: false,
            reason: "Elo client incorrect – ajusté par le serveur",
          },
          serverExpected: {
            deltaPlayer: deltaP,
            deltaOpponent: deltaO,
            eloPlayerAfter: expectedPEloAfter,
            eloOpponentAfter: expectedOEloAfter,
          },
        });
        return;
      }

      // Tout est cohérent → on écrit l’Elo officiel (si pas déjà la bonne valeur)
      if (!pOk) tx.update(pRef, {elo: expectedPEloAfter});
      if (!oOk) tx.update(oRef, {elo: expectedOEloAfter});

      tx.update(snap.ref, {
        validation: {valid: true},
        deltaPlayer: deltaP,
        deltaOpponent: deltaO,
        eloPlayerAfter: expectedPEloAfter,
        eloOpponentAfter: expectedOEloAfter,
      });
    });
  });

/**
 * @function  validateGameDocument
 * @param {string} gameId - ID de la partie
 * @param { Change<DocumentSnapshot> } change - Données de la partie
 */
export const validateGameDocument = functions
  .region(DEFAULT_REGION)
  .firestore.document("games/{gameId}")
  .onWrite(async (change, ctx) => {
    const isCreate = !change.before.exists;
    const data = change.after.exists ? change.after.data() : null;
    if (!data) return;

    let valid = true;
    let reason = "";

    if (isCreate) {
      if (Object.keys(data.players ?? {}).length !== 2) {
        valid = false;
        reason = "2 joueurs requis";
      }
      if (!["CLASSIQUE", "CLASSEE"].includes(data.mode)) {
        valid = false;
        reason = "mode invalide";
      }
    } else {
      const beforeStatus = change.before.get("status");
      const afterStatus = data.status;
      const ok =
        (beforeStatus === "pending" && afterStatus === "ongoing") ||
        (beforeStatus === "ongoing" && afterStatus === "finished") ||
        beforeStatus === afterStatus;
      if (!ok) {
        valid = false;
        reason = "Transition status interdite";
      }
      if (
        beforeStatus === "ongoing" &&
        JSON.stringify(change.before.get("players")) !==
          JSON.stringify(data.players)
      ) {
        valid = false;
        reason = "Liste joueurs immuable";
      }
    }

    if (!valid) {
      await change.after.ref.update({validation: {valid: false, reason}});
      console.warn(
        "[validateGameDocument] Invalide",
        ctx.params.gameId,
        reason,
      );
    } else if (!data.validation?.valid) {
      await change.after.ref.update({validation: {valid: true}});
    }
  });
