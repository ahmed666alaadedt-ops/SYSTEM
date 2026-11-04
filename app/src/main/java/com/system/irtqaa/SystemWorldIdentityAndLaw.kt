package com.system.irtqaa

import java.util.UUID

enum class SystemWorldNpcRole {
    CIVILIAN,
    POLICE,
    GUARD,
    MERCHANT,
    DOCTOR,
    CRIMINAL,
    SOLDIER,
    EXPLORER,
    RULER
}

enum class SystemWorldNpcBehavior {
    IDLE,
    WANDERING,
    WORKING,
    PATROLLING,
    INVESTIGATING,
    CHASING,
    ARRESTING,
    ESCORTING,
    HIDING,
    TRADING,
    SLEEPING
}

enum class SystemWorldCrimeType {
    THEFT,
    ASSAULT,
    MURDER,
    TRESPASSING,
    FRAUD,
    PROPERTY_DAMAGE,
    SMUGGLING,
    OTHER
}

enum class SystemWorldCrimeSeverity {
    MINOR,
    MODERATE,
    SERIOUS,
    EXTREME
}

enum class SystemWorldWantedStatus {
    NOT_WANTED,
    SUSPECTED,
    WANTED,
    ARRESTED,
    IMPRISONED
}

data class SystemWorldCharacterAppearance(
    val gender: String = "UNSPECIFIED",
    val skinColor: String = "",
    val eyeColor: String = "",
    val hairColor: String = "",
    val hairstyle: String = "",
    val heightCm: Int = 175,
    val bodyType: String = "AVERAGE",
    val clothing: String = "",
    val accessories: List<String> = emptyList()
)

data class SystemWorldCharacterVoice(
    val voiceId: String = "default",
    val language: String = "ar",
    val pitch: Float = 1.0f,
    val speed: Float = 1.0f,
    val customVoiceEnabled: Boolean = false
)

data class SystemWorldCharacterProfile(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val appearance: SystemWorldCharacterAppearance =
        SystemWorldCharacterAppearance(),
    val voice: SystemWorldCharacterVoice =
        SystemWorldCharacterVoice(),
    val level: Int = 1,
    val experience: Long = 0
)

data class SystemWorldNpcAgent(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val role: SystemWorldNpcRole,
    val behavior: SystemWorldNpcBehavior =
        SystemWorldNpcBehavior.IDLE,
    val currentLocation: String = "",
    val isAlive: Boolean = true,
    val dialogueEnabled: Boolean = true,
    val intelligenceLevel: Int = 1
)

data class SystemWorldCrimeRecord(
    val id: String = UUID.randomUUID().toString(),
    val criminalId: String,
    val crimeType: SystemWorldCrimeType,
    val severity: SystemWorldCrimeSeverity,
    val location: String,
    val description: String = "",
    val timestamp: Long = System.currentTimeMillis(),
    val evidence: List<String> = emptyList(),
    val isResolved: Boolean = false
)

data class SystemWorldLawPolicy(
    val minorFine: Long = 100,
    val moderateFine: Long = 500,
    val seriousFine: Long = 1500,
    val extremeFine: Long = 5000,
    val minorPrisonMinutes: Int = 0,
    val moderatePrisonMinutes: Int = 30,
    val seriousPrisonMinutes: Int = 120,
    val extremePrisonMinutes: Int = 360
)

data class SystemWorldPenalty(
    val fine: Long,
    val prisonMinutes: Int,
    val wantedStatus: SystemWorldWantedStatus,
    val requiresInvestigation: Boolean
)

object SystemWorldLawEngine {

    fun calculatePenalty(
        severity: SystemWorldCrimeSeverity,
        policy: SystemWorldLawPolicy = SystemWorldLawPolicy()
    ): SystemWorldPenalty {

        return when (severity) {

            SystemWorldCrimeSeverity.MINOR ->
                SystemWorldPenalty(
                    fine = policy.minorFine,
                    prisonMinutes = policy.minorPrisonMinutes,
                    wantedStatus = SystemWorldWantedStatus.SUSPECTED,
                    requiresInvestigation = false
                )

            SystemWorldCrimeSeverity.MODERATE ->
                SystemWorldPenalty(
                    fine = policy.moderateFine,
                    prisonMinutes = policy.moderatePrisonMinutes,
                    wantedStatus = SystemWorldWantedStatus.WANTED,
                    requiresInvestigation = true
                )

            SystemWorldCrimeSeverity.SERIOUS ->
                SystemWorldPenalty(
                    fine = policy.seriousFine,
                    prisonMinutes = policy.seriousPrisonMinutes,
                    wantedStatus = SystemWorldWantedStatus.WANTED,
                    requiresInvestigation = true
                )

            SystemWorldCrimeSeverity.EXTREME ->
                SystemWorldPenalty(
                    fine = policy.extremeFine,
                    prisonMinutes = policy.extremePrisonMinutes,
                    wantedStatus = SystemWorldWantedStatus.WANTED,
                    requiresInvestigation = true
                )
        }
    }
}
