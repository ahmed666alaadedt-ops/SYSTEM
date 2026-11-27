import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";

process.env.GCLOUD_PROJECT ||= "demo-system-world";
process.env.GOOGLE_CLOUD_PROJECT ||= "demo-system-world";
process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";

// Import after emulator environment and the Admin app have been configured.
const market = await import("../lib/index.js");
const db = getFirestore();

const testPrefix = "marketplace_emulator_" + randomUUID().replaceAll("-", "");
const uid = (label) => testPrefix + "_" + label;
const artifactId = (label) => testPrefix + "_artifact_" + label;

async function seedPlayer(playerId, balance = 0, reservedBalance = 0) {
  await db.collection("players").doc(playerId).set({
    userId: playerId,
    displayName: "Player " + playerId.slice(-12),
    email: playerId + "@example.test",
    avatarUrl: "",
    createdAt: Date.now()
  });
  await db.collection("systemWallets").doc(playerId).set({
    userId: playerId,
    currency: "SYSTEM",
    balance,
    reservedBalance,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp()
  });
}

async function seedArtifact(ownerId, id, extra = {}) {
  await db.collection("artifactOwnership").doc(ownerId).collection("items").doc(id).set({
    artifactId: id,
    ownerId,
    name: "ختم أثري اختباري",
    civilization: "Babylonian",
    rarity: "rare",
    condition: "excellent",
    authenticity: "verified",
    provenanceSummary: "Emulator-only fixture",
    status: "owned",
    acquiredAt: FieldValue.serverTimestamp(),
    ...extra
  });
}

function request(playerId, data = {}, claims = {}) {
  return {
    data,
    auth: playerId ? { uid: playerId, token: claims } : null
  };
}

async function call(name, playerId, data = {}, claims = {}) {
  const callable = market[name];
  assert.ok(callable && typeof callable.run === "function", name + " must be exported as a callable function");
  return callable.run(request(playerId, data, claims));
}

async function readArtifact(ownerId, id) {
  return db.collection("artifactOwnership").doc(ownerId).collection("items").doc(id).get();
}

before(async () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, "Firestore emulator host must be configured");
});

after(async () => {
  // The Firebase emulator is ephemeral in CI; fixtures use a unique prefix to
  // avoid collisions between tests and can be discarded with the emulator.
});

test("fixed-price listing locks a real artifact and purchase atomically transfers ownership and SYSTEM credits", async () => {
  const seller = uid("fixed_seller");
  const buyer = uid("fixed_buyer");
  const id = artifactId("fixed_sale");
  await seedPlayer(seller, 0);
  await seedPlayer(buyer, 1000);
  await seedArtifact(seller, id);

  const listing = await call("createArtifactListing", seller, {
    artifactId: id,
    price: 250,
    durationDays: 7
  });
  assert.equal(listing.success, true);
  const escrowed = await readArtifact(seller, id);
  assert.equal(escrowed.data().status, "escrow");
  assert.equal(escrowed.data().activeListingId, listing.listingId);

  const browse = await call("browseArtifactMarketplace", buyer, {});
  const publicListing = browse.listings.find((entry) => entry.listingId === listing.listingId);
  assert.ok(publicListing, "active listing should be visible through callable browse");
  assert.equal(publicListing.sellerName.startsWith("Player "), true);
  assert.equal(publicListing.isSeller, false);
  assert.equal("sellerId" in publicListing, false, "public projection must not expose seller UID");

  const result = await call("purchaseArtifactListing", buyer, { listingId: listing.listingId });
  assert.equal(result.success, true);
  assert.equal(result.price, 250);
  assert.equal((await readArtifact(seller, id)).exists, false);
  const transferred = await readArtifact(buyer, id);
  assert.equal(transferred.data().ownerId, buyer);
  assert.equal(transferred.data().status, "owned");
  assert.equal((await db.collection("marketplaceListings").doc(listing.listingId).get()).data().status, "sold");
  assert.equal((await db.collection("systemWallets").doc(buyer).get()).data().balance, 750);
  assert.equal((await db.collection("systemWallets").doc(seller).get()).data().balance, 250);
  const receipt = await db.collection("marketplaceTransactions").doc(result.transactionId).get();
  assert.equal(receipt.exists, true);
  assert.equal(receipt.data().buyerId, buyer);
  assert.equal(receipt.data().sellerId, seller);
  await assert.rejects(() => call("purchaseArtifactListing", buyer, { listingId: listing.listingId }));
});

