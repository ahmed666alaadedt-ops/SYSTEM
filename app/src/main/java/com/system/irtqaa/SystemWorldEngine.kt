package com.system.irtqaa

object SystemWorldEngine {

    fun getAvailableLocations(
        progress: PlayerWorldProgress
    ): List<WorldLocation> {
        return SystemWorldData.locations.map { location ->
            location.copy(
                isUnlocked = progress.playerLevel >= location.requiredLevel
            )
        }
    }

    fun getAvailableGates(
        progress: PlayerWorldProgress
    ): List<StarGate> {
        return SystemWorldData.starGates.map { gate ->
            gate.copy(
                isUnlocked = progress.playerLevel >= gate.requiredLevel
            )
        }
    }

    fun getAvailableMissions(
        progress: PlayerWorldProgress
    ): List<WorldMission> {
        return SystemWorldData.missions.map { mission ->
            mission.copy(
                isCompleted = mission.id in progress.completedMissions
            )
        }.filter {
            progress.playerLevel >= it.requiredLevel
        }
    }

    fun completeMission(
        progress: PlayerWorldProgress,
        missionId: String
    ): PlayerWorldProgress {

        val mission = SystemWorldData.missions
            .firstOrNull { it.id == missionId }
            ?: return progress

        if (missionId in progress.completedMissions) {
            return progress
        }

        if (progress.playerLevel < mission.requiredLevel) {
            return progress
        }

        val newExperience = progress.experience + mission.xpReward

        val newLevel = 1 + (newExperience / 100)

        return progress.copy(
            playerLevel = newLevel,
            experience = newExperience,
            coins = progress.coins + (mission.xpReward / 2),
            completedMissions =
                progress.completedMissions + missionId,
            unlockedLocations = getAvailableLocations(
                progress.copy(playerLevel = newLevel)
            ).filter { it.isUnlocked }.map { it.id }.toSet()
        )
    }

    fun getNextLevelExperience(
        progress: PlayerWorldProgress
    ): Int {
        return 100 - (progress.experience % 100)
    }

    fun getLevelProgress(
        progress: PlayerWorldProgress
    ): Int {
        return progress.experience % 100
    }
}
