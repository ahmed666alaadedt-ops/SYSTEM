package com.system.irtqaa

import java.time.LocalDate

enum class SystemFitnessPlanActivityType {
    WALKING,
    CARDIO,
    STRENGTH,
    MOBILITY,
    REST
}
data class SystemFitnessPlanActivity(
    val type: SystemFitnessPlanActivityType,
    val title: String,
    val description: String,
    val durationMinutes: Int,
    val sets: Int? = null,
    val repetitions: Int? = null
)

data class SystemFitnessPlanDay(
    val date: LocalDate,
    val dayNumber: Int,
    val title: String,
    val activities: List<SystemFitnessPlanActivity>,
    val isRestDay: Boolean
)

data class SystemFitnessWeeklyPlan(
    val userId: String,
    val goal: SystemFitnessGoal,
    val activityLevel: SystemFitnessActivityLevel,
    val days: List<SystemFitnessPlanDay>,
    val safetyReminder: String
)
class SystemFitnessPlanEngine {

    fun buildWeeklyPlan(
        profile: SystemFitnessProfile,
        startDate: LocalDate = LocalDate.now()
    ): SystemFitnessWeeklyPlan {

        val level = profile.activityLevel
        val goal = profile.goal

        val walkingMinutes = when (level) {
            SystemFitnessActivityLevel.BEGINNER -> 15
            SystemFitnessActivityLevel.LIGHT -> 25
            SystemFitnessActivityLevel.MODERATE -> 35
            SystemFitnessActivityLevel.ACTIVE -> 40
        }

        val strengthSets = when (level) {
            SystemFitnessActivityLevel.BEGINNER -> 2
            SystemFitnessActivityLevel.LIGHT -> 2
            SystemFitnessActivityLevel.MODERATE -> 3
            SystemFitnessActivityLevel.ACTIVE -> 3
        }

        val strengthDays = when (level) {
            SystemFitnessActivityLevel.BEGINNER -> setOf(2, 5)
            SystemFitnessActivityLevel.LIGHT -> setOf(2, 5)
            SystemFitnessActivityLevel.MODERATE -> setOf(2, 4, 6)
            SystemFitnessActivityLevel.ACTIVE -> setOf(2, 4, 6)
        }

        val restDays = when (level) {
            SystemFitnessActivityLevel.BEGINNER -> setOf(4, 7)
            SystemFitnessActivityLevel.LIGHT -> setOf(4, 7)
            SystemFitnessActivityLevel.MODERATE -> setOf(1, 7)
            SystemFitnessActivityLevel.ACTIVE -> setOf(1, 7)
        }

        val days = (1..7).map { dayNumber ->
            val date = startDate.plusDays((dayNumber - 1).toLong())

            val activities = when {
                dayNumber in restDays -> listOf(
                    SystemFitnessPlanActivity(
                        type = SystemFitnessPlanActivityType.REST,
                        title = "راحة واستشفاء",
                        description = "استرح، واشرب الماء، ويمكنك المشي الخفيف حسب راحتك",
                        durationMinutes = 0
                    )
                )

                dayNumber in strengthDays -> strengthActivities(
                    sets = strengthSets,
                    goal = goal
                )

                else -> cardioActivities(
                    minutes = walkingMinutes,
                    goal = goal
                )
            }

            SystemFitnessPlanDay(
                date = date,
                dayNumber = dayNumber,
                title = "اليوم $dayNumber",
                activities = activities,
                isRestDay = dayNumber in restDays
            )
        }

        return SystemFitnessWeeklyPlan(
            userId = profile.userId,
            goal = goal,
            activityLevel = level,
            days = days,
            safetyReminder = "ابدأ بالتدريج، وتوقف عند الألم أو الدوخة أو ضيق النفس غير المعتاد. استشر مختصاً إذا كانت لديك حالة صحية تؤثر على التمرين."
        )
    }
}
private fun strengthActivities(
    sets: Int,
    goal: SystemFitnessGoal
): List<SystemFitnessPlanActivity> {

    val repetitions = when (goal) {
        SystemFitnessGoal.MUSCLE_GAIN -> 10
        else -> 8
    }

    return listOf(
        SystemFitnessPlanActivity(
            type = SystemFitnessPlanActivityType.STRENGTH,
            title = "تمارين مقاومة للجسم",
            description = "سكوات بوزن الجسم، ضغط على الحائط أو سطح مرتفع، وجسر الحوض. خذ استراحة بين المجموعات.",
            durationMinutes = 20,
            sets = sets,
            repetitions = repetitions
        ),
        SystemFitnessPlanActivity(
            type = SystemFitnessPlanActivityType.MOBILITY,
            title = "إطالة ومرونة",
            description = "حركات لطيفة للكتفين والظهر والساقين دون إجبار المفاصل.",
            durationMinutes = 5
        )
    )
}

private fun cardioActivities(
    minutes: Int,
    goal: SystemFitnessGoal
): List<SystemFitnessPlanActivity> {

    val activity = when (goal) {
        SystemFitnessGoal.IMPROVE_ENDURANCE -> "مشي نشيط أو هرولة خفيفة حسب القدرة"
        SystemFitnessGoal.WEIGHT_LOSS -> "مشي منتظم بوتيرة مريحة"
        SystemFitnessGoal.MUSCLE_GAIN -> "مشي خفيف للمحافظة على النشاط"
        else -> "مشي منتظم حسب القدرة"
    }

    return listOf(
        SystemFitnessPlanActivity(
            type = SystemFitnessPlanActivityType.WALKING,
            title = activity,
            description = "ابدأ بوتيرة مريحة، ويمكن تقسيم المدة إلى فترات قصيرة.",
            durationMinutes = minutes
        ),
        SystemFitnessPlanActivity(
            type = SystemFitnessPlanActivityType.MOBILITY,
            title = "إحماء وتهدئة",
            description = "حركات خفيفة قبل المشي وبعده.",
            durationMinutes = 5
        )
    )
}