test("self-purchase, unauthenticated purchase and insufficient balance are rejected without changing escrow", async () => {
  const seller = uid("guard_seller");
  const poorBuyer = uid("guard_buyer");
  const id = artifactId("guard_sale");
  await seedPlayer(seller, 0);
  await seedPlayer(poorBuyer, 10);
  await seedArtifact(seller, id);
  const listing = await call("createArtifactListing", seller, { artifactId: id, price: 80 });

  await assert.rejects(() => call("purchaseArtifactListing", seller, { listingId: listing.listingId }));
  await assert.rejects(() => call("purchaseArtifactListing", null, { listingId: listing.listingId }));
  await assert.rejects(() => call("purchaseArtifactListing", poorBuyer, { listingId: listing.listingId }));
  assert.equal((await readArtifact(seller, id)).data().status, "escrow");
  assert.equal((await db.collection("marketplaceListings").doc(listing.listingId).get()).data().status, "active");
  assert.equal((await db.collection("systemWallets").doc(poorBuyer).get()).data().balance, 10);
});

test("simultaneous purchases produce exactly one winner and one ownership transfer", async () => {
  const seller = uid("race_seller");
  const buyerA = uid("race_a");
  const buyerB = uid("race_b");
  const id = artifactId("race_sale");
  await seedPlayer(seller, 0);
  await seedPlayer(buyerA, 500);
  await seedPlayer(buyerB, 500);
  await seedArtifact(seller, id);
  const listing = await call("createArtifactListing", seller, { artifactId: id, price: 200 });

  const results = await Promise.allSettled([
    call("purchaseArtifactListing", buyerA, { listingId: listing.listingId }),
    call("purchaseArtifactListing", buyerB, { listingId: listing.listingId })
  ]);
  assert.equal(results.filter((result) => result.status === "fulfilled").length, 1);
  assert.equal(results.filter((result) => result.status === "rejected").length, 1);
  const winner = (await readArtifact(buyerA, id)).exists ? buyerA : buyerB;
  const loser = winner === buyerA ? buyerB : buyerA;
  assert.equal((await readArtifact(winner, id)).data().ownerId, winner);
  assert.equal((await readArtifact(loser, id)).exists, false);
  assert.equal((await readArtifact(seller, id)).exists, false);
  assert.equal((await db.collection("marketplaceListings").doc(listing.listingId).get()).data().status, "sold");
  assert.equal((await db.collection("systemWallets").doc(winner).get()).data().balance, 300);
  assert.equal((await db.collection("systemWallets").doc(loser).get()).data().balance, 500);
  assert.equal((await db.collection("systemWallets").doc(seller).get()).data().balance, 200);
});

test("seller cancellation and expired listing cleanup release escrow exactly once", async () => {
  const seller = uid("expiry_seller");
  const other = uid("expiry_other");
  const id = artifactId("expiry_sale");
  await seedPlayer(seller, 0);
  await seedPlayer(other, 100);
  await seedArtifact(seller, id);
  const listing = await call("createArtifactListing", seller, { artifactId: id, price: 50 });
  await assert.rejects(() => call("cancelArtifactListing", other, { listingId: listing.listingId }));
  await call("cancelArtifactListing", seller, { listingId: listing.listingId });
  assert.equal((await readArtifact(seller, id)).data().status, "owned");

  const expiringId = artifactId("expiring_sale");
  await seedArtifact(seller, expiringId);
  const expiring = await call("createArtifactListing", seller, { artifactId: expiringId, price: 40 });
  await db.collection("marketplaceListings").doc(expiring.listingId).update({
    expiresAt: Timestamp.fromMillis(Date.now() - 1000)
  });
  await call("expireArtifactListing", other, { listingId: expiring.listingId });
  assert.equal((await readArtifact(seller, expiringId)).data().status, "owned");
  assert.equal((await db.collection("marketplaceListings").doc(expiring.listingId).get()).data().status, "expired");
  await assert.rejects(() => call("expireArtifactListing", other, { listingId: expiring.listingId }));
});

