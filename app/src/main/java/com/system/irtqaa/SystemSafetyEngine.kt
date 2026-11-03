
package com.system.irtqaa

object SystemSafetyEngine {

    fun submitReport(
        reports: List<SystemSafetyReport>,
        reporterId: String,
        reportedPlayerId: String,
        reportType: SafetyReportType,
        description: String,
        settings: SystemSafetySettings
    ): List<SystemSafetyReport> {

        if (!settings.allowPlayerReports) return reports

        if (
            reporterId.isBlank() ||
            reportedPlayerId.isBlank() ||
            reporterId == reportedPlayerId ||
            description.isBlank()
        ) {
            return reports
        }

        val duplicate = reports.any {
            it.reporterId == reporterId &&
            it.reportedPlayerId == reportedPlayerId &&
            it.status == SafetyReportStatus.PENDING
        }

        if (duplicate) return reports

        val report = SystemSafetyReport(
            reportId = "REPORT_${System.currentTimeMillis()}_${reports.size}",
            reporterId = reporterId,
            reportedPlayerId = reportedPlayerId,
            reportType = reportType,
            description = description.trim()
        )

        return reports + report
    }

    fun updateReportStatus(
        reports: List<SystemSafetyReport>,
        reportId: String,
        newStatus: SafetyReportStatus
    ): List<SystemSafetyReport> {

        return reports.map { report ->
            if (report.reportId == reportId) {
                report.copy(status = newStatus)
            } else {
                report
            }
        }
    }

    fun getPlayerReports(
        reports: List<SystemSafetyReport>,
        playerId: String
    ): List<SystemSafetyReport> {

        return reports.filter {
            it.reportedPlayerId == playerId
        }
    }

    fun getPendingReports(
        reports: List<SystemSafetyReport>
    ): List<SystemSafetyReport> {

        return reports.filter {
            it.status == SafetyReportStatus.PENDING
        }
    }

    fun issueAction(
        actions: List<SystemSafetyAction>,
        actionId: String,
        playerId: String,
        actionType: SafetyActionType,
        reason: String,
        moderatorId: String,
        durationMillis: Long? = null
    ): List<SystemSafetyAction> {

        if (
            actionId.isBlank() ||
            playerId.isBlank() ||
            moderatorId.isBlank() ||
            reason.isBlank()
        ) {
            return actions
        }

        if (actions.any { it.actionId == actionId }) {
            return actions
        }

        val expiry = durationMillis?.let {
            if (it > 0) System.currentTimeMillis() + it
            else null
        }

        val action = SystemSafetyAction(
            actionId = actionId,
            playerId = playerId,
            actionType = actionType,
            reason = reason.trim(),
            moderatorId = moderatorId,
            expiresAt = expiry
        )

        return actions + action
    }

    fun getPlayerActions(
        actions: List<SystemSafetyAction>,
        playerId: String
    ): List<SystemSafetyAction> {

        return actions.filter {
            it.playerId == playerId
        }
    }

    fun isSuspended(
        actions: List<SystemSafetyAction>,
        playerId: String
    ): Boolean {

        val now = System.currentTimeMillis()

        return actions.any {
            it.playerId == playerId &&
            it.actionType == SafetyActionType.TEMPORARY_SUSPENSION &&
            (it.expiresAt == null || it.expiresAt > now)
        }
    }

    fun isPermanentlyBanned(
        actions: List<SystemSafetyAction>,
        playerId: String
    ): Boolean {

        return actions.any {
            it.playerId == playerId &&
            it.actionType == SafetyActionType.PERMANENT_BAN
        }
    }
}
