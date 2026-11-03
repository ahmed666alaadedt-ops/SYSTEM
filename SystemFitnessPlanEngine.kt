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
