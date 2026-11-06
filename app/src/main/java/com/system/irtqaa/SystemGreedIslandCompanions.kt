
package com.system.irtqaa

/**
 * نظام الوحوش الأسطورية والمرافقين في SYSTEM WORLD.
 *
 * قواعد الاستدعاء:
 * - العالم الخيالي: يسمح بالاستدعاء الفعلي.
 * - جزيرة الطمع: يسمح بالاستدعاء الفعلي.
 * - العالم الحديث والتاريخي: لا يسمح بظهور الوحش،
 *   وتتحول قوته إلى قدرات داخل جسم اللاعب.
 */

enum class CompanionWorld(
    val worldId: String
) {
    MODERN("real"),
    HISTORICAL("mythology"),
    FANTASY("fantasy"),
    GREED_ISLAND("greed");

    companion object {
        fun fromWorldId(worldId: String): CompanionWorld? {
            return values().firstOrNull {
                it.worldId == worldId
            }
        }
    }
}

enum class CompanionUseMode {
    SUMMON_COMPANION,
    INTERNAL_BEAST_POWER,
    UNAVAILABLE
}

enum class MythicalCompanionType {
    DRAGON,
    PHOENIX,
    GIANT_BEAST,
    SHADOW_BEAST,
    CELESTIAL_BEAST
}

data class CompanionPower(
    val strengthBonus: Int,
    val speedBonus: Int,
    val defenseBonus: Int,
    val staminaBonus: Int,
    val specialAbility: String
)

data class MythicalCompanion(
    val id: String,
    val name: String,
    val title: String,
    val type: MythicalCompanionType,
    val description: String,
    val level: Int,
    val rarity: String,
    val power: CompanionPower,
    val canFly: Boolean,
    val canFight: Boolean
)

data class PlayerMythicalCompanion(
    val playerId: String,
    val companionId: String,
    val isUnlocked: Boolean,
    val isEquipped: Boolean = true,
    val companionLevel: Int = 1,
    val bondLevel: Int = 1
)

data class CompanionWorldResult(
    val mode: CompanionUseMode,
    val canAppear: Boolean,
    val canUseInternalPower: Boolean,
    val explanation: String
)

object SystemGreedIslandCompanions {

    const val COMPANION_REWARD_SOURCE = "tournament_winner"

    /**
     * الاستدعاء الفعلي مسموح فقط في الخيالي وجزيرة الطمع.
     */
    fun getUseMode(
        worldId: String
    ): CompanionUseMode {

        return when (
            CompanionWorld.fromWorldId(worldId)
        ) {
            CompanionWorld.FANTASY,
            CompanionWorld.GREED_ISLAND ->
                CompanionUseMode.SUMMON_COMPANION

            CompanionWorld.MODERN,
            CompanionWorld.HISTORICAL ->
                CompanionUseMode.INTERNAL_BEAST_POWER

            null ->
                CompanionUseMode.UNAVAILABLE
        }
    }

    /**
     * تحديد طريقة استخدام المرافق داخل العالم.
     */
    fun getWorldResult(
        worldId: String,
        hasUnlockedCompanion: Boolean
    ): CompanionWorldResult {

        if (!hasUnlockedCompanion) {
            return CompanionWorldResult(
                mode = CompanionUseMode.UNAVAILABLE,
                canAppear = false,
                canUseInternalPower = false,
                explanation = "يجب الفوز بمكافأة الوحش الأسطوري أولاً."
            )
        }

        return when (getUseMode(worldId)) {

            CompanionUseMode.SUMMON_COMPANION ->
                CompanionWorldResult(
                    mode = CompanionUseMode.SUMMON_COMPANION,
                    canAppear = true,
                    canUseInternalPower = true,
                    explanation = "يمكن استدعاء الوحش ومرافقته للاعب."
                )

            CompanionUseMode.INTERNAL_BEAST_POWER ->
                CompanionWorldResult(
                    mode = CompanionUseMode.INTERNAL_BEAST_POWER,
                    canAppear = false,
                    canUseInternalPower = true,
                    explanation = "لا يظهر الوحش، لكن يستطيع اللاعب استخدام قوته داخل جسده."
                )

            CompanionUseMode.UNAVAILABLE ->
                CompanionWorldResult(
                    mode = CompanionUseMode.UNAVAILABLE,
                    canAppear = false,
                    canUseInternalPower = false,
                    explanation = "هذا العالم غير معروف في نظام المرافقين."
                )
        }
    }

