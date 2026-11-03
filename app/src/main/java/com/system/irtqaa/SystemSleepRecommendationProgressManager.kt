
package com.system.irtqaa

import android.content.Context

class SystemSleepRecommendationProgressManager(
    context: Context
) {

    private val storage =
        SystemSleepRecommendationProgressStorage(context)

    fun getProgress(
        recommendations: List<String>
    ): List<SystemSleepRecommendationProgressItem> {

        val savedProgress = storage.load()

        val updatedProgress =
            SystemSleepRecommendationProgressEngine.create(
                recommendations = recommendations,
                previousProgress = savedProgress
            )

        storage.save(updatedProgress)

        return updatedProgress
    }

    fun updateCompletion(
        recommendations: List<String>,
        recommendation: String,
        completed: Boolean
    ): List<SystemSleepRecommendationProgressItem> {

        val currentProgress = getProgress(recommendations)

        val updatedProgress =
            SystemSleepRecommendationProgressEngine.setCompleted(
                progress = currentProgress,
                recommendation = recommendation,
                completed = completed
            )

        storage.save(updatedProgress)

        return updatedProgress
    }

    fun getCompletedCount(
        recommendations: List<String>
    ): Int {
        return SystemSleepRecommendationProgressEngine.completedCount(
            getProgress(recommendations)
        )
    }

    fun getRemainingCount(
        recommendations: List<String>
    ): Int {
        return SystemSleepRecommendationProgressEngine.remainingCount(
            getProgress(recommendations)
        )
    }

    fun getCompletionPercentage(
        recommendations: List<String>
    ): Int {
        return SystemSleepRecommendationProgressEngine.completionPercentage(
            getProgress(recommendations)
        )
    }

    fun resetProgress() {
        storage.clear()
    }
}
