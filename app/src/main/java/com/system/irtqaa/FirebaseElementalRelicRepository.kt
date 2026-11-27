package com.system.irtqaa

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.functions.FirebaseFunctions
import org.json.JSONObject

/**
 * Client-side request adapter for elemental relic activation.
 *
 * This class can request an authoritative activation receipt only. It never
 * applies combat effects and deliberately exposes no client-callable resolver:
 * resolveElementalRelicCombat is restricted to the trusted game-server claim.
 */
class FirebaseElementalRelicRepository(
    private val functions: FirebaseFunctions = FirebaseFunctions.getInstance("us-central1"),
    private val auth: FirebaseAuth = FirebaseAuth.getInstance()
) {
    fun authorizeActivation(
        skillId: String,
        callback: (Result<JSONObject>) -> Unit
    ) {
        val normalized = skillId.trim().lowercase()
        if (auth.currentUser == null) {
            callback(Result.failure(IllegalStateException("يجب تسجيل الدخول قبل تفعيل التحفة.")))
            return
        }
        if (normalized !in ELEMENTAL_SKILLS) {
            callback(Result.failure(IllegalArgumentException("المهارة العنصرية غير معروفة.")))
            return
        }

        functions.getHttpsCallable("authorizeElementalRelicActivation")
            .call(mapOf("skillId" to normalized))
            .addOnSuccessListener { result ->
                val data = result.data as? Map<*, *>
                val activationId = data?.get("activationId") as? String
                val status = data?.get("status") as? String
                val returnedSkill = data?.get("skillId") as? String
                val energyCost = (data?.get("energyCost") as? Number)?.toInt()
                val remainingEnergy = (data?.get("remainingEnergy") as? Number)?.toInt()
                val cooldown = (data?.get("cooldownSeconds") as? Number)?.toInt()
                if (data?.get("success") != true ||
                    activationId.isNullOrBlank() ||
                    status != "authorized_pending_combat" ||
                    returnedSkill != normalized ||
                    energyCost == null || remainingEnergy == null || cooldown == null
                ) {
                    callback(Result.failure(IllegalStateException("استجابة تفعيل التحفة غير مكتملة أو غير موثوقة.")))
                    return@addOnSuccessListener
                }
                callback(Result.success(
                    JSONObject()
                        .put("success", true)
                        .put("activationId", activationId)
                        .put("skillId", normalized)
                        .put("status", status)
                        .put("energyCost", energyCost)
                        .put("remainingEnergy", remainingEnergy)
                        .put("cooldownSeconds", cooldown)
                ))
            }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    companion object {
        private val ELEMENTAL_SKILLS = setOf(
            "primordial_flame_burst",
            "stormwind_aerial_step",
            "tideheart_restoration",
            "worldroot_earthguard",
            "stormlightning_arc"
        )
    }
}
