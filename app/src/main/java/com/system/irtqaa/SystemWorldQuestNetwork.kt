
package com.system.irtqaa

/**
 * شبكة المهمات العابرة لعوالم SYSTEM WORLD.
 * تربط المهمات بين العالم الحديث والتاريخي والخيالي وجزيرة الطمع.
 */

data class SystemWorldQuestStage(
    val id: String,
    val title: String,
    val description: String,
    val worldId: String,
    val requiredClue: String,
    val experienceReward: Int,
    val nextStageId: String? = null
)

data class SystemWorldQuestChain(
    val id: String,
    val title: String,
    val description: String,
    val stages: List<SystemWorldQuestStage>,
    val isGlobalEvent: Boolean = false
)

data class SystemPlayerQuestProgress(
    val playerId: String,
    val chainId: String,
    val completedStageIds: Set<String> = emptySet(),
    val discoveredClues: Set<String> = emptySet(),
    val artifactFound: Boolean = false,
    val islandAccessUnlocked: Boolean = false
)

data class SystemGlobalArtifactEvent(
    val artifactId: String,
    val name: String,
    val description: String,
    val requiredWorlds: List<String>,
    val isSeasonal: Boolean,
    val opensGreedIsland: Boolean
)

object SystemWorldQuestNetwork {

    const val MODERN = "real"
    const val HISTORY = "mythology"
    const val FANTASY = "fantasy"
    const val GREED = "greed"

    const val RARE_ARTIFACT_ID = "eternal_world_artifact"

    val globalArtifact = SystemGlobalArtifactEvent(
        artifactId = RARE_ARTIFACT_ID,
        name = "قطعة العوالم الأزلية",
        description = """
            قطعة نادرة مخفية داخل أسرار العوالم الأربعة.
            يبحث عنها جميع اللاعبين ويجمعون الأدلة للوصول إليها.
            اكتشافها وإنجاز شروطها يفتح طريق جزيرة الطمع.
        """.trimIndent(),
        requiredWorlds = listOf(
            MODERN,
            HISTORY,
            FANTASY
        ),
        isSeasonal = true,
        opensGreedIsland = true
    )

    val artifactQuest = SystemWorldQuestChain(
        id = "global_artifact_hunt",
        title = "البحث العالمي عن القطعة النادرة",
        description = """
            حدث عالمي يشارك فيه جميع اللاعبين.
            الأدلة موزعة بين العوالم، وعلى اللاعب
            اكتشافها وربط أسرارها حتى يصل إلى القطعة.
        """.trimIndent(),
        isGlobalEvent = true,
        stages = listOf(

            SystemWorldQuestStage(
                id = "modern_clue",
                title = "الأثر المجهول",
                description = """
                    ابحث في العالم الحديث عن أثر غريب
                    يقود إلى سر قديم.
                """.trimIndent(),
                worldId = MODERN,
                requiredClue = "modern_artifact_clue",
                experienceReward = 300,
                nextStageId = "historical_clue"
            ),

            SystemWorldQuestStage(
                id = "historical_clue",
                title = "سر الحضارة القديمة",
                description = """
                    انتقل إلى الحضارات التاريخية،
                    وابحث عن النقش الذي يفسر أصل الأثر.
                """.trimIndent(),
                worldId = HISTORY,
                requiredClue = "ancient_inscription",
                experienceReward = 500,
                nextStageId = "fantasy_clue"
            ),

            SystemWorldQuestStage(
                id = "fantasy_clue",
                title = "حارس السر",
                description = """
                    ادخل العالم الخيالي واكتشف السر
                    الذي يحرسه أحد الكائنات الأسطورية.
                """.trimIndent(),
                worldId = FANTASY,
                requiredClue = "fantasy_guardian_secret",
                experienceReward = 800,
                nextStageId = "artifact_discovery"
            ),

            SystemWorldQuestStage(
                id = "artifact_discovery",
                title = "اكتشاف القطعة الأزلية",
                description = """
                    اجمع الأدلة الثلاثة واكتشف موقع
                    قطعة العوالم الأزلية.
                """.trimIndent(),
                worldId = FANTASY,
                requiredClue = RARE_ARTIFACT_ID,
                experienceReward = 2000,
                nextStageId = "greed_island_entry"
            ),

            SystemWorldQuestStage(
                id = "greed_island_entry",
                title = "بوابة جزيرة الطمع",
                description = """
                    استخدم القطعة النادرة لفتح طريق
                    جزيرة الطمع والدخول إلى موسمها.
                """.trimIndent(),
                worldId = GREED,
                requiredClue = "greed_island_access",
                experienceReward = 3000
            )
        )
    )

