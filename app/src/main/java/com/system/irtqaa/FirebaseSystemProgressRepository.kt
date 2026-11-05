package com.system.irtqaa

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions

class FirebaseSystemProgressRepository(
    private val firestore: FirebaseFirestore =
        FirebaseFirestore.getInstance()
) {

    private fun progressDocument(userId: String) =
        firestore.collection("players")
            .document(userId)
            .collection("systemData")
            .document("progress")

    private fun historyCollection(userId: String) =
        firestore.collection("players")
            .document(userId)
            .collection("systemData")
            .document("progress")
            .collection("history")

    private fun dailyCollection(userId: String) =
        firestore.collection("players")
            .document(userId)
            .collection("systemData")
            .document("progress")
            .collection("daily")

    fun saveProgress(
        snapshot: SystemProgressSnapshot,
        onComplete: (Boolean, Exception?) -> Unit
    ) {
        if (snapshot.userId.isBlank()) {
            onComplete(false, IllegalArgumentException("Invalid user ID"))
            return
        }

        val domains = snapshot.domains.map { domain ->
            mapOf(
                "domain" to domain.domain.name,
                "level" to domain.level,
                "experience" to domain.experience,
                "completedTasks" to domain.completedTasks,
                "totalTasks" to domain.totalTasks,
                "lastActivityAt" to domain.lastActivityAt
            )
        }

        val data = mapOf(
            "userId" to snapshot.userId,
            "domains" to domains,
            "totalExperience" to snapshot.totalExperience,
            "overallLevel" to snapshot.overallLevel,
            "updatedAt" to snapshot.updatedAt
        )

        progressDocument(snapshot.userId)
            .set(data, SetOptions.merge())
            .addOnSuccessListener {
                onComplete(true, null)
            }
            .addOnFailureListener { error ->
                onComplete(false, error)
            }
    }

    fun loadProgress(
        userId: String,
        onComplete: (
            SystemProgressSnapshot?,
            Exception?
        ) -> Unit
    ) {
        if (userId.isBlank()) {
            onComplete(null, IllegalArgumentException("Invalid user ID"))
            return
        }

        progressDocument(userId)
            .get()
            .addOnSuccessListener { document ->

                if (!document.exists()) {
                    onComplete(null, null)
                    return@addOnSuccessListener
                }

                try {
                    val savedUserId =
                        document.getString("userId") ?: userId

                    if (savedUserId != userId) {
                        onComplete(
                            null,
                            IllegalStateException("Account mismatch")
                        )
                        return@addOnSuccessListener
                    }

                    val rawDomains =
                        document.get("domains") as? List<*>
                            ?: emptyList<Any>()

                    val domains = rawDomains.mapNotNull { raw ->

                        val item = raw as? Map<*, *>
                            ?: return@mapNotNull null

                        val domainName =
                            item["domain"] as? String
                                ?: return@mapNotNull null

                        val domain = runCatching {
                            SystemDevelopmentDomain.valueOf(domainName)
                        }.getOrNull() ?: return@mapNotNull null

                        SystemDomainProgress(
                            domain = domain,
                            level = (item["level"] as? Number)?.toInt() ?: 1,
                            experience = (item["experience"] as? Number)?.toInt() ?: 0,
                            completedTasks = (item["completedTasks"] as? Number)?.toInt() ?: 0,
                            totalTasks = (item["totalTasks"] as? Number)?.toInt() ?: 0,
                            lastActivityAt = (item["lastActivityAt"] as? Number)?.toLong() ?: 0L
                        )
                    }

                    val completeDomains =
                        SystemDevelopmentDomain.values().map { domain ->
                            domains.firstOrNull {
                                it.domain == domain
                            } ?: SystemDomainProgress(domain = domain)
                        }

                    val result = SystemProgressSnapshot(
                        userId = userId,
                        domains = completeDomains,
                        totalExperience =
                            document.getLong("totalExperience")?.toInt() ?: 0,
                        overallLevel =
                            document.getLong("overallLevel")?.toInt() ?: 1,
                        updatedAt =
                            document.getLong("updatedAt") ?: 0L
                    )

                    onComplete(result, null)

                } catch (error: Exception) {
                    onComplete(null, error)
                }
            }
            .addOnFailureListener { error ->
                onComplete(null, error)
            }
    }

    fun saveExperienceRecord(
        record: SystemExperienceRecord,
        onComplete: (Boolean, Exception?) -> Unit
    ) {
        if (
            record.userId.isBlank() ||
            record.recordId.isBlank() ||
            record.amount <= 0
        ) {
            onComplete(false, IllegalArgumentException("Invalid experience record"))
            return
        }

        val data = mapOf(
            "recordId" to record.recordId,
            "userId" to record.userId,
            "domain" to record.domain.name,
            "amount" to record.amount,
            "reason" to record.reason,
            "createdAt" to record.createdAt
        )

        historyCollection(record.userId)
            .document(record.recordId)
            .set(data)
            .addOnSuccessListener {
                onComplete(true, null)
            }
            .addOnFailureListener { error ->
                onComplete(false, error)
            }
    }

    fun saveDailyProgress(
        userId: String,
        progress: SystemDailyProgress,
        onComplete: (Boolean, Exception?) -> Unit
    ) {
        if (userId.isBlank() || progress.date.isBlank()) {
            onComplete(false, IllegalArgumentException("Invalid daily progress"))
            return
        }

        val data = mapOf(
            "date" to progress.date,
            "completedTasks" to progress.completedTasks,
            "earnedExperience" to progress.earnedExperience,
            "activeDomains" to progress.activeDomains.map { it.name }
        )

        dailyCollection(userId)
            .document(progress.date)
            .set(data)
            .addOnSuccessListener {
                onComplete(true, null)
            }
            .addOnFailureListener { error ->
                onComplete(false, error)
            }
    }

    fun loadDailyProgress(
        userId: String,
        date: String,
        onComplete: (
            SystemDailyProgress?,
            Exception?
        ) -> Unit
    ) {
        if (userId.isBlank() || date.isBlank()) {
            onComplete(null, IllegalArgumentException("Invalid request"))
            return
        }

        dailyCollection(userId)
            .document(date)
            .get()
            .addOnSuccessListener { document ->

                if (!document.exists()) {
                    onComplete(null, null)
                    return@addOnSuccessListener
                }

                try {
                    val activeDomains =
                        (document.get("activeDomains") as? List<*>)
                            ?.mapNotNull { value ->
                                val name = value as? String
                                    ?: return@mapNotNull null

                                runCatching {
                                    SystemDevelopmentDomain.valueOf(name)
                                }.getOrNull()
                            }
                            ?: emptyList()

                    val result = SystemDailyProgress(
                        date = document.getString("date") ?: date,
                        completedTasks =
                            document.getLong("completedTasks")?.toInt() ?: 0,
                        earnedExperience =
                            document.getLong("earnedExperience")?.toInt() ?: 0,
                        activeDomains = activeDomains.distinct()
                    )

                    onComplete(result, null)

                } catch (error: Exception) {
                    onComplete(null, error)
                }
            }
            .addOnFailureListener { error ->
                onComplete(null, error)
            }
    }
}
