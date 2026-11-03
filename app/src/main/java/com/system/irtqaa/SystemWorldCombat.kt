package com.system.irtqaa

data class WorldBattleResult(
    val victory: Boolean,
    val monsterName: String,
    val message: String,
    val xpGained: Int,
    val coinsGained: Int,
    val updatedProgress: PlayerWorldProgress
)

object SystemWorldCombat {

    fun fightMonster(
        progress: PlayerWorldProgress,
        monsterId: String,
        playerPower: Int
    ): WorldBattleResult {

        val monster = SystemWorldData.monsters
            .firstOrNull { it.id == monsterId }

        if (monster == null) {
            return WorldBattleResult(
                victory = false,
                monsterName = "غير معروف",
                message = "هذا الوحش غير موجود.",
                xpGained = 0,
                coinsGained = 0,
                updatedProgress = progress
            )
        }

        if (progress.playerLevel < monster.level) {
            return WorldBattleResult(
                victory = false,
                monsterName = monster.name,
                message = "مستواك غير كافٍ لمواجهة هذا الوحش.",
                xpGained = 0,
                coinsGained = 0,
                updatedProgress = progress
            )
        }

        if (playerPower < monster.level * 10) {
            return WorldBattleResult(
                victory = false,
                monsterName = monster.name,
                message = "لم تكن قوتك كافية للفوز بالمعركة.",
                xpGained = 0,
                coinsGained = 0,
                updatedProgress = progress
            )
        }

        val newExperience =
            progress.experience + monster.xpReward

        val newLevel = 1 + (newExperience / 100)

        val newProgress = progress.copy(
            playerLevel = newLevel,
            experience = newExperience,
            coins = progress.coins + monster.xpReward / 2,
            unlockedLocations =
                progress.unlockedLocations +
                SystemWorldEngine.getAvailableLocations(
                    progress.copy(playerLevel = newLevel)
                ).filter { it.isUnlocked }.map { it.id }
        )

        return WorldBattleResult(
            victory = true,
            monsterName = monster.name,
            message = "انتصرت على ${monster.name}!",
            xpGained = monster.xpReward,
            coinsGained = monster.xpReward / 2,
            updatedProgress = newProgress
        )
    }
}
