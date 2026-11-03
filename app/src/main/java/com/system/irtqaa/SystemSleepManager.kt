package com.system.irtqaa

import android.content.Context
import java.time.LocalDate

class SystemSleepManager(context: Context) {

    private val storage = SystemSleepStorage(context)

    fun saveSleepRecord(
        userId: String,
        bedtime: java.time.LocalDateTime,
        wakeUpTime: java.time.LocalDateTime,
        quality: Int,
        notes: String = ""
    ): Boolean {

        val record = SystemSleepTracker.createRecord(
            bedtime,
            wakeUpTime,
            quality,
            notes
        ) ?: return false

        val records = storage.loadRecords(userId)
            .filterNot { it.date == record.date }

        return storage.saveRecords(
            userId,
            records + record
        )
    }

    fun getRecords(userId: String): List<SystemSleepRecord> {
        return SystemSleepHistory.getHistory(
            storage.loadRecords(userId)
        )
    }

    fun getAnalysis(userId: String): SystemSleepAnalysis {
        return SystemSleepAnalysisEngine.analyze(
            storage.loadRecords(userId)
        )
    }

    fun getWeeklyReport(userId: String): SystemSleepWeeklyReport {
        return SystemSleepWeeklyReportGenerator.generate(
            storage.loadRecords(userId)
        )
    }

    fun getSleepScore(userId: String): SystemSleepScore {
        return SystemSleepScoreCalculator.calculate(
            storage.loadRecords(userId)
        )
    }

    fun getRecovery(userId: String): SystemSleepRecoveryResult {
        return SystemSleepRecovery.calculate(
            storage.loadRecords(userId)
        )
    }

    fun getRecommendations(userId: String): List<String> {
        return SystemSleepRecommendation.generate(
            storage.loadRecords(userId)
        )
    }

    fun getRecordByDate(
        userId: String,
        date: LocalDate
    ): SystemSleepRecord? {
        return SystemSleepHistory.findByDate(
            storage.loadRecords(userId),
            date
        )
    }

    fun deleteAllRecords(userId: String): Boolean {
        return storage.clearRecords(userId)
    }
}
