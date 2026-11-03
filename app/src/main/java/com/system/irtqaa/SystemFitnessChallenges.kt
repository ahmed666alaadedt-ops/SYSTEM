package com.system.irtqaa

import java.time.LocalDate
import java.util.UUID

enum class SystemFitnessChallengeType {
    DAILY,
    WEEKLY
}

enum class SystemFitnessChallengeStatus {
    ACTIVE,
    COMPLETED,
    EXPIRED
}

data class SystemFitnessChallenge(
    val challengeId: String,
    val title: String,
    val description: String,
    val type: SystemFitnessChallengeType,
    val targetMinutes: Int,
    val rewardXP: Int,
    val startDate: String,
    val endDate: String,
    val status: SystemFitnessChallengeStatus
)

data class SystemFitnessChallengeProgress(
    val challengeId: String,
    val completedMinutes: Int,
    val targetMinutes: Int,
    val percentage: Int,
    val isCompleted: Boolean
)

class SystemFitnessChallenges {

    private val challenges =
        mutableMapOf<String, SystemFitnessChallenge>()

    fun createChallenge(
        title: String,
        description: String,
        type: SystemFitnessChallengeType,
        targetMinutes: Int,
        rewardXP: Int,
        startDate: LocalDate = LocalDate.now(),
        endDate: LocalDate
    ): SystemFitnessChallenge {

        require(title.isNotBlank())
        require(targetMinutes in 1..10000)
        require(rewardXP in 0..10000)
        require(!endDate.isBefore(startDate))

        val challenge = SystemFitnessChallenge(
            challengeId = UUID.randomUUID().toString(),
            title = title.trim(),
            description = description.trim(),
            type = type,
            targetMinutes = targetMinutes,
            rewardXP = rewardXP,
            startDate = startDate.toString(),
            endDate = endDate.toString(),
            status = SystemFitnessChallengeStatus.ACTIVE
        )

        challenges[challenge.challengeId] = challenge

        return challenge
    }

    fun getChallenges(): List<SystemFitnessChallenge> {
        return challenges.values.toList()
    }

    fun getActiveChallenges(
        date: LocalDate = LocalDate.now()
    ): List<SystemFitnessChallenge> {

        return challenges.values.filter { challenge ->
            val start = LocalDate.parse(challenge.startDate)
            val end = LocalDate.parse(challenge.endDate)

            challenge.status == SystemFitnessChallengeStatus.ACTIVE &&
                !date.isBefore(start) &&
                !date.isAfter(end)
        }
    }

    fun calculateProgress(
        challengeId: String,
        activityLog: SystemFitnessActivityLog,
        date: LocalDate = LocalDate.now()
    ): SystemFitnessChallengeProgress? {

        val challenge = challenges[challengeId] ?: return null

        val start = LocalDate.parse(challenge.startDate)
        val end = LocalDate.parse(challenge.endDate)

        val completedMinutes = activityLog.getAllActivities()
            .filter { activity ->
                val activityDate = LocalDate.parse(activity.date)

                !activityDate.isBefore(start) &&
                    !activityDate.isAfter(end) &&
                    !activityDate.isAfter(date)
            }
            .sumOf { it.durationMinutes }

        val percentage = (
            completedMinutes.toDouble() /
                challenge.targetMinutes * 100
            ).toInt().coerceIn(0, 100)

        return SystemFitnessChallengeProgress(
            challengeId = challengeId,
            completedMinutes = completedMinutes,
            targetMinutes = challenge.targetMinutes,
            percentage = percentage,
            isCompleted = completedMinutes >= challenge.targetMinutes
        )
    }

    fun completeChallenge(
        challengeId: String,
        activityLog: SystemFitnessActivityLog,
        date: LocalDate = LocalDate.now()
    ): Boolean {

        val challenge = challenges[challengeId] ?: return false

        val progress = calculateProgress(
            challengeId,
            activityLog,
            date
        ) ?: return false

        if (!progress.isCompleted) return false

        challenges[challengeId] = challenge.copy(
            status = SystemFitnessChallengeStatus.COMPLETED
        )

        return true
    }

    fun expireChallenges(
        date: LocalDate = LocalDate.now()
    ) {
        challenges.entries.forEach { entry ->
            val challenge = entry.value
            val end = LocalDate.parse(challenge.endDate)

            if (
                challenge.status == SystemFitnessChallengeStatus.ACTIVE &&
                date.isAfter(end)
            ) {
                entry.setValue(
                    challenge.copy(
                        status = SystemFitnessChallengeStatus.EXPIRED
                    )
                )
            }
        }
    }

    fun deleteChallenge(challengeId: String): Boolean {
        return challenges.remove(challengeId) != null
    }

    fun clearChallenges() {
        challenges.clear()
    }
}
