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

        val progressReference = firestore
            .collection("players")
            .document(userId)
            .collection("systemData")
            .document("progress")

        progressReference
            .collection("history")
            .get()
            .addOnSuccessListener { documents ->

                try {
                    val localRecords =
                        storage.loadExperienceHistory(userId)

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

                    synchronizeAllDailyProgress(
                        userId = userId,
                        today = date,
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

    private fun synchronizeAllDailyProgress(
        userId: String,
        today: String,
        onComplete: (Boolean, Exception?) -> Unit
    ) {
        val dailyReference = firestore
            .collection("players")
            .document(userId)
            .collection("systemData")
            .document("progress")
            .collection("daily")

        dailyReference.get()
            .addOnSuccessListener { documents ->

                try {
                    val cloudByDate = documents.documents.associateBy {
                        it.id
                    }

                    val dates = (
                        cloudByDate.keys + today
                    ).distinct()

                    val batch = firestore.batch()

                    for (date in dates) {
                        val document = cloudByDate[date]

                        val localDaily = storage.loadDailyProgress(
                            userId,
                            date
                        )

                        val cloudDaily = if (document != null) {
                            val cloudDomains = (
                                document.get("activeDomains") as? List<*>
                            )?.mapNotNull { value ->

                                val name = value as? String
                                    ?: return@mapNotNull null

                                runCatching {
                                    SystemDevelopmentDomain.valueOf(name)
                                }.getOrNull()
                            } ?: emptyList()

                            SystemDailyProgress(
                                date = date,
                                completedTasks =
                                    document.getLong("completedTasks")
                                        ?.toInt() ?: 0,
                                earnedExperience =
                                    document.getLong("earnedExperience")
                                        ?.toInt() ?: 0,
                                activeDomains = cloudDomains.distinct()
                            )
                        } else {
                            SystemDailyProgress(date = date)
                        }

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

                        if (!storage.saveDailyProgress(
                                userId,
                                mergedDaily
                            )) {
                            onComplete(
                                false,
                                IllegalStateException(
                                    "Could not save daily progress: $date"
                                )
                            )
                            return@addOnSuccessListener
                        }

                        val hasProgress =
                            mergedDaily.completedTasks > 0 ||
                            mergedDaily.earnedExperience > 0 ||
                            mergedDaily.activeDomains.isNotEmpty()

                        if (hasProgress) {
                            batch.set(
                                dailyReference.document(date),
                                mapOf(
                                    "date" to mergedDaily.date,
                                    "completedTasks" to
                                        mergedDaily.completedTasks,
                                    "earnedExperience" to
                                        mergedDaily.earnedExperience,
                                    "activeDomains" to
                                        mergedDaily.activeDomains.map {
                                            it.name
                                        }
                                )
                            )
                        }
                    }

                    batch.commit()
                        .addOnSuccessListener {
                            onComplete(true, null)
                        }
                        .addOnFailureListener { error ->
                            onComplete(false, error)
                        }

                } catch (error: Exception) {
                    onComplete(false, error)
                }
            }
            .addOnFailureListener { error ->
                onComplete(false, error)
            }
    }
}
