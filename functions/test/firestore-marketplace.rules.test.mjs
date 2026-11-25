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
    await setDoc(doc(database, "marketplaceAuctions", "auction-1"), {
      status: "active",
      sellerId: "alice",
      artifactId: "relic-2"
    });
    await setDoc(doc(database, "marketplaceAuctions", "auction-1", "bids", "bid-1"), {
      bidderId: "bob",
      amount: 300
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

test("marketplace listing documents cannot be read directly; callable browse is the public interface", async () => {
  await assertFails(getDoc(doc(alice, "marketplaceListings", "active-listing")));
  await assertFails(getDocs(query(
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

test("auction and exchange backing documents are callable-only and never directly readable", async () => {
  await assertFails(getDoc(doc(alice, "marketplaceAuctions", "auction-1")));
  await assertFails(getDoc(doc(alice, "marketplaceAuctions", "auction-1", "bids", "bid-1")));
  await assertFails(getDoc(doc(alice, "marketplaceExchanges", "exchange-1")));
  await assertFails(getDoc(doc(bob, "marketplaceExchanges", "exchange-1")));
  await assertFails(getDoc(doc(outsider, "marketplaceExchanges", "exchange-1")));
  await assertFails(setDoc(doc(alice, "marketplaceAuctions", "forged-auction"), { status: "active", sellerId: "alice" }));
  await assertFails(setDoc(doc(alice, "marketplaceAuctions", "auction-1", "bids", "forged-bid"), { bidderId: "alice", amount: 1 }));
  await assertFails(updateDoc(doc(alice, "marketplaceAuctions", "auction-1", "bids", "bid-1"), { amount: 999999 }));
  await assertFails(updateDoc(doc(alice, "marketplaceExchanges", "exchange-1"), {
    recipientId: "mallory"
  }));
});

test("transaction receipt documents are callable-only and cannot be read or forged directly", async () => {
  await assertFails(getDoc(doc(alice, "marketplaceTransactions", "transaction-1")));
  await assertFails(getDoc(doc(bob, "marketplaceTransactions", "transaction-1")));
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
