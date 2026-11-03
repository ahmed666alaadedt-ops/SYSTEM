
package com.system.irtqaa

import android.content.Context

class SystemProgressAccountManagerV2(context: Context) {

    private val oldAccountManager =
        SystemProgressAccountManager(context.applicationContext)

    private val progressManager =
        SystemProgressPersistentManagerV2(context.applicationContext)

    fun getOrCreateProfile(
        playerId: String,
        playerName: String,
        membershipNumber: String
    ): SystemPlayerProfile {
        return oldAccountManager.getOrCreateProfile(
            playerId,
            playerName,
            membershipNumber
        )
    }

    fun getProfile(playerId: String): SystemPlayerProfile? {
        return oldAccountManager.getProfile(playerId)
    }

    fun saveProfile(profile: SystemPlayerProfile): Boolean {
        return oldAccountManager.saveProfile(profile)
    }

    fun getProgress(playerId: String): SystemProgressSnapshot {
        require(playerId.isNotBlank())
        return progressManager.getProgress(playerId)
    }

    fun addExperience(
        playerId: String,
        domain: SystemDevelopmentDomain,
        amount: Int,
        reason: String
    ): SystemProgressSnapshot {
        require(playerId.isNotBlank())

        val updated = progressManager.addExperience(
            userId = playerId,
            domain = domain,
            amount = amount,
            reason = reason
        )

        updateProfileLevel(playerId, updated)
        return updated
    }

    fun completeTask(
        playerId: String,
        domain: SystemDevelopmentDomain,
        experienceReward: Int,
        date: String
    ): SystemProgressSnapshot {
        require(playerId.isNotBlank())

        val updated = progressManager.completeTask(
            userId = playerId,
            domain = domain,
            experienceReward = experienceReward,
            date = date
        )

        updateProfileLevel(playerId, updated)
        return updated
    }

    fun getExperienceHistory(
        playerId: String
    ): List<SystemExperienceRecord> {
        return progressManager.getExperienceHistory(playerId)
    }

    fun getDailyProgress(
        playerId: String,
        date: String
    ): SystemDailyProgress {
        require(playerId.isNotBlank())
        return progressManager.getDailyProgress(playerId, date)
    }

    fun addBadge(playerId: String, badge: String): Boolean {
        return oldAccountManager.addBadge(playerId, badge)
    }

    fun addAchievement(
        playerId: String,
        achievement: String
    ): Boolean {
        return oldAccountManager.addAchievement(playerId, achievement)
    }

    fun updatePlayerName(
        playerId: String,
        newName: String
    ): Boolean {
        return oldAccountManager.updatePlayerName(playerId, newName)
    }

    fun updateAvatar(
        playerId: String,
        avatarImage: String?
    ): Boolean {
        return oldAccountManager.updateAvatar(playerId, avatarImage)
    }

    fun updateTitle(
        playerId: String,
        newTitle: String
    ): Boolean {
        return oldAccountManager.updateTitle(playerId, newTitle)
    }

    fun resetProgress(playerId: String): Boolean {
        require(playerId.isNotBlank())

        val deleted = progressManager.resetUserProgress(playerId)
        if (!deleted) return false

        val profile = getProfile(playerId) ?: return true

        val resetProfile = profile.copy(
            rank = SystemPlayerRank.BEGINNER,
            level = 1,
            experience = 0
        )

        return saveProfile(resetProfile)
    }

    private fun updateProfileLevel(
        playerId: String,
        progress: SystemProgressSnapshot
    ) {
        val profile = getProfile(playerId) ?: return

        val updatedProfile = SystemPlayerProfileEngine.updateLevel(
            profile = profile,
            newLevel = progress.overallLevel,
            newExperience = progress.totalExperience
        )

        check(saveProfile(updatedProfile)) {
            "Could not save player profile"
        }
    }
}
