package com.system.irtqaa

import org.json.JSONArray
import org.json.JSONObject

/**
 * Dispatches authenticated Godot marketplace requests to the Firebase callable
 * repository. The host Activity/plugin supplies the router transport; no
 * Firebase token or wallet authority is exposed to the Godot runtime.
 */
class SystemMarketplaceGodotBridgeHandler(
    private val repository: FirebaseArtifactMarketplaceRepository,
    private val router: SystemGodotMessageRouter
) : SystemGodotMessageRouter.Listener {

    override fun onMarketplaceRequest(requestId: String?, payload: JSONObject) {
        val id = requestId?.takeIf { it.isNotBlank() } ?: return
        when (payload.optString("operation")) {
            "browse_secret_antique_offers" -> repository.browseSecretAntiqueOffers { result ->
                respond(id, result.map { offers -> JSONObject().put("offers", JSONArray(offers.map { JSONObject(it) })) })
            }
            "purchase_secret_antique_offer" -> repository.purchaseSecretAntiqueOffer(
                payload.optString("offerId"),
                payload.optString("eventId")
            ) { result -> respond(id, result.map { JSONObject(it) }) }
            "appraise_artifact_authenticity" -> repository.appraiseMyArtifactAuthenticity(
                payload.optString("artifactId")
            ) { result -> respond(id, result.map { JSONObject(it) }) }
            "antiques_reputation" -> repository.loadMyAntiquesReputation { result ->
                respond(id, result.map { JSONObject(it) })
            }
            "request_relic_quest_start" -> repository.requestHistoricalRelicQuestStart(
                payload.optString("questId"),
                payload.optString("artifactId")
            ) { result -> respond(id, result.map { JSONObject(it) }) }
            "request_relic_return" -> repository.requestHistoricalRelicReturn(
                payload.optString("questId"),
                payload.optString("artifactId")
            ) { result -> respond(id, result.map { JSONObject(it) }) }
            "refresh_relic_state" -> repository.loadRelicQuestState { result ->
                respond(id, result.map { snapshot ->
                    JSONObject()
                        .put("ownedArtifacts", JSONArray(snapshot.ownedArtifacts.map { artifact ->
                            JSONObject()
                                .put("artifactId", artifact.artifactId)
                                .put("name", artifact.name)
                                .put("civilization", artifact.civilization)
                                .put("rarity", artifact.rarity)
                                .put("condition", artifact.condition)
                                .put("authenticity", artifact.authenticity)
                                .put("provenanceSummary", artifact.provenanceSummary)
                        }))
                        .put("marketListings", JSONArray(snapshot.marketListings.map { listing ->
                            JSONObject()
                                .put("listingId", listing.listingId)
                                .put("artifactId", listing.artifactId)
                                .put("name", listing.name)
                                .put("civilization", listing.civilization)
                                .put("rarity", listing.rarity)
                                .put("condition", listing.condition)
                                .put("authenticity", listing.authenticity)
                                .put("price", listing.price)
                                .put("currency", listing.currency)
                                .put("sellerName", listing.sellerName)
                                .put("isSeller", listing.isSeller)
                        }))
                        .put("skills", JSONArray(snapshot.skills.map { JSONObject(it) }))
                        .put("questSessions", JSONArray(snapshot.questSessions.map { JSONObject(it) }))
                })
            }
            "wallet" -> repository.loadWallet { result ->
                respond(id, result.map { wallet ->
                    JSONObject()
                        .put("balance", wallet.balance)
                        .put("reservedBalance", wallet.reservedBalance)
                        .put("availableBalance", wallet.availableBalance)
                        .put("currency", wallet.currency)
                })
            }
            "owned_artifacts" -> repository.loadOwnedArtifacts { result ->
                respond(id, result.map { artifacts ->
                    JSONObject().put("artifacts", JSONArray(artifacts.map { artifact ->
                        JSONObject()
                            .put("artifactId", artifact.artifactId)
                            .put("name", artifact.name)
                            .put("civilization", artifact.civilization)
                            .put("rarity", artifact.rarity)
                            .put("condition", artifact.condition)
                            .put("authenticity", artifact.authenticity)
                            .put("provenanceSummary", artifact.provenanceSummary)
                    }))
                })
            }
            "browse_listings" -> repository.browseListings(
                civilization = payload.optString("civilization").takeIf { it.isNotBlank() },
                rarity = payload.optString("rarity").takeIf { it.isNotBlank() }
            ) { result ->
                respond(id, result.map { listings ->
                    JSONObject().put("listings", JSONArray(listings.map { listing ->
                        JSONObject()
                            .put("listingId", listing.listingId)
                            .put("artifactId", listing.artifactId)
                            .put("name", listing.name)
                            .put("civilization", listing.civilization)
                            .put("rarity", listing.rarity)
                            .put("condition", listing.condition)
                            .put("authenticity", listing.authenticity)
                            .put("price", listing.price)
                            .put("currency", listing.currency)
                            .put("sellerName", listing.sellerName)
                            .put("isSeller", listing.isSeller)
                    }))
                })
            }
            "create_listing" -> repository.createListing(
                payload.optString("artifactId"),
                payload.optLong("price"),
                payload.optInt("durationDays", 7)
            ) { respond(id, it.map { listingId -> JSONObject().put("listingId", listingId) }) }
            "purchase_listing" -> repository.purchaseListing(payload.optString("listingId")) {
                respond(id, it.map { transactionId -> JSONObject().put("transactionId", transactionId) })
            }
            "cancel_listing" -> repository.cancelListing(payload.optString("listingId")) {
                respond(id, it.map { JSONObject().put("cancelled", true) })
            }
            "expire_listing" -> repository.expireListing(payload.optString("listingId")) {
                respond(id, it.map { JSONObject().put("expired", true) })
            }
            "trade_history" -> repository.loadTradeHistory { result ->
                respond(id, result.map { rows -> JSONObject().put("transactions", JSONArray(rows.map { JSONObject(it) })) })
            }
            "browse_auctions" -> repository.browseAuctions { result ->
                respond(id, result.map { auctions ->
                    JSONObject().put("auctions", JSONArray(auctions.map { auction ->
                        JSONObject()
                            .put("auctionId", auction.auctionId)
                            .put("artifactId", auction.artifactId)
                            .put("name", auction.name)
                            .put("civilization", auction.civilization)
                            .put("rarity", auction.rarity)
                            .put("condition", auction.condition)
                            .put("sellerName", auction.sellerName)
                            .put("isSeller", auction.isSeller)
                            .put("startingBid", auction.startingBid)
                            .put("highestBid", auction.highestBid)
                            .put("highestBidderName", auction.highestBidderName)
                            .put("bidCount", auction.bidCount)
                            .put("endsAt", auction.endsAt)
                    }))
                })
            }
            "create_auction" -> repository.createAuction(
                payload.optString("artifactId"),
                payload.optLong("startingBid"),
                payload.optInt("durationHours", 24)
            ) { respond(id, it.map { auctionId -> JSONObject().put("auctionId", auctionId) }) }
            "place_bid" -> repository.placeAuctionBid(
                payload.optString("auctionId"),
                payload.optLong("amount")
            ) { respond(id, it.map { JSONObject().put("accepted", true) }) }
            "auction_bids" -> repository.loadAuctionBids(payload.optString("auctionId")) {
                respond(id, it.map { bids -> JSONObject().put("bids", JSONArray(bids.map { JSONObject(it) })) })
            }
            "settle_auction" -> repository.settleAuction(payload.optString("auctionId")) {
                respond(id, it.map { JSONObject().put("settled", true) })
            }
            "cancel_auction" -> repository.cancelAuction(payload.optString("auctionId")) {
                respond(id, it.map { JSONObject().put("cancelled", true) })
            }
            "exchange_offers" -> repository.loadMyExchangeOffers { result ->
                respond(id, result.map { offers ->
                    val sent = offers["sent"] as? List<Map<String, Any?>> ?: emptyList()
                    val received = offers["received"] as? List<Map<String, Any?>> ?: emptyList()
                    JSONObject()
                        .put("sent", JSONArray(sent.map { JSONObject(it) }))
                        .put("received", JSONArray(received.map { JSONObject(it) }))
                })
            }
            "create_exchange_offer" -> repository.createExchangeOffer(
                payload.optString("recipientId"),
                payload.optString("offeredArtifactId"),
                payload.optString("requestedArtifactId")
            ) { respond(id, it.map { exchangeId -> JSONObject().put("exchangeId", exchangeId) }) }
            "accept_exchange_offer" -> repository.acceptExchangeOffer(payload.optString("exchangeId")) {
                respond(id, it.map { JSONObject().put("accepted", true) })
            }
            "close_exchange_offer" -> repository.closeExchangeOffer(
                payload.optString("exchangeId"),
                payload.optString("action")
            ) { respond(id, it.map { JSONObject().put("closed", true) }) }
            else -> router.sendMarketplaceResult(
                id,
                JSONObject().put("success", false).put("error", "UNKNOWN_MARKETPLACE_OPERATION")
            )
        }
    }

    override fun onRejectedMessage(reason: String) {
        // The router owns malformed-message reporting; no sensitive details are echoed.
    }

    private fun respond(requestId: String, result: Result<JSONObject>) {
        val payload = result.fold(
            onSuccess = { JSONObject().put("success", true).put("data", it) },
            onFailure = {
                JSONObject()
                    .put("success", false)
                    .put("error", it.message?.take(240) ?: "MARKETPLACE_REQUEST_FAILED")
            }
        )
        router.sendMarketplaceResult(requestId, payload)
    }
}