    /**
     * مهمات إضافية تسمح بانتقال القصة بين العوالم.
     */
    val crossWorldStories = listOf(

        SystemWorldQuestChain(
            id = "past_to_future",
            title = "رسالة من الماضي إلى المستقبل",
            description = "قصة تبدأ في التاريخ وتستمر في المستقبل.",
            stages = listOf(
                SystemWorldQuestStage(
                    id = "past_message",
                    title = "المخطوطة القديمة",
                    description = "اكتشف المخطوطة في الحضارة القديمة.",
                    worldId = HISTORY,
                    requiredClue = "future_prophecy",
                    experienceReward = 400,
                    nextStageId = "future_investigation"
                ),
                SystemWorldQuestStage(
                    id = "future_investigation",
                    title = "التحقيق في المستقبل",
                    description = "انتقل إلى المستقبل وابحث عن حقيقة النبوءة.",
                    worldId = MODERN,
                    requiredClue = "future_truth",
                    experienceReward = 900
                )
            )
        ),

        SystemWorldQuestChain(
            id = "fantasy_to_modern",
            title = "سر التنين",
            description = "سر أسطوري يقود إلى تجربة في العالم الحديث.",
            stages = listOf(
                SystemWorldQuestStage(
                    id = "dragon_mark",
                    title = "علامة التنين",
                    description = "اكتشف العلامة الغامضة في العالم الخيالي.",
                    worldId = FANTASY,
                    requiredClue = "dragon_mark",
                    experienceReward = 500,
                    nextStageId = "modern_lab"
                ),
                SystemWorldQuestStage(
                    id = "modern_lab",
                    title = "المختبر السري",
                    description = "ابحث عن أصل العلامة في العالم الحديث.",
                    worldId = MODERN,
                    requiredClue = "dragon_experiment",
                    experienceReward = 1000
                )
            )
        )
    )

    fun getAllQuestChains(): List<SystemWorldQuestChain> {
        return listOf(artifactQuest) + crossWorldStories
    }

    fun getQuestChain(
        chainId: String
    ): SystemWorldQuestChain? {
        return getAllQuestChains().find {
            it.id == chainId
        }
    }

    fun getNextStage(
        progress: SystemPlayerQuestProgress
    ): SystemWorldQuestStage? {
        val chain = getQuestChain(progress.chainId)
            ?: return null

        return chain.stages.firstOrNull {
            it.id !in progress.completedStageIds
        }
    }

    fun canCompleteStage(
        stage: SystemWorldQuestStage,
        progress: SystemPlayerQuestProgress
    ): Boolean {
        return stage.requiredClue in progress.discoveredClues
    }

    fun discoverClue(
        progress: SystemPlayerQuestProgress,
        clueId: String
    ): SystemPlayerQuestProgress {
        return progress.copy(
            discoveredClues = progress.discoveredClues + clueId
        )
    }

    fun completeStage(
        progress: SystemPlayerQuestProgress,
        stageId: String
    ): SystemPlayerQuestProgress {
        val chain = getQuestChain(progress.chainId)
            ?: return progress

        val stage = chain.stages.firstOrNull {
            it.id == stageId
        } ?: return progress

        val expectedStage = getNextStage(progress)

        if (expectedStage?.id != stageId) return progress
        if (!canCompleteStage(stage, progress)) return progress

        val updated = progress.copy(
            completedStageIds = progress.completedStageIds + stageId
        )

        val artifactFound =
            chain.id == artifactQuest.id &&
            stageId == "artifact_discovery"

        val islandUnlocked =
            chain.id == artifactQuest.id &&
            stageId == "greed_island_entry"

        return updated.copy(
            artifactFound = updated.artifactFound || artifactFound,
            islandAccessUnlocked =
                updated.islandAccessUnlocked || islandUnlocked
        )
    }

    fun hasAllArtifactClues(
        progress: SystemPlayerQuestProgress
    ): Boolean {
        return listOf(
            "modern_artifact_clue",
            "ancient_inscription",
            "fantasy_guardian_secret"
        ).all {
            it in progress.discoveredClues
        }
    }

    fun canEnterGreedIsland(
        progress: SystemPlayerQuestProgress
    ): Boolean {
        return progress.artifactFound &&
            progress.islandAccessUnlocked
    }
}
