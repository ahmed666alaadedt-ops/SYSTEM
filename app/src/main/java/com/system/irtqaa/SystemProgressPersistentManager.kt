
package com.system.irtqaa

import android.content.Context
import java.time.LocalDate

class SystemProgressPersistentManager(context: Context) {

    private val storage = SystemProgressStorage(context)

    private val lock = Any()

    fun getProgress(userId: String): SystemProgressSnapshot {
        require(userId.isNotBlank()) {
            "User ID cannot be blank"
        }

        synchronized(lock) {
            return storage.loadProgress(userId)
                ?: createInitialProgress(userId)
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

        synchronized(lock) {
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

            val history = storage.loadExperienceHistory(userId)
                .toMutableList()

            history.add(
                SystemExperienceRecord(
                    recordId = "XP-$timestamp-${history.size}",
                    userId = userId,
                    domain = domain,
                    amount = amount,
                    reason = reason,
                    createdAt = timestamp
                )
            )

            check(storage.saveProgress(updated)) {
                "Could not save progress"
            }

            check(storage.saveExperienceHistory(userId, history)) {
                "Could not save experience history"
            }

            return updated
        }
    }

    fun completeTask(
        userId: String,
        domain: SystemDevelopmentDomain,
        experienceReward: Int,
        date: String = LocalDate.now().toString()
    ): SystemProgressSnapshot {
        require(experienceReward > 0)
        require(date.isNotBlank())

        synchronized(lock) {
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

            val taskUpdated = current.copy(
                domains = updatedDomains,
                updatedAt = System.currentTimeMillis()
            )

            check(storage.saveProgress(taskUpdated)) {
                "Could not save task progress"
            }

            val daily = storage.loadDailyProgress(date)

            val updatedDaily = daily.copy(
                completedTasks = daily.completedTasks + 1,
                earnedExperience = daily.earnedExperience + experienceReward,
                activeDomains = (
                    daily.activeDomains + domain
                ).distinct()
            )

            check(storage.saveDailyProgress(updatedDaily)) {
                "Could not save daily progress"
            }

            return addExperience(
                userId = userId,
                domain = domain,
                amount = experienceReward,
                reason = "Task completed",
                timestamp = System.currentTimeMillis()
            )
        }
    }

    fun getExperienceHistory(
        userId: String
    ): List<SystemExperienceRecord> {
        require(userId.isNotBlank())

        synchronized(lock) {
            return storage.loadExperienceHistory(userId)
        }
    }

    fun getDailyProgress(date: String): SystemDailyProgress {
        require(date.isNotBlank())

        synchronized(lock) {
            return storage.loadDailyProgress(date)
        }
    }

    fun resetUserProgress(userId: String): Boolean {
        require(userId.isNotBlank())

        synchronized(lock) {
            return storage.deleteUserProgress(userId)
        }
    }

    private fun createInitialProgress(
        userId: String
    ): SystemProgressSnapshot {
        return SystemProgressSnapshot(
            userId = userId,
            domains = SystemDevelopmentDomain.values().map {
                SystemDomainProgress(domain = it)
            }
        )
    }

    private fun calculateLevel(experience: Int): Int {
        if (experience <= 0) return 1
        return (experience / 100) + 1
    }
}
