package com.system.irtqaa

import android.content.Context
import java.time.LocalDate

class SystemProgressEngine(context: Context) {

    private val progressManager =
        SystemProgressPersistentManagerV2(
            context.applicationContext
        )

    fun getProgress(userId: String): SystemProgressSnapshot {
        require(userId.isNotBlank())
        return progressManager.getProgress(userId)
    }

    fun addExperience(
        userId: String,
        domain: SystemDevelopmentDomain,
        amount: Int,
        reason: String,
        timestamp: Long = System.currentTimeMillis()
    ): SystemProgressSnapshot {
        require(userId.isNotBlank())

        return progressManager.addExperience(
            userId = userId,
            domain = domain,
            amount = amount,
            reason = reason,
            timestamp = timestamp
        )
    }

    fun completeTask(
        userId: String,
        domain: SystemDevelopmentDomain,
        experienceReward: Int,
        date: String = LocalDate.now().toString()
    ): SystemProgressSnapshot {
        require(userId.isNotBlank())

        return progressManager.completeTask(
            userId = userId,
            domain = domain,
            experienceReward = experienceReward,
            date = date
        )
    }

    fun getExperienceHistory(
        userId: String
    ): List<SystemExperienceRecord> {
        require(userId.isNotBlank())
        return progressManager.getExperienceHistory(userId)
    }

    fun getDailyProgress(
        userId: String,
        date: String
    ): SystemDailyProgress {
        require(userId.isNotBlank())

        return progressManager.getDailyProgress(
            userId = userId,
            date = date
        )
    }

    fun resetUserProgress(userId: String): Boolean {
        require(userId.isNotBlank())
        return progressManager.resetUserProgress(userId)
    }
}
