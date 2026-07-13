export interface DeleteUserRequest {
  userId?: unknown;
}

export type CallerClaims = Record<string, unknown>;

export function normalizeDeleteUserRequest(data: DeleteUserRequest): string {
  const userId = typeof data.userId === "string" ? data.userId.trim() : "";
  if (!userId) {
    throw new Error("userId wajib diisi");
  }

  return userId;
}

export function isAuthorizedAdmin(claims: CallerClaims | undefined): boolean {
  return claims?.admin === true || claims?.role === "admin";
}

export function shouldDeleteAuthUserOnSoftDelete(
  beforeData: FirebaseFirestore.DocumentData | undefined,
  afterData: FirebaseFirestore.DocumentData | undefined,
): boolean {
  if (!afterData) return false;

  const wasDeleted = beforeData?.isDeleted === true ||
    beforeData?.status === "Dihapus";
  const isDeleted = afterData.isDeleted === true ||
    afterData.status === "Dihapus";
  const alreadyProcessed = afterData.authDeleteStatus === "deleted" ||
    afterData.authDeleteStatus === "not_found";

  return !wasDeleted && isDeleted && !alreadyProcessed;
}
