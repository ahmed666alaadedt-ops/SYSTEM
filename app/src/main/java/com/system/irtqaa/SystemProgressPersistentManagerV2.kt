package com.system.irtqaa

import android.content.Context
import android.util.Log
import java.time.LocalDate

class SystemProgressPersistentManagerV2(context: Context) {

    private val storage = SystemProgressStorageV2(context)
    private val cloudRepository = FirebaseSystemProgressRepository()
    private val lock = Any()

    companion object {
        private const val TAG = "SystemProgressManager"
    }

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

            val record = SystemExperienceRecord(
                recordId = "XP-$timestamp-${history.size}",
                userId = userId,
                domain = domain,
                amount = amount,
                reason = reason,
                createdAt = timestamp
            )

            history.add(record)

            check(storage.saveProgress(updated)) {
                "Could not save progress"
            }

            check(storage.saveExperienceHistory(userId, history)) {
                "Could not save experience history"
            }

            // رفع التقدم إلى الحساب السحابي
            cloudRepository.saveProgress(updated) { success, error ->
                if (!success) {
                    Log.e(TAG, "Cloud progress upload failed", error)
                }
            }

            // رفع سجل الخبرة
            cloudRepository.saveExperienceRecord(record) { success, error ->
                if (!success) {
                    Log.e(TAG, "Cloud experience history upload failed", error)
                }
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
        require(userId.isNotBlank())
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

            val daily = storage.loadDailyProgress(userId, date)

            val updatedDaily = daily.copy(
                completedTasks = daily.completedTasks + 1,
                earnedExperience = daily.earnedExperience + experienceReward,
                activeDomains = (
                    daily.activeDomains + domain
                ).distinct()
            )

            check(storage.saveDailyProgress(userId, updatedDaily)) {
                "Could not save daily progress"
            }

            // رفع تقدم اليوم إلى Firestore
            cloudRepository.saveDailyProgress(
                userId,
                updatedDaily
            ) { success, error ->
                if (!success) {
                    Log.e(TAG, "Cloud daily progress upload failed", error)
                }
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

    fun getDailyProgress(
        userId: String,
        date: String
    ): SystemDailyProgress {
        require(userId.isNotBlank())
        require(date.isNotBlank())

        synchronized(lock) {
            return storage.loadDailyProgress(userId, date)
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
