package com.system.irtqaa

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.functions.FirebaseFunctions

data class SystemMarketplaceWallet(
    val balance: Long,
    val reservedBalance: Long = 0L,
    val availableBalance: Long = balance - reservedBalance,
    val currency: String = "SYSTEM"
)

data class SystemOwnedArtifact(
    val artifactId: String,
    val name: String,
    val civilization: String,
    val rarity: String,
    val condition: String,
    val authenticity: String,
    val provenanceSummary: String
)

data class SystemArtifactListing(
    val listingId: String,
    val artifactId: String,
    val name: String,
    val civilization: String,
    val rarity: String,
    val condition: String,
    val authenticity: String,
    val provenanceSummary: String,
    val price: Long,
    val currency: String,
    val sellerId: String,
    val sellerName: String,
    val createdAt: Long?,
    val expiresAt: Long?
)

data class SystemArtifactAuction(
    val auctionId: String,
    val artifactId: String,
    val name: String,
    val civilization: String,
    val rarity: String,
    val condition: String,
    val sellerId: String,
    val sellerName: String,
    val startingBid: Long,
    val highestBid: Long,
    val highestBidderName: String?,
    val bidCount: Int,
    val endsAt: Long
)

/**
 * Client adapter for the server-authoritative Baghdad Antiques marketplace.
 * It deliberately exposes callable operations only; the Android client never
 * writes wallet, ownership, escrow, listing or settlement documents directly.
 */