test("auction bids reserve funds, release the outbid reservation and settle atomically after expiry", async () => {
  const seller = uid("auction_seller");
  const bidderA = uid("auction_a");
  const bidderB = uid("auction_b");
  const id = artifactId("auction_item");
  await seedPlayer(seller, 0);
  await seedPlayer(bidderA, 500);
  await seedPlayer(bidderB, 500);
  await seedArtifact(seller, id);

  const auction = await call("createArtifactAuction", seller, {
    artifactId: id,
    startingBid: 100,
    durationHours: 1
  });
  await call("placeArtifactAuctionBid", bidderA, { auctionId: auction.auctionId, amount: 100 });
  assert.equal((await db.collection("systemWallets").doc(bidderA).get()).data().reservedBalance, 100);
  await call("placeArtifactAuctionBid", bidderB, { auctionId: auction.auctionId, amount: 150 });
  assert.equal((await db.collection("systemWallets").doc(bidderA).get()).data().reservedBalance, 0);
  assert.equal((await db.collection("systemWallets").doc(bidderB).get()).data().reservedBalance, 150);

  await assert.rejects(() => call("placeArtifactAuctionBid", seller, { auctionId: auction.auctionId, amount: 200 }));
  await db.collection("marketplaceAuctions").doc(auction.auctionId).update({
    endsAt: Timestamp.fromMillis(Date.now() - 1000)
  });
  const settled = await call("settleExpiredArtifactAuction", uid("auction_observer"), { auctionId: auction.auctionId });
  assert.equal(settled.status, "sold");
  assert.equal(settled.winnerId, bidderB);
  assert.equal((await db.collection("systemWallets").doc(bidderB).get()).data().balance, 350);
  assert.equal((await db.collection("systemWallets").doc(bidderB).get()).data().reservedBalance, 0);
  assert.equal((await db.collection("systemWallets").doc(seller).get()).data().balance, 150);
  assert.equal((await readArtifact(seller, id)).exists, false);
  assert.equal((await readArtifact(bidderB, id)).data().ownerId, bidderB);
  const repeated = await call("settleExpiredArtifactAuction", uid("auction_observer"), { auctionId: auction.auctionId });
  assert.equal(repeated.alreadySettled, true);
});

test("two-player artifact exchange requires the addressed recipient and transfers both artifacts atomically", async () => {
  const initiator = uid("exchange_a");
  const recipient = uid("exchange_b");
  const outsider = uid("exchange_outsider");
  const offeredId = artifactId("exchange_offered");
  const requestedId = artifactId("exchange_requested");
  await seedPlayer(initiator, 0);
  await seedPlayer(recipient, 0);
  await seedPlayer(outsider, 0);
  await seedArtifact(initiator, offeredId, { name: "ختم بابل" });
  await seedArtifact(recipient, requestedId, { name: "لوح مسماري" });
  await db.collection("artifactRegistry").doc(requestedId).set({
    artifactId: requestedId,
    originalOwnerId: recipient,
    issuedAt: FieldValue.serverTimestamp()
  });

  const offer = await call("createArtifactExchangeOffer", initiator, {
    recipientId: recipient,
    offeredArtifactId: offeredId,
    requestedArtifactId: requestedId
  });
  assert.equal((await readArtifact(initiator, offeredId)).data().status, "escrow");
  await assert.rejects(() => call("acceptArtifactExchangeOffer", outsider, { exchangeId: offer.exchangeId }));
  const accepted = await call("acceptArtifactExchangeOffer", recipient, { exchangeId: offer.exchangeId });
  assert.equal(accepted.success, true);
  assert.equal((await readArtifact(initiator, offeredId)).exists, false);
  assert.equal((await readArtifact(recipient, offeredId)).data().ownerId, recipient);
  assert.equal((await readArtifact(recipient, requestedId)).exists, false);
  assert.equal((await readArtifact(initiator, requestedId)).data().ownerId, initiator);
  assert.equal((await db.collection("marketplaceExchanges").doc(offer.exchangeId).get()).data().status, "accepted");
});

