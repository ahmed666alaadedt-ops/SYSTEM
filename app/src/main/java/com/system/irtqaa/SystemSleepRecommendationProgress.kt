
package com.system.irtqaa

data class SystemSleepRecommendationProgressItem(
    val recommendation: String,
    val isCompleted: Boolean = false
)

object SystemSleepRecommendationProgressEngine {

    fun create(
        recommendations: List<String>,
        previousProgress: List<SystemSleepRecommendationProgressItem> = emptyList()
    ): List<SystemSleepRecommendationProgressItem> {

        val completedRecommendations = previousProgress
            .filter { it.isCompleted }
            .map { it.recommendation }
            .toSet()

        return recommendations
            .filter { it.isNotBlank() }
            .distinct()
            .map { recommendation ->
                SystemSleepRecommendationProgressItem(
                    recommendation = recommendation,
                    isCompleted = recommendation in completedRecommendations
                )
            }
    }

    fun setCompleted(
        progress: List<SystemSleepRecommendationProgressItem>,
        recommendation: String,
        completed: Boolean
    ): List<SystemSleepRecommendationProgressItem> {

        return progress.map { item ->
            if (item.recommendation == recommendation) {
                item.copy(isCompleted = completed)
            } else {
                item
            }
        }
    }

    fun completedCount(
        progress: List<SystemSleepRecommendationProgressItem>
    ): Int {
        return progress.count { it.isCompleted }
    }

    fun remainingCount(
        progress: List<SystemSleepRecommendationProgressItem>
    ): Int {
        return progress.count { !it.isCompleted }
    }

    fun completionPercentage(
        progress: List<SystemSleepRecommendationProgressItem>
    ): Int {

        if (progress.isEmpty()) return 0

        return (
            completedCount(progress) * 100f / progress.size
        ).toInt()
    }
}
