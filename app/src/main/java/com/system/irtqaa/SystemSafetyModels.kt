
package com.system.irtqaa

enum class SafetyReportType {
    HARASSMENT,
    BULLYING,
    THREATS,
    INAPPROPRIATE_CONTENT,
    IMPERSONATION,
    SPAM,
    CHEATING,
    OTHER
}

enum class SafetyReportStatus {
    PENDING,
    UNDER_REVIEW,
    RESOLVED,
    REJECTED
}

enum class SafetyActionType {
    WARNING,
    TEMPORARY_MUTE,
    TEMPORARY_SUSPENSION,
    PERMANENT_BAN,
    NO_ACTION
}

data class SystemSafetyReport(
    val reportId: String,
    val reporterId: String,
    val reportedPlayerId: String,
    val reportType: SafetyReportType,
    val description: String,
    val evidenceReference: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val status: SafetyReportStatus =
        SafetyReportStatus.PENDING
)

data class SystemSafetyAction(
    val actionId: String,
    val playerId: String,
    val actionType: SafetyActionType,
    val reason: String,
    val moderatorId: String,
    val createdAt: Long = System.currentTimeMillis(),
    val expiresAt: Long? = null
)

data class SystemSafetySettings(
    val allowPlayerReports: Boolean = true,
    val allowBlocking: Boolean = true,
    val allowEvidenceAttachments: Boolean = true,
    val notifyUserAboutReportStatus: Boolean = true
)