class FirebaseArtifactMarketplaceRepository(
    private val functions: FirebaseFunctions = FirebaseFunctions.getInstance("us-central1"),
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) {
    fun loadWallet(callback: (Result<SystemMarketplaceWallet>) -> Unit) {
        functions.getHttpsCallable("getMyMarketplaceWallet").call()
            .addOnSuccessListener { result ->
                val data = result.data as? Map<*, *>
                val balance = (data?.get("balance") as? Number)?.toLong()
                if (balance == null || balance < 0L) {
                    callback(Result.failure(IllegalStateException("بيانات محفظة SYSTEM غير صالحة.")))
                } else {
                    val reserved = (data["reservedBalance"] as? Number)?.toLong() ?: 0L
                    val available = (data["availableBalance"] as? Number)?.toLong()
                        ?: (balance - reserved)
                    if (reserved < 0L || reserved > balance || available < 0L) {
                        callback(Result.failure(IllegalStateException("الحجوزات في محفظة SYSTEM غير صالحة.")))
                    } else callback(Result.success(SystemMarketplaceWallet(
                        balance = balance,
                        reservedBalance = reserved,
                        availableBalance = available,
                        currency = data["currency"] as? String ?: "SYSTEM"
                    )))
                }
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun loadOwnedArtifacts(callback: (Result<List<SystemOwnedArtifact>>) -> Unit) {
        functions.getHttpsCallable("listMyMarketplaceArtifacts").call()
            .addOnSuccessListener { result ->
                val data = result.data as? Map<*, *>
                val raw = data?.get("artifacts") as? List<*> ?: emptyList<Any>()
                val artifacts = raw.mapNotNull { value ->
                    val item = value as? Map<*, *> ?: return@mapNotNull null
                    val id = item["artifactId"] as? String ?: return@mapNotNull null
                    SystemOwnedArtifact(
                        artifactId = id,
                        name = item["name"] as? String ?: "قطعة أثرية",
                        civilization = item["civilization"] as? String ?: "",
                        rarity = item["rarity"] as? String ?: "common",
                        condition = item["condition"] as? String ?: "good",
                        authenticity = item["authenticity"] as? String ?: "unverified",
                        provenanceSummary = item["provenanceSummary"] as? String ?: ""
                    )
                }
                callback(Result.success(artifacts))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun browseListings(
        civilization: String? = null,
        rarity: String? = null,
        callback: (Result<List<SystemArtifactListing>>) -> Unit
    ) {
        val payload = mutableMapOf<String, Any>()
        civilization?.trim()?.takeIf { it.isNotEmpty() }?.let { payload["civilization"] = it }
        rarity?.trim()?.takeIf { it.isNotEmpty() }?.let { payload["rarity"] = it }

        functions.getHttpsCallable("browseArtifactMarketplace").call(payload)
            .addOnSuccessListener { result ->
                val data = result.data as? Map<*, *>
                val raw = data?.get("listings") as? List<*> ?: emptyList<Any>()
                val listings = raw.mapNotNull { value ->
                    val item = value as? Map<*, *> ?: return@mapNotNull null
                    val listingId = item["listingId"] as? String ?: return@mapNotNull null
                    val artifactId = item["artifactId"] as? String ?: return@mapNotNull null
                    SystemArtifactListing(
                        listingId = listingId,
                        artifactId = artifactId,
                        name = item["name"] as? String ?: "قطعة أثرية",
                        civilization = item["civilization"] as? String ?: "",
                        rarity = item["rarity"] as? String ?: "common",
                        condition = item["condition"] as? String ?: "good",
                        authenticity = item["authenticity"] as? String ?: "unverified",
                        provenanceSummary = item["provenanceSummary"] as? String ?: "",
                        price = (item["price"] as? Number)?.toLong() ?: 0L,
                        currency = item["currency"] as? String ?: "SYSTEM",
                        sellerId = item["sellerId"] as? String ?: "",
                        sellerName = item["sellerName"] as? String ?: "لاعب",
                        createdAt = (item["createdAt"] as? Number)?.toLong(),
                        expiresAt = (item["expiresAt"] as? Number)?.toLong()
                    )
                }
                callback(Result.success(listings))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun loadTransactionHistory(callback: (Result<List<Map<String, Any?>>>) -> Unit) {
        functions.getHttpsCallable("listMyMarketplaceTransactions").call()
            .addOnSuccessListener { result ->
                val raw = (result.data as? Map<*, *>)?.get("transactions") as? List<*> ?: emptyList<Any>()
                val records = raw.mapNotNull { it as? Map<String, Any?> }
                callback(Result.success(records))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun createListing(
        artifactId: String,
        price: Long,
        durationDays: Int = 7,
        callback: (Result<String>) -> Unit
    ) {
        if (artifactId.isBlank() || price <= 0L || durationDays !in 1..30) {
            callback(Result.failure(IllegalArgumentException("بيانات عرض القطعة غير صالحة.")))
            return
        }
        functions.getHttpsCallable("createArtifactListing")
            .call(mapOf(
                "artifactId" to artifactId,
                "price" to price,
                "durationDays" to durationDays
            ))
            .addOnSuccessListener { result ->
                val listingId = (result.data as? Map<*, *>)?.get("listingId") as? String
                if (listingId.isNullOrBlank()) {
                    callback(Result.failure(IllegalStateException("لم يرجع الخادم معرّف العرض.")))
                } else callback(Result.success(listingId))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun purchaseListing(listingId: String, callback: (Result<String>) -> Unit) {
        if (listingId.isBlank()) {
            callback(Result.failure(IllegalArgumentException("معرّف العرض غير صالح.")))
            return
        }
        functions.getHttpsCallable("purchaseArtifactListing")
            .call(mapOf("listingId" to listingId))
            .addOnSuccessListener { result ->
                val transactionId = (result.data as? Map<*, *>)?.get("transactionId") as? String
                if (transactionId.isNullOrBlank()) {
                    callback(Result.failure(IllegalStateException("لم يرجع الخادم معرّف الصفقة.")))
                } else callback(Result.success(transactionId))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun expireListing(listingId: String, callback: (Result<Unit>) -> Unit) {
        if (listingId.isBlank()) {
            callback(Result.failure(IllegalArgumentException("معرّف العرض غير صالح.")))
            return
        }
        functions.getHttpsCallable("expireArtifactListing")
            .call(mapOf("listingId" to listingId))
            .addOnSuccessListener { callback(Result.success(Unit)) }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun loadTradeHistory(callback: (Result<List<Map<String, Any?>>>) -> Unit) {
        functions.getHttpsCallable("listMyMarketplaceTransactions").call()
            .addOnSuccessListener { result ->
                val raw = (result.data as? Map<*, *>)?.get("transactions") as? List<*> ?: emptyList<Any>()
                callback(Result.success(raw.mapNotNull { it as? Map<String, Any?> }))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun cancelListing(listingId: String, callback: (Result<Unit>) -> Unit) {
        if (listingId.isBlank()) {
            callback(Result.failure(IllegalArgumentException("معرّف العرض غير صالح.")))
            return
        }
        functions.getHttpsCallable("cancelArtifactListing")
            .call(mapOf("listingId" to listingId))
            .addOnSuccessListener { callback(Result.success(Unit)) }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun createAuction(
        artifactId: String,
        startingBid: Long,
        durationHours: Int = 24,
        callback: (Result<String>) -> Unit
    ) {
        if (artifactId.isBlank() || startingBid <= 0L || durationHours !in 1..168) {
            callback(Result.failure(IllegalArgumentException("بيانات المزاد غير صالحة.")))
            return
        }
        functions.getHttpsCallable("createArtifactAuction")
            .call(mapOf(
                "artifactId" to artifactId,
                "startingBid" to startingBid,
                "durationHours" to durationHours
            ))
            .addOnSuccessListener { result ->
                val id = (result.data as? Map<*, *>)?.get("auctionId") as? String
                if (id.isNullOrBlank()) callback(Result.failure(IllegalStateException("لم يرجع معرّف المزاد.")))
                else callback(Result.success(id))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun browseAuctions(callback: (Result<List<SystemArtifactAuction>>) -> Unit) {
        functions.getHttpsCallable("browseArtifactAuctions").call()
            .addOnSuccessListener { result ->
                val raw = (result.data as? Map<*, *>)?.get("auctions") as? List<*> ?: emptyList<Any>()
                val auctions = raw.mapNotNull { value ->
                    val item = value as? Map<*, *> ?: return@mapNotNull null
                    val id = item["auctionId"] as? String ?: return@mapNotNull null
                    val artifactId = item["artifactId"] as? String ?: return@mapNotNull null
                    SystemArtifactAuction(
                        auctionId = id,
                        artifactId = artifactId,
                        name = item["name"] as? String ?: "قطعة أثرية",
                        civilization = item["civilization"] as? String ?: "",
                        rarity = item["rarity"] as? String ?: "common",
                        condition = item["condition"] as? String ?: "good",
                        sellerId = item["sellerId"] as? String ?: "",
                        sellerName = item["sellerName"] as? String ?: "لاعب",
                        startingBid = (item["startingBid"] as? Number)?.toLong() ?: 0L,
                        highestBid = (item["highestBid"] as? Number)?.toLong() ?: 0L,
                        highestBidderName = item["highestBidderName"] as? String,
                        bidCount = (item["bidCount"] as? Number)?.toInt() ?: 0,
                        endsAt = (item["endsAt"] as? Number)?.toLong() ?: 0L
                    )
                }
                callback(Result.success(auctions))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun placeAuctionBid(auctionId: String, amount: Long, callback: (Result<Unit>) -> Unit) {
        if (auctionId.isBlank() || amount <= 0L) {
            callback(Result.failure(IllegalArgumentException("بيانات المزايدة غير صالحة.")))
            return
        }
        functions.getHttpsCallable("placeArtifactAuctionBid")
            .call(mapOf("auctionId" to auctionId, "amount" to amount))
            .addOnSuccessListener { callback(Result.success(Unit)) }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun loadAuctionBids(
        auctionId: String,
        callback: (Result<List<Map<String, Any?>>>) -> Unit
    ) {
        if (auctionId.isBlank()) {
            callback(Result.failure(IllegalArgumentException("معرّف المزاد غير صالح.")))
            return
        }
        functions.getHttpsCallable("listArtifactAuctionBids")
            .call(mapOf("auctionId" to auctionId))
            .addOnSuccessListener { result ->
                val raw = (result.data as? Map<*, *>)?.get("bids") as? List<*> ?: emptyList<Any>()
                val bids = raw.mapNotNull { it as? Map<String, Any?> }
                callback(Result.success(bids))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun settleAuction(auctionId: String, callback: (Result<Unit>) -> Unit) {
        if (auctionId.isBlank()) {
            callback(Result.failure(IllegalArgumentException("معرّف المزاد غير صالح.")))
            return
        }
        functions.getHttpsCallable("settleExpiredArtifactAuction")
            .call(mapOf("auctionId" to auctionId))
            .addOnSuccessListener { callback(Result.success(Unit)) }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun cancelAuction(auctionId: String, callback: (Result<Unit>) -> Unit) {
        if (auctionId.isBlank()) {
            callback(Result.failure(IllegalArgumentException("معرّف المزاد غير صالح.")))
            return
        }
        functions.getHttpsCallable("cancelArtifactAuction")
            .call(mapOf("auctionId" to auctionId))
            .addOnSuccessListener { callback(Result.success(Unit)) }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun createExchangeOffer(
        recipientId: String,
        offeredArtifactId: String,
        requestedArtifactId: String,
        callback: (Result<String>) -> Unit
    ) {
        if (recipientId.isBlank() || offeredArtifactId.isBlank() || requestedArtifactId.isBlank()) {
            callback(Result.failure(IllegalArgumentException("بيانات التبادل غير مكتملة.")))
            return
        }
        functions.getHttpsCallable("createArtifactExchangeOffer")
            .call(mapOf(
                "recipientId" to recipientId,
                "offeredArtifactId" to offeredArtifactId,
                "requestedArtifactId" to requestedArtifactId
            ))
            .addOnSuccessListener { result ->
                val id = (result.data as? Map<*, *>)?.get("exchangeId") as? String
                if (id.isNullOrBlank()) callback(Result.failure(IllegalStateException("لم يرجع معرّف التبادل.")))
                else callback(Result.success(id))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun acceptExchangeOffer(exchangeId: String, callback: (Result<Unit>) -> Unit) {
        if (exchangeId.isBlank()) {
            callback(Result.failure(IllegalArgumentException("معرّف التبادل غير صالح.")))
            return
        }
        functions.getHttpsCallable("acceptArtifactExchangeOffer")
            .call(mapOf("exchangeId" to exchangeId))
            .addOnSuccessListener { callback(Result.success(Unit)) }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun closeExchangeOffer(
        exchangeId: String,
        action: String,
        callback: (Result<Unit>) -> Unit
    ) {
        if (exchangeId.isBlank() || action !in setOf("cancel", "decline", "expire")) {
            callback(Result.failure(IllegalArgumentException("إجراء إغلاق التبادل غير صالح.")))
            return
        }
        functions.getHttpsCallable("closeArtifactExchangeOffer")
            .call(mapOf("exchangeId" to exchangeId, "action" to action))
            .addOnSuccessListener { callback(Result.success(Unit)) }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun loadMyExchangeOffers(
        callback: (Result<Map<String, List<Map<String, Any?>>>>) -> Unit
    ) {
        functions.getHttpsCallable("listMyArtifactExchangeOffers").call()
            .addOnSuccessListener { result ->
                val data = result.data as? Map<*, *> ?: emptyMap<Any, Any>()
                fun parse(key: String): List<Map<String, Any?>> =
                    (data[key] as? List<*>)?.mapNotNull { it as? Map<String, Any?> } ?: emptyList()
                callback(Result.success(mapOf("sent" to parse("sent"), "received" to parse("received"))))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

}