    /**
     * لا يحصل اللاعب على مرافق أسطوري إلا بعد استحقاق المكافأة.
     */
    fun canUnlockCompanion(
        tournamentWinner: Boolean,
        rewardGranted: Boolean
    ): Boolean {
        return tournamentWinner && rewardGranted
    }

    /**
     * أمثلة الوحوش الأسطورية الموجودة في الجزيرة.
     * هذه بيانات تعريفية وليست نظام قتال منفذاً بحد ذاته.
     */
    val mythicalCompanions = listOf(

        MythicalCompanion(
            id = "ancient_dragon",
            name = "التنين العتيق",
            title = "سيد اللهب",
            type = MythicalCompanionType.DRAGON,
            description = "تنين أسطوري عظيم يمتلك قوة اللهب والطيران.",
            level = 80,
            rarity = "أسطوري",
            power = CompanionPower(
                strengthBonus = 35,
                speedBonus = 25,
                defenseBonus = 30,
                staminaBonus = 35,
                specialAbility = "اللهب العتيق"
            ),
            canFly = true,
            canFight = true
        ),

        MythicalCompanion(
            id = "phoenix_guardian",
            name = "حارس العنقاء",
            title = "روح التجدد",
            type = MythicalCompanionType.PHOENIX,
            description = "طائر أسطوري يمتلك طاقة نارية وقدرة على التجدد.",
            level = 75,
            rarity = "أسطوري",
            power = CompanionPower(
                strengthBonus = 20,
                speedBonus = 35,
                defenseBonus = 25,
                staminaBonus = 35,
                specialAbility = "طاقة العنقاء"
            ),
            canFly = true,
            canFight = true
        ),

        MythicalCompanion(
            id = "mountain_titan_beast",
            name = "وحش الجبال",
            title = "قوة العمالقة",
            type = MythicalCompanionType.GIANT_BEAST,
            description = "وحش أرضي ضخم يمتلك قوة جسدية هائلة.",
            level = 70,
            rarity = "ملحمي",
            power = CompanionPower(
                strengthBonus = 40,
                speedBonus = 10,
                defenseBonus = 40,
                staminaBonus = 30,
                specialAbility = "ضربة العملاق"
            ),
            canFly = false,
            canFight = true
        ),

        MythicalCompanion(
            id = "shadow_wing_beast",
            name = "وحش الجناح الظلي",
            title = "سيد الظلال",
            type = MythicalCompanionType.SHADOW_BEAST,
            description = "كائن سريع يتحرك بين الظلال ويتميز بالمراوغة.",
            level = 65,
            rarity = "نادر",
            power = CompanionPower(
                strengthBonus = 20,
                speedBonus = 40,
                defenseBonus = 15,
                staminaBonus = 25,
                specialAbility = "اندفاع الظلال"
            ),
            canFly = true,
            canFight = true
        )
    )

    fun findCompanion(
        companionId: String
    ): MythicalCompanion? {
        return mythicalCompanions.firstOrNull {
            it.id == companionId
        }
    }

    /**
     * فحص إمكانية الاستدعاء قبل تنفيذ الاستدعاء داخل اللعبة.
     */
    fun canSummon(
        worldId: String,
        companion: PlayerMythicalCompanion?
    ): Boolean {

        if (companion == null) return false
        if (!companion.isUnlocked) return false
        if (!companion.isEquipped) return false

        return getUseMode(worldId) ==
            CompanionUseMode.SUMMON_COMPANION
    }

    /**
     * فحص إمكانية استخدام القوة الداخلية.
     */
    fun canUseInternalPower(
        worldId: String,
        companion: PlayerMythicalCompanion?
    ): Boolean {

        if (companion == null) return false
        if (!companion.isUnlocked) return false
        if (!companion.isEquipped) return false

        return getUseMode(worldId) ==
            CompanionUseMode.INTERNAL_BEAST_POWER
    }

    /**
     * إرجاع قوة المرافق للاستخدام الداخلي.
     * تطبيق تأثيرها الفعلي على القتال يحتاج ربطاً بمحرك القتال.
     */
    fun getInternalPower(
        worldId: String,
        companion: PlayerMythicalCompanion?
    ): CompanionPower? {

        if (!canUseInternalPower(worldId, companion)) {
            return null
        }

        return findCompanion(
            companion!!.companionId
        )?.power
    }
}
