
package com.system.irtqaa

enum class SystemDevelopmentDomain {
    SPIRIT,
    MIND,
    BODY,
    AWARENESS,
    DISCIPLINE
}

data class SystemDomainProgress(
    val domain: SystemDevelopmentDomain,
    val level: Int = 1,
    val experience: Int = 0,
    val completedTasks: Int = 0,
    val totalTasks: Int = 0,
    val lastActivityAt: Long = 0L
) {
    val completionRate: Float
        get() = if (totalTasks <= 0) 0f
        else (completedTasks.toFloat() / totalTasks).coerceIn(0f, 1f)
}

data class SystemProgressSnapshot(
    val userId: String,
    val domains: List<SystemDomainProgress> = emptyList(),
    val totalExperience: Int = 0,
    val overallLevel: Int = 1,
    val updatedAt: Long = 0L
)

data class SystemExperienceRecord(
    val recordId: String,
    val userId: String,
    val domain: SystemDevelopmentDomain,
    val amount: Int,
    val reason: String,
    val createdAt: Long
)

data class SystemDailyProgress(
    val date: String,
    val completedTasks: Int = 0,
    val earnedExperience: Int = 0,
    val activeDomains: List<SystemDevelopmentDomain> = emptyList()
)