test("trusted currency and artifact rewards are replay-safe and reject ordinary players", async () => {
  const player = uid("reward_player");
  const gameServer = uid("game_server");
  await seedPlayer(player, 0);

  await assert.rejects(() => call("awardMarketplaceCurrency", player, {
    playerId: player,
    eventId: "quest_reward_1",
    source: "verified_quest",
    amount: 75
  }));
  const award = await call("awardMarketplaceCurrency", gameServer, {
    playerId: player,
    eventId: "quest_reward_1",
    source: "verified_quest",
    referenceId: "quest-001",
    amount: 75
  }, { gameServer: true });
  assert.equal(award.alreadyAwarded, false);
  const replay = await call("awardMarketplaceCurrency", gameServer, {
    playerId: player,
    eventId: "quest_reward_1",
    source: "verified_quest",
    referenceId: "quest-001",
    amount: 75
  }, { gameServer: true });
  assert.equal(replay.alreadyAwarded, true);
  assert.equal((await db.collection("systemWallets").doc(player).get()).data().balance, 75);

  const relicId = artifactId("quest_relic");
  const rewardPayload = {
    playerId: player,
    eventId: "quest_artifact_1",
    artifactId: relicId,
    name: "ختم ملكي",
    civilization: "Babylonian",
    rarity: "legendary",
    condition: "excellent",
    authenticity: "verified",
    source: "verified_quest",
    referenceId: "quest-001"
  };
  await assert.rejects(() => call("grantMarketplaceArtifactFromReward", player, rewardPayload));
  const issued = await call("grantMarketplaceArtifactFromReward", gameServer, rewardPayload, { gameServer: true });
  assert.equal(issued.alreadyIssued, false);
  const duplicate = await call("grantMarketplaceArtifactFromReward", gameServer, rewardPayload, { gameServer: true });
  assert.equal(duplicate.alreadyIssued, true);
  assert.equal((await readArtifact(player, relicId)).data().ownerId, player);
});

test("scheduled expiry workers release stale listing, auction and exchange escrow", async () => {
  const seller = uid("scheduled_seller");
  const recipient = uid("scheduled_recipient");
  const listingArtifact = artifactId("scheduled_listing");
  const auctionArtifact = artifactId("scheduled_auction");
  const exchangeArtifact = artifactId("scheduled_exchange");
  const requestedArtifact = artifactId("scheduled_requested");
  await seedPlayer(seller, 0);
  await seedPlayer(recipient, 0);

  await seedArtifact(seller, listingArtifact);
  const listing = await call("createArtifactListing", seller, { artifactId: listingArtifact, price: 60 });
  await db.collection("marketplaceListings").doc(listing.listingId).update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });

  await seedArtifact(seller, auctionArtifact);
  const auction = await call("createArtifactAuction", seller, { artifactId: auctionArtifact, startingBid: 80, durationHours: 1 });
  await db.collection("marketplaceAuctions").doc(auction.auctionId).update({ endsAt: Timestamp.fromMillis(Date.now() - 1000) });

  await seedArtifact(seller, exchangeArtifact);
  await db.collection("artifactRegistry").doc(requestedArtifact).set({ artifactId: requestedArtifact, originalOwnerId: recipient, issuedAt: FieldValue.serverTimestamp() });
  const exchange = await call("createArtifactExchangeOffer", seller, { recipientId: recipient, offeredArtifactId: exchangeArtifact, requestedArtifactId: requestedArtifact });
  await db.collection("marketplaceExchanges").doc(exchange.exchangeId).update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });

  assert.equal(typeof market.releaseExpiredArtifactListings?.run, "function");
  assert.equal(typeof market.settleExpiredArtifactAuctions?.run, "function");
  assert.equal(typeof market.releaseExpiredArtifactExchangeOffers?.run, "function");
  await market.releaseExpiredArtifactListings.run({});
  await market.settleExpiredArtifactAuctions.run({});
  await market.releaseExpiredArtifactExchangeOffers.run({});

  assert.equal((await db.collection("marketplaceListings").doc(listing.listingId).get()).data().status, "expired");
  assert.equal((await readArtifact(seller, listingArtifact)).data().status, "owned");
  assert.equal((await db.collection("marketplaceAuctions").doc(auction.auctionId).get()).data().status, "ended_without_bids");
  assert.equal((await readArtifact(seller, auctionArtifact)).data().status, "owned");
  assert.equal((await db.collection("marketplaceExchanges").doc(exchange.exchangeId).get()).data().status, "expired");
  assert.equal((await readArtifact(seller, exchangeArtifact)).data().status, "owned");
});


