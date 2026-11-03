package com.system.irtqaa

import java.time.LocalDate

class SystemFitnessPlanManager(
    private val fitnessManager: SystemFitnessManager,
    private val planEngine: SystemFitnessPlanEngine =
        SystemFitnessPlanEngine()
) {

    fun buildWeeklyPlan(
        startDate: LocalDate = LocalDate.now()
    ): SystemFitnessWeeklyPlan? {

        val profile = fitnessManager.getProfile()
            ?: return null

        if (!profile.hasUserConsentToStore) {
            return null
        }

        return planEngine.buildWeeklyPlan(
            profile = profile,
            startDate = startDate
        )
    }

    fun hasFitnessProfile(): Boolean {
        return fitnessManager.getProfile() != null
    }
}
