import {describe, expect, it} from "vitest";
import {
  isAuthorizedAdmin,
  normalizeDeleteUserRequest,
  shouldDeleteAuthUserOnSoftDelete,
} from "./userDeletion";

describe("normalizeDeleteUserRequest", () => {
  it("accepts a non-empty uid string", () => {
    expect(normalizeDeleteUserRequest({userId: " abc123 "})).toBe("abc123");
  });

  it("rejects missing userId", () => {
    expect(() => normalizeDeleteUserRequest({})).toThrow("userId wajib diisi");
  });
});

describe("isAuthorizedAdmin", () => {
  it("allows admin role or admin claim", () => {
    expect(isAuthorizedAdmin({role: "admin"})).toBe(true);
    expect(isAuthorizedAdmin({admin: true})).toBe(true);
  });

  it("rejects non-admin callers", () => {
    expect(isAuthorizedAdmin({role: "pendonor"})).toBe(false);
    expect(isAuthorizedAdmin(undefined)).toBe(false);
  });
});

describe("shouldDeleteAuthUserOnSoftDelete", () => {
  it("runs only when user becomes soft deleted", () => {
    expect(shouldDeleteAuthUserOnSoftDelete(
      {isDeleted: false},
      {isDeleted: true},
    )).toBe(true);
  });

  it("does not rerun after auth deletion is processed", () => {
    expect(shouldDeleteAuthUserOnSoftDelete(
      {isDeleted: true},
      {isDeleted: true, authDeleteStatus: "deleted"},
    )).toBe(false);
  });
});
