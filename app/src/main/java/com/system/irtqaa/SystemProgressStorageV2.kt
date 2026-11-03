
package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

class SystemProgressStorageV2(context: Context) {

    private val preferences = context.applicationContext
        .getSharedPreferences("system_progress_storage", Context.MODE_PRIVATE)

    fun saveProgress(snapshot: SystemProgressSnapshot): Boolean {
        return try {
            val domainsArray = JSONArray()

            snapshot.domains.forEach { domain ->
                domainsArray.put(JSONObject().apply {
                    put("domain", domain.domain.name)
                    put("level", domain.level)
                    put("experience", domain.experience)
                    put("completedTasks", domain.completedTasks)
                    put("totalTasks", domain.totalTasks)
                    put("lastActivityAt", domain.lastActivityAt)
                })
            }

            val json = JSONObject().apply {
                put("userId", snapshot.userId)
                put("domains", domainsArray)
                put("totalExperience", snapshot.totalExperience)
                put("overallLevel", snapshot.overallLevel)
                put("updatedAt", snapshot.updatedAt)
            }

            preferences.edit()
                .putString(progressKey(snapshot.userId), json.toString())
                .commit()
        } catch (e: Exception) {
            false
        }
    }

    fun loadProgress(userId: String): SystemProgressSnapshot? {
        return try {
            val raw = preferences.getString(progressKey(userId), null)
                ?: return null

            val json = JSONObject(raw)
            val array = json.optJSONArray("domains") ?: JSONArray()
            val domains = mutableListOf<SystemDomainProgress>()

            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)

                val domain = runCatching {
                    SystemDevelopmentDomain.valueOf(item.getString("domain"))
                }.getOrNull() ?: continue

                domains.add(
                    SystemDomainProgress(
                        domain = domain,
                        level = item.optInt("level", 1),
                        experience = item.optInt("experience", 0),
                        completedTasks = item.optInt("completedTasks", 0),
                        totalTasks = item.optInt("totalTasks", 0),
                        lastActivityAt = item.optLong("lastActivityAt", 0L)
                    )
                )
            }

            SystemProgressSnapshot(
                userId = json.optString("userId", userId),
                domains = domains,
                totalExperience = json.optInt("totalExperience", 0),
                overallLevel = json.optInt("overallLevel", 1),
                updatedAt = json.optLong("updatedAt", 0L)
            )
        } catch (e: Exception) {
            null
        }
    }

    fun saveExperienceHistory(
        userId: String,
        records: List<SystemExperienceRecord>
    ): Boolean {
        return try {
            val array = JSONArray()

            records.filter { it.userId == userId }.forEach { record ->
                array.put(JSONObject().apply {
                    put("recordId", record.recordId)
                    put("userId", record.userId)
                    put("domain", record.domain.name)
                    put("amount", record.amount)
                    put("reason", record.reason)
                    put("createdAt", record.createdAt)
                })
            }

            preferences.edit()
                .putString(historyKey(userId), array.toString())
                .commit()
        } catch (e: Exception) {
            false
        }
    }

    fun loadExperienceHistory(userId: String): List<SystemExperienceRecord> {
        return try {
            val raw = preferences.getString(historyKey(userId), null)
                ?: return emptyList()

            val array = JSONArray(raw)
            val records = mutableListOf<SystemExperienceRecord>()

            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)

                val domain = runCatching {
                    SystemDevelopmentDomain.valueOf(item.getString("domain"))
                }.getOrNull() ?: continue

                records.add(
                    SystemExperienceRecord(
                        recordId = item.optString("recordId"),
                        userId = item.optString("userId", userId),
                        domain = domain,
                        amount = item.optInt("amount", 0),
                        reason = item.optString("reason"),
                        createdAt = item.optLong("createdAt", 0L)
                    )
                )
            }

            records
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun saveDailyProgress(
        userId: String,
        progress: SystemDailyProgress
    ): Boolean {
        if (userId.isBlank() || progress.date.isBlank()) return false

        return try {
            val domainsArray = JSONArray()
            progress.activeDomains.forEach {
                domainsArray.put(it.name)
            }

            val json = JSONObject().apply {
                put("date", progress.date)
                put("completedTasks", progress.completedTasks)
                put("earnedExperience", progress.earnedExperience)
                put("activeDomains", domainsArray)
            }

            val datesKey = dailyDatesKey(userId)
            val dates = JSONArray(
                preferences.getString(datesKey, "[]") ?: "[]"
            )

            val knownDates = (0 until dates.length())
                .map { dates.getString(it) }
                .toMutableSet()

            knownDates.add(progress.date)

            val updatedDates = JSONArray()
            knownDates.forEach { updatedDates.put(it) }

            preferences.edit()
                .putString(dailyKey(userId, progress.date), json.toString())
                .putString(datesKey, updatedDates.toString())
                .commit()
        } catch (e: Exception) {
            false
        }
    }

    fun loadDailyProgress(
        userId: String,
        date: String
    ): SystemDailyProgress {
        if (userId.isBlank() || date.isBlank()) {
            return SystemDailyProgress(date)
        }

        return try {
            val raw = preferences.getString(dailyKey(userId, date), null)
                ?: return SystemDailyProgress(date)

            val json = JSONObject(raw)
            val array = json.optJSONArray("activeDomains") ?: JSONArray()
            val domains = mutableListOf<SystemDevelopmentDomain>()

            for (i in 0 until array.length()) {
                val domain = runCatching {
                    SystemDevelopmentDomain.valueOf(array.getString(i))
                }.getOrNull()

                if (domain != null) domains.add(domain)
            }

            SystemDailyProgress(
                date = json.optString("date", date),
                completedTasks = json.optInt("completedTasks", 0),
                earnedExperience = json.optInt("earnedExperience", 0),
                activeDomains = domains.distinct()
            )
        } catch (e: Exception) {
            SystemDailyProgress(date)
        }
    }

    fun deleteUserProgress(userId: String): Boolean {
        if (userId.isBlank()) return false

        return try {
            val datesKey = dailyDatesKey(userId)
            val dates = JSONArray(
                preferences.getString(datesKey, "[]") ?: "[]"
            )

            val editor = preferences.edit()
                .remove(progressKey(userId))
                .remove(historyKey(userId))
                .remove(datesKey)

            for (i in 0 until dates.length()) {
                editor.remove(dailyKey(userId, dates.getString(i)))
            }

            editor.commit()
        } catch (e: Exception) {
            false
        }
    }

    private fun progressKey(userId: String) = "progress_$userId"

    private fun historyKey(userId: String) = "history_$userId"

    private fun dailyKey(userId: String, date: String) =
        "daily_${userId}_$date"

    private fun dailyDatesKey(userId: String) =
        "daily_dates_$userId"
}
