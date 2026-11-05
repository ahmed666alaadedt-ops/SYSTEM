package com.system.irtqaa

import android.content.Context
import com.google.firebase.firestore.FirebaseFirestore
import java.time.LocalDate

class FirebaseSystemProgressDetailsSync(context: Context) {

    private val storage = SystemProgressStorageV2(
        context.applicationContext
    )

    private val firestore = FirebaseFirestore.getInstance()

    fun synchronize(
        userId: String,
        date: String = LocalDate.now().toString(),
        onComplete: (Boolean, Exception?) -> Unit
    ) {
        if (userId.isBlank() || date.isBlank()) {
            onComplete(
                false,
                IllegalArgumentException("Invalid synchronization request")
            )
            return
        }

        val historyReference = firestore
            .collection("players")
            .document(userId)
            .collection("systemData")
            .document("progress")
            .collection("history")

        historyReference.get()
            .addOnSuccessListener { documents ->

                try {
                    val localRecords = storage
                        .loadExperienceHistory(userId)

                    val cloudRecords = documents.documents.mapNotNull {
                        document ->

                        val domainName =
                            document.getString("domain")
                                ?: return@mapNotNull null

                        val domain = runCatching {
                            SystemDevelopmentDomain.valueOf(domainName)
                        }.getOrNull() ?: return@mapNotNull null

                        val recordUserId =
                            document.getString("userId") ?: userId

                        if (recordUserId != userId) {
                            return@mapNotNull null
                        }

                        SystemExperienceRecord(
                            recordId = document.getString("recordId")
                                ?: document.id,
                            userId = userId,
                            domain = domain,
                            amount = document.getLong("amount")?.toInt() ?: 0,
                            reason = document.getString("reason").orEmpty(),
                            createdAt = document.getLong("createdAt") ?: 0L
                        )
                    }

                    val mergedRecords = (
                        localRecords + cloudRecords
                    )
                        .filter { it.userId == userId }
                        .associateBy { it.recordId }
                        .values
                        .sortedBy { it.createdAt }

                    if (!storage.saveExperienceHistory(
                            userId,
                            mergedRecords
                        )) {
                        onComplete(
                            false,
                            IllegalStateException(
                                "Could not save experience history"
                            )
                        )
                        return@addOnSuccessListener
                    }

                    synchronizeDailyProgress(
                        userId = userId,
                        date = date,
                        onComplete = onComplete
                    )

                } catch (error: Exception) {
                    onComplete(false, error)
                }
            }
            .addOnFailureListener { error ->
                onComplete(false, error)
            }
    }

    private fun synchronizeDailyProgress(
        userId: String,
        date: String,
        onComplete: (Boolean, Exception?) -> Unit
    ) {
        val dailyReference = firestore
            .collection("players")
            .document(userId)
            .collection("systemData")
            .document("progress")
            .collection("daily")
            .document(date)

        dailyReference.get()
            .addOnSuccessListener { document ->

                try {
                    val localDaily = storage.loadDailyProgress(
                        userId,
                        date
                    )

                    if (!document.exists()) {
                        onComplete(true, null)
                        return@addOnSuccessListener
                    }

                    val cloudDomains = (
                        document.get("activeDomains") as? List<*>
                    )?.mapNotNull { value ->
                        val name = value as? String
                            ?: return@mapNotNull null

                        runCatching {
                            SystemDevelopmentDomain.valueOf(name)
                        }.getOrNull()
                    } ?: emptyList()

                    val cloudDaily = SystemDailyProgress(
                        date = date,
                        completedTasks =
                            document.getLong("completedTasks")?.toInt() ?: 0,
                        earnedExperience =
                            document.getLong("earnedExperience")?.toInt() ?: 0,
                        activeDomains = cloudDomains.distinct()
                    )

                    val mergedDaily = SystemDailyProgress(
                        date = date,
                        completedTasks = maxOf(
                            localDaily.completedTasks,
                            cloudDaily.completedTasks
                        ),
                        earnedExperience = maxOf(
                            localDaily.earnedExperience,
                            cloudDaily.earnedExperience
                        ),
                        activeDomains = (
                            localDaily.activeDomains +
                                cloudDaily.activeDomains
                        ).distinct()
                    )

                    val saved = storage.saveDailyProgress(
                        userId,
                        mergedDaily
                    )

                    if (!saved) {
                        onComplete(
                            false,
                            IllegalStateException(
                                "Could not restore daily progress"
                            )
                        )
                        return@addOnSuccessListener
                    }

                    onComplete(true, null)

                } catch (error: Exception) {
                    onComplete(false, error)
                }
            }
            .addOnFailureListener { error ->
                onComplete(false, error)
            }
    }
}