test("historical relic return and rare skill reward are trusted, atomic and replay-safe", async () => {
  const owner = uid("babylon_relic_owner");
  const relicId = "babylonian_star_tablet";
  await seedPlayer(owner, 0);
  await seedArtifact(owner, relicId);

  await assert.rejects(() => call("completeHistoricalRelicQuest", owner, {
    playerId: owner,
    questId: "quest_babylon_star_tablet",
    artifactId: relicId,
    eventId: "babylon_reward_untrusted",
    siteId: "babylon_esagila_archive"
  }));

  const payload = {
    playerId: owner,
    questId: "quest_babylon_star_tablet",
    artifactId: relicId,
    eventId: "babylon_reward_verified",
    siteId: "babylon_esagila_archive"
  };
  const result = await call("completeHistoricalRelicQuest", uid("trusted_game_server"), payload, { gameServer: true });
  assert.equal(result.success, true);
  assert.equal(result.relicReturned, true);
  assert.equal(result.skillId, "rare_skill_celestial_lightning");

  const returned = await readArtifact(owner, relicId);
  assert.equal(returned.data().status, "returned_to_history");
  assert.equal(returned.data().returnedToHistoricalSite, "babylon_esagila_archive");
  const skill = await db.collection("playerSkillUnlocks").doc(owner).collection("skills").doc("rare_skill_celestial_lightning").get();
  assert.equal(skill.exists, true);
  assert.equal(skill.data().questId, "quest_babylon_star_tablet");

  const retry = await call("completeHistoricalRelicQuest", uid("trusted_game_server"), payload, { gameServer: true });
  assert.equal(retry.success, true);
  assert.equal(retry.alreadyCompleted, true);
  assert.equal((await readArtifact(owner, relicId)).data().status, "returned_to_history");
});

test("historical relic quest rejects wrong return site and keeps retain-branch relic tradable", async () => {
  const owner = uid("historical_relic_owner");
  await seedPlayer(owner, 0);
  await seedArtifact(owner, "sumerian_oath_seal");
  await seedArtifact(owner, "akkadian_shadow_crown");

  await assert.rejects(() => call("completeHistoricalRelicQuest", uid("trusted_game_server"), {
    playerId: owner,
    questId: "quest_sumerian_oath",
    artifactId: "sumerian_oath_seal",
    eventId: "sumer_wrong_site",
    siteId: "wrong_historical_site"
  }, { gameServer: true }));
  assert.equal((await readArtifact(owner, "sumerian_oath_seal")).data().status, "owned");

  const retained = await call("completeHistoricalRelicQuest", uid("trusted_game_server"), {
    playerId: owner,
    questId: "quest_akkadian_shadow",
    artifactId: "akkadian_shadow_crown",
    eventId: "akkadian_reward_verified"
  }, { gameServer: true });
  assert.equal(retained.success, true);
  assert.equal(retained.relicReturned, false);
  assert.equal((await readArtifact(owner, "akkadian_shadow_crown")).data().status, "owned");
  assert.equal(
    (await db.collection("playerSkillUnlocks").doc(owner).collection("skills").doc("rare_skill_shadow_avatar").get()).exists,
    true
  );
});
