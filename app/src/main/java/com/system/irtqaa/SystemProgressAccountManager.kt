package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

class SystemProgressAccountManager(context: Context) {

    private val appContext = context.applicationContext

    private val preferences = appContext.getSharedPreferences(
        "system_progress_accounts",
        Context.MODE_PRIVATE
    )

    private val progressManager =
        SystemProgressPersistentManager(appContext)

    private val lock = Any()

    fun getOrCreateProfile(
        playerId: String,
        playerName: String,
        membershipNumber: String
    ): SystemPlayerProfile {

        require(playerId.isNotBlank())
        require(playerName.isNotBlank())
        require(membershipNumber.isNotBlank())

        synchronized(lock) {
            val existing = getProfile(playerId)

            if (existing != null) {
                return existing
            }

            val profile = SystemPlayerProfile(
                playerId = playerId,
                playerName = playerName,
                membershipNumber = membershipNumber,
                joinedAt = System.currentTimeMillis()
            )

            saveProfile(profile)

            return profile
        }
    }

    fun getProfile(playerId: String): SystemPlayerProfile? {
        if (playerId.isBlank()) return null

        return synchronized(lock) {
            try {
                val raw = preferences.getString(
                    profileKey(playerId),
                    null
                ) ?: return@synchronized null

                val json = JSONObject(raw)

                val badgesArray =
                    json.optJSONArray("badges") ?: JSONArray()

                val achievementsArray =
                    json.optJSONArray("achievements") ?: JSONArray()

                val badges = mutableListOf<String>()
                val achievements = mutableListOf<String>()

                for (i in 0 until badgesArray.length()) {
                    badges.add(badgesArray.getString(i))
                }

                for (i in 0 until achievementsArray.length()) {
                    achievements.add(
                        achievementsArray.getString(i)
                    )
                }

                val rank = runCatching {
                    SystemPlayerRank.valueOf(
                        json.optString(
                            "rank",
                            SystemPlayerRank.BEGINNER.name
                        )
                    )
                }.getOrDefault(SystemPlayerRank.BEGINNER)

                SystemPlayerProfile(
                    playerId = json.optString("playerId"),
                    playerName = json.optString("playerName"),
                    membershipNumber =
                        json.optString("membershipNumber"),
                    rank = rank,
                    level = json.optInt("level", 1),
                    experience = json.optInt("experience", 0),
                    avatarImage = json.optString(
                        "avatarImage"
                    ).takeIf { it.isNotBlank() },
                    title = json.optString(
                        "title",
                        "عضو جديد"
                    ),
                    badges = badges,
                    achievements = achievements,
                    joinedAt = json.optLong("joinedAt", 0L)
                )
            } catch (exception: Exception) {
                null
            }
        }
    }

    fun saveProfile(profile: SystemPlayerProfile): Boolean {
        return synchronized(lock) {
            try {
                val badgesArray = JSONArray()
                profile.badges.forEach {
                    badgesArray.put(it)
                }

                val achievementsArray = JSONArray()
                profile.achievements.forEach {
                    achievementsArray.put(it)
                }

                val json = JSONObject().apply {
                    put("playerId", profile.playerId)
                    put("playerName", profile.playerName)
                    put("membershipNumber", profile.membershipNumber)
                    put("rank", profile.rank.name)
                    put("level", profile.level)
                    put("experience", profile.experience)
                    put("avatarImage", profile.avatarImage ?: "")
                    put("title", profile.title)
                    put("badges", badgesArray)
                    put("achievements", achievementsArray)
                    put("joinedAt", profile.joinedAt)
                }

                preferences.edit()
                    .putString(
                        profileKey(profile.playerId),
                        json.toString()
                    )
                    .commit()

            } catch (exception: Exception) {
                false
            }
        }
    }

    fun getProgress(
        playerId: String
    ): SystemProgressSnapshot {
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

        synchronized(lock) {

            val updatedProgress = progressManager.addExperience(
                userId = playerId,
                domain = domain,
                amount = amount,
                reason = reason
            )

            val profile = getProfile(playerId)

            if (profile != null) {
                val updatedProfile =
                    SystemPlayerProfileEngine.updateLevel(
                        profile = profile,
                        newLevel = updatedProgress.overallLevel,
                        newExperience = updatedProgress.totalExperience
                    )

                check(saveProfile(updatedProfile)) {
                    "Could not save player profile"
                }
            }

            return updatedProgress
        }
    }

    fun completeTask(
        playerId: String,
        domain: SystemDevelopmentDomain,
        experienceReward: Int,
        date: String
    ): SystemProgressSnapshot {

        require(playerId.isNotBlank())

        synchronized(lock) {

            val updatedProgress = progressManager.completeTask(
                userId = playerId,
                domain = domain,
                experienceReward = experienceReward,
                date = date
            )

            val profile = getProfile(playerId)

            if (profile != null) {
                val updatedProfile =
                    SystemPlayerProfileEngine.updateLevel(
                        profile = profile,
                        newLevel = updatedProgress.overallLevel,
                        newExperience = updatedProgress.totalExperience
                    )

                check(saveProfile(updatedProfile)) {
                    "Could not save player profile"
                }
            }

            return updatedProgress
        }
    }

    fun addBadge(
        playerId: String,
        badge: String
    ): Boolean {

        synchronized(lock) {
            val profile = getProfile(playerId) ?: return false

            val updated = SystemPlayerProfileEngine.addBadge(
                profile,
                badge
            )

            return saveProfile(updated)
        }
    }

    fun addAchievement(
        playerId: String,
        achievement: String
    ): Boolean {

        synchronized(lock) {
            val profile = getProfile(playerId) ?: return false

            val updated =
                SystemPlayerProfileEngine.addAchievement(
                    profile,
                    achievement
                )

            return saveProfile(updated)
        }
    }

    fun updatePlayerName(
        playerId: String,
        newName: String
    ): Boolean {

        if (newName.isBlank()) return false

        synchronized(lock) {
            val profile = getProfile(playerId) ?: return false

            return saveProfile(
                profile.copy(playerName = newName)
            )
        }
    }

    fun updateAvatar(
        playerId: String,
        avatarImage: String?
    ): Boolean {

        synchronized(lock) {
            val profile = getProfile(playerId) ?: return false

            return saveProfile(
                profile.copy(avatarImage = avatarImage)
            )
        }
    }

    fun updateTitle(
        playerId: String,
        newTitle: String
    ): Boolean {

        if (newTitle.isBlank()) return false

        synchronized(lock) {
            val profile = getProfile(playerId) ?: return false

            return saveProfile(
                profile.copy(title = newTitle)
            )
        }
    }

    fun getExperienceHistory(
        playerId: String
    ): List<SystemExperienceRecord> {

        return progressManager.getExperienceHistory(playerId)
    }

    fun getDailyProgress(
        date: String
    ): SystemDailyProgress {

        return progressManager.getDailyProgress(date)
    }

    fun resetProgress(playerId: String): Boolean {
        require(playerId.isNotBlank())

        synchronized(lock) {
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
    }

    private fun profileKey(playerId: String): String {
        return "player_profile_$playerId"
    }
}
