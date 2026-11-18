package com.system.irtqaa

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.functions.FirebaseFunctions

data class SystemPlayerParty(
    val partyId: String,
    val name: String,
    val leaderId: String,
    val memberIds: List<String>,
    val maxMembers: Int = 6
)

data class SystemPlayerPartyInvite(
    val inviteId: String,
    val partyId: String,
    val partyName: String,
    val fromUid: String,
    val fromName: String
)

/**
 * Client for the authenticated, server-validated player party system.
 * Firestore party documents are intentionally not writable by clients.
 */
class FirebasePlayerPartyRepository(
    private val functions: FirebaseFunctions = FirebaseFunctions.getInstance(),
    private val auth: FirebaseAuth = FirebaseAuth.getInstance()
) {
    fun isSignedIn(): Boolean = auth.currentUser != null

    fun currentPlayerId(): String? = auth.currentUser?.uid

    fun createParty(name: String, callback: (Result<SystemPlayerParty>) -> Unit) {
        val clean = name.trim()
        if (clean.isEmpty() || clean.length > 32) {
            callback(Result.failure(IllegalArgumentException("اسم الفريق من 1 إلى 32 حرفاً.")))
            return
        }
        call("createPlayerParty", mapOf("name" to clean), callback) { data ->
            parseParty(data["party"] as? Map<*, *>)
                ?: throw IllegalStateException("لم تصل بيانات الفريق من الخادم.")
        }
    }

    fun invitePlayer(
        partyId: String,
        targetPlayerId: String,
        callback: (Result<String>) -> Unit
    ) {
        val party = partyId.trim()
        val target = targetPlayerId.trim()
        if (party.isEmpty() || target.isEmpty()) {
            callback(Result.failure(IllegalArgumentException("أدخل معرّف الفريق واللاعب.")))
            return
        }
        functions.getHttpsCallable("invitePlayerToParty")
            .call(mapOf("partyId" to party, "targetPlayerId" to target))
            .addOnSuccessListener { result ->
                val data = result.data as? Map<*, *>
                val inviteId = data?.get("inviteId") as? String
                if (inviteId.isNullOrBlank()) callback(Result.failure(IllegalStateException("لم يصل معرّف الدعوة.")))
                else callback(Result.success(inviteId))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun respondToInvite(
        inviteId: String,
        accept: Boolean,
        callback: (Result<String>) -> Unit
    ) {
        functions.getHttpsCallable("respondToPlayerPartyInvite")
            .call(mapOf("inviteId" to inviteId, "accept" to accept))
            .addOnSuccessListener { result ->
                val status = (result.data as? Map<*, *>)?.get("status") as? String
                if (status.isNullOrBlank()) callback(Result.failure(IllegalStateException("لم تصل نتيجة الدعوة.")))
                else callback(Result.success(status))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun leaveParty(partyId: String, callback: (Result<String>) -> Unit) {
        functions.getHttpsCallable("leavePlayerParty")
            .call(mapOf("partyId" to partyId))
            .addOnSuccessListener { result ->
                val status = (result.data as? Map<*, *>)?.get("status") as? String
                if (status.isNullOrBlank()) callback(Result.failure(IllegalStateException("لم تصل نتيجة مغادرة الفريق.")))
                else callback(Result.success(status))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun loadMyParties(callback: (Result<List<SystemPlayerParty>>) -> Unit) {
        functions.getHttpsCallable("listMyPlayerParties")
            .call()
            .addOnSuccessListener { result ->
                val data = result.data as? Map<*, *>
                val items = data?.get("parties") as? List<*> ?: emptyList<Any>()
                val parties = items.mapNotNull { parseParty(it as? Map<*, *>) }
                callback(Result.success(parties))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    fun loadMyInvites(callback: (Result<List<SystemPlayerPartyInvite>>) -> Unit) {
        functions.getHttpsCallable("listMyPlayerPartyInvites")
            .call()
            .addOnSuccessListener { result ->
                val data = result.data as? Map<*, *>
                val items = data?.get("invites") as? List<*> ?: emptyList<Any>()
                val invites = items.mapNotNull { item ->
                    val map = item as? Map<*, *> ?: return@mapNotNull null
                    val inviteId = map["inviteId"] as? String ?: return@mapNotNull null
                    SystemPlayerPartyInvite(
                        inviteId = inviteId,
                        partyId = map["partyId"] as? String ?: "",
                        partyName = map["partyName"] as? String ?: "فريق اللاعبين",
                        fromUid = map["fromUid"] as? String ?: "",
                        fromName = map["fromName"] as? String ?: "لاعب"
                    )
                }
                callback(Result.success(invites))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    private fun parseParty(map: Map<*, *>?): SystemPlayerParty? {
        map ?: return null
        val id = map["partyId"] as? String ?: return null
        val members = (map["memberIds"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
        return SystemPlayerParty(
            partyId = id,
            name = map["name"] as? String ?: "فريق اللاعبين",
            leaderId = map["leaderId"] as? String ?: "",
            memberIds = members,
            maxMembers = (map["maxMembers"] as? Number)?.toInt() ?: 6
        )
    }

    private fun <T> call(
        name: String,
        payload: Map<String, Any>,
        callback: (Result<T>) -> Unit,
        parse: (Map<*, *>) -> T
    ) {
        functions.getHttpsCallable(name).call(payload)
            .addOnSuccessListener { result ->
                try {
                    val data = result.data as? Map<*, *>
                        ?: throw IllegalStateException("استجابة الخادم غير صالحة.")
                    callback(Result.success(parse(data)))
                } catch (error: Exception) {
                    callback(Result.failure(error))
                }
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }
}
