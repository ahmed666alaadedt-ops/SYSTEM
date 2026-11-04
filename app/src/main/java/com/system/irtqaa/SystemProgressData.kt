package com.system.irtqaa

class SystemProgressLegacyEngine {

    private val progress =
        mutableMapOf<String, SystemProgressSnapshot>()

    private val experienceRecords =
        mutableListOf<SystemExperienceRecord>()

    private val dailyProgress =
        mutableMapOf<String, SystemDailyProgress>()

    fun getProgress(userId: String): SystemProgressSnapshot {
        require(userId.isNotBlank())

        return progress.getOrPut(userId) {
            SystemProgressSnapshot(
                userId = userId,
                domains = SystemDevelopmentDomain.values().map {
                    SystemDomainProgress(domain = it)
                }
            )
        }
    }

    fun addExperience(
        userId: String,
        domain: SystemDevelopmentDomain,
        amount: Int,
        reason: String,
        timestamp: Long = System.currentTimeMillis()
    ): SystemProgressSnapshot {
        require(userId.isNotBlank())
        require(amount > 0)
        require(reason.isNotBlank())

        val current = getProgress(userId)

        val updatedDomains = current.domains.map { item ->
            if (item.domain == domain) {
                val newExperience = item.experience + amount

                item.copy(
                    experience = newExperience,
                    level = calculateLevel(newExperience),
                    lastActivityAt = timestamp
                )
            } else {
                item
            }
        }

        val updated = current.copy(
            domains = updatedDomains,
            totalExperience = current.totalExperience + amount,
            overallLevel = calculateLevel(
                current.totalExperience + amount
            ),
            updatedAt = timestamp
        )

        progress[userId] = updated

        experienceRecords.add(
            SystemExperienceRecord(
                recordId = "XP-$timestamp-${experienceRecords.size}",
                userId = userId,
                domain = domain,
                amount = amount,
                reason = reason,
                createdAt = timestamp
            )
        )

        return updated
    }

    fun completeTask(
        userId: String,
        domain: SystemDevelopmentDomain,
        experienceReward: Int,
        date: String
    ): SystemProgressSnapshot {
        require(userId.isNotBlank())
        require(experienceReward > 0)
        require(date.isNotBlank())

        val current = getProgress(userId)

        val updatedDomains = current.domains.map { item ->
            if (item.domain == domain) {
                item.copy(
                    completedTasks = item.completedTasks + 1,
                    totalTasks = item.totalTasks + 1
                )
            } else {
                item
            }
        }

        progress[userId] = current.copy(
            domains = updatedDomains,
            updatedAt = System.currentTimeMillis()
        )

        val today = dailyProgress[date]
            ?: SystemDailyProgress(date)

        dailyProgress[date] = today.copy(
            completedTasks = today.completedTasks + 1,
            earnedExperience = today.earnedExperience + experienceReward,
            activeDomains = (
                today.activeDomains + domain
            ).distinct()
        )

        return addExperience(
            userId = userId,
            domain = domain,
            amount = experienceReward,
            reason = "Task completed"
        )
    }

    fun getExperienceHistory(
        userId: String
    ): List<SystemExperienceRecord> {
        return experienceRecords.filter {
            it.userId == userId
        }
    }

    fun getDailyProgress(
        date: String
    ): SystemDailyProgress {
        return dailyProgress[date]
            ?: SystemDailyProgress(date)
    }

    fun getAllProgress(): List<SystemProgressSnapshot> {
        return progress.values.toList()
    }

    private fun calculateLevel(experience: Int): Int {
        if (experience <= 0) return 1
        return (experience / 100) + 1
    }
}
