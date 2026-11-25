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
}
