import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import * as functions from "firebase-functions/v1";
import {
  isAuthorizedAdmin,
  normalizeDeleteUserRequest,
  shouldDeleteAuthUserOnSoftDelete,
} from "./userDeletion";

initializeApp();

const region = "asia-southeast2";

async function deleteAuthUserAndMarkFirestore(userId: string): Promise<void> {
  const userRef = getFirestore().collection("users").doc(userId);

  try {
    await getAuth().deleteUser(userId);
    await userRef.set({
      authDeletedAt: FieldValue.serverTimestamp(),
      authDeleteStatus: "deleted",
      authDeleteError: FieldValue.delete(),
    }, {merge: true});
  } catch (error) {
    const code = typeof error === "object" && error !== null &&
      "code" in error ? String(error.code) : "";

    if (code === "auth/user-not-found") {
      await userRef.set({
        authDeletedAt: FieldValue.serverTimestamp(),
        authDeleteStatus: "not_found",
        authDeleteError: FieldValue.delete(),
      }, {merge: true});
      return;
    }

    functions.logger.error("Gagal menghapus Firebase Auth user", {
      userId,
      error,
    });
    await userRef.set({
      authDeleteStatus: "failed",
      authDeleteError: "Gagal menghapus akun Auth. Cek Cloud Functions logs.",
      authDeleteFailedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    throw error;
  }
}

export const deleteUserForTesting = functions
  .region(region)
  .https
  .onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Login admin diperlukan.",
      );
    }

    if (!isAuthorizedAdmin(context.auth.token)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Akses admin diperlukan.",
      );
    }

    const userId = normalizeDeleteUserRequest(data ?? {});
    const userRef = getFirestore().collection("users").doc(userId);
    const userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "User tidak ditemukan.",
      );
    }

    const userData = userSnapshot.data() ?? {};
    const email = typeof userData.email === "string" ?
      userData.email.trim() : "";
    const emailLower = typeof userData.emailLower === "string" ?
      userData.emailLower.trim() : email.toLowerCase();

    await userRef.set({
      isDeleted: true,
      deletedAt: FieldValue.serverTimestamp(),
      deletedBy: context.auth.uid,
      deletedEmail: email || FieldValue.delete(),
      deletedEmailLower: emailLower || FieldValue.delete(),
      email: FieldValue.delete(),
      emailLower: FieldValue.delete(),
      status: "Dihapus",
    }, {merge: true});

    await deleteAuthUserAndMarkFirestore(userId);

    return {ok: true};
  });

export const deleteAuthUserWhenSoftDeleted = functions
  .region(region)
  .firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    if (!shouldDeleteAuthUserOnSoftDelete(beforeData, afterData)) {
      return;
    }

    const userId = context.params.userId;
    await deleteAuthUserAndMarkFirestore(userId);
  });
