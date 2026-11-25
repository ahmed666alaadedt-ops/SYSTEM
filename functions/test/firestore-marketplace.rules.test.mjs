import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where
} from "firebase/firestore";

let environment;
let alice;
let bob;
let outsider;
let unauthenticated;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: "demo-system-world",
    firestore: {
      rules: readFileSync(new URL("../../firestore.rules", import.meta.url), "utf8")
    }
  });

  await environment.withSecurityRulesDisabled(async (context) => {
    const database = context.firestore();
    await setDoc(doc(database, "marketplaceListings", "active-listing"), {
      status: "active",
      sellerId: "alice",
      artifactId: "relic-1",
      price: 250
    });
    await setDoc(doc(database, "marketplaceListings", "sold-listing"), {
      status: "sold",
      sellerId: "alice",
      artifactId: "relic-2",
      price: 100
    });
    await setDoc(doc(database, "systemWallets", "alice"), {
      balance: 500,
      reservedBalance: 0
    });
    await setDoc(doc(database, "artifactOwnership", "alice", "items", "relic-1"), {
      ownerId: "alice",
      status: "owned"
    });
    await setDoc(doc(database, "marketplaceExchanges", "exchange-1"), {
      status: "pending",
      initiatorId: "alice",
      recipientId: "bob",
      offeredArtifactId: "relic-1"
    });
    await setDoc(doc(database, "marketplaceTransactions", "transaction-1"), {
      buyerId: "alice",
      sellerId: "bob",
      artifactId: "relic-1",
      price: 250
    });
  });

  alice = environment.authenticatedContext("alice", { email: "alice@example.com" }).firestore();
  bob = environment.authenticatedContext("bob", { email: "bob@example.com" }).firestore();
  outsider = environment.authenticatedContext("mallory", { email: "mallory@example.com" }).firestore();
  unauthenticated = environment.unauthenticatedContext().firestore();
});

after(async () => {
  await environment?.cleanup();
});

test("active listings are readable by signed-in players, but inactive listings are hidden", async () => {
  await assertSucceeds(getDoc(doc(alice, "marketplaceListings", "active-listing")));
  await assertSucceeds(getDocs(query(
    collection(alice, "marketplaceListings"),
    where("status", "==", "active")
  )));
  await assertFails(getDoc(doc(alice, "marketplaceListings", "sold-listing")));
  await assertFails(getDoc(doc(unauthenticated, "marketplaceListings", "active-listing")));
});

test("clients cannot create, edit, or delete marketplace listings", async () => {
  await assertFails(setDoc(doc(alice, "marketplaceListings", "forged-listing"), {
    status: "active",
    sellerId: "alice",
    artifactId: "forged",
    price: 1
  }));
  await assertFails(updateDoc(doc(alice, "marketplaceListings", "active-listing"), {
    price: 1
  }));
  await assertFails(deleteDoc(doc(alice, "marketplaceListings", "active-listing")));
});

test("only the wallet owner may read a wallet and no client may mutate it", async () => {
  await assertSucceeds(getDoc(doc(alice, "systemWallets", "alice")));
  await assertFails(getDoc(doc(bob, "systemWallets", "alice")));
  await assertFails(setDoc(doc(alice, "systemWallets", "alice"), {
    balance: 999999,
    reservedBalance: 0
  }));
  await assertFails(updateDoc(doc(alice, "systemWallets", "alice"), {
    balance: 999999
  }));
});

test("artifact ownership is private to the owner and server-write-only", async () => {
  await assertSucceeds(getDoc(doc(alice, "artifactOwnership", "alice", "items", "relic-1")));
  await assertFails(getDoc(doc(bob, "artifactOwnership", "alice", "items", "relic-1")));
  await assertFails(updateDoc(doc(alice, "artifactOwnership", "alice", "items", "relic-1"), {
    ownerId: "mallory"
  }));
  await assertFails(deleteDoc(doc(alice, "artifactOwnership", "alice", "items", "relic-1")));
});

test("exchange offers are visible only to their two participants and remain server-write-only", async () => {
  await assertSucceeds(getDoc(doc(alice, "marketplaceExchanges", "exchange-1")));
  await assertSucceeds(getDoc(doc(bob, "marketplaceExchanges", "exchange-1")));
  await assertFails(getDoc(doc(outsider, "marketplaceExchanges", "exchange-1")));
  await assertFails(updateDoc(doc(alice, "marketplaceExchanges", "exchange-1"), {
    recipientId: "mallory"
  }));
});

test("transaction receipts are visible only to their buyer or seller", async () => {
  await assertSucceeds(getDoc(doc(alice, "marketplaceTransactions", "transaction-1")));
  await assertSucceeds(getDoc(doc(bob, "marketplaceTransactions", "transaction-1")));
  await assertFails(getDoc(doc(outsider, "marketplaceTransactions", "transaction-1")));
  await assertFails(setDoc(doc(alice, "marketplaceTransactions", "forged"), {
    buyerId: "alice",
    sellerId: "alice",
    price: 999999
  }));
});

test("unknown collections remain denied by the default-deny rule", async () => {
  await assertFails(getDoc(doc(alice, "unrecognizedMarketplaceData", "record")));
});
