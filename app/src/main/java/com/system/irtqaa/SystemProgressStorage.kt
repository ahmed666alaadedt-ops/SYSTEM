
package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

class SystemProgressStorage(context: Context) {

    private val preferences = context.applicationContext
        .getSharedPreferences("system_progress_storage", Context.MODE_PRIVATE)

    fun saveProgress(snapshot: SystemProgressSnapshot): Boolean {
        return try {
            val domainsArray = JSONArray()

            snapshot.domains.forEach { domain ->
                domainsArray.put(
                    JSONObject().apply {
                        put("domain", domain.domain.name)
                        put("level", domain.level)
                        put("experience", domain.experience)
                        put("completedTasks", domain.completedTasks)
                        put("totalTasks", domain.totalTasks)
                        put("lastActivityAt", domain.lastActivityAt)
                    }
                )
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
        } catch (exception: Exception) {
            false
        }
    }

    fun loadProgress(userId: String): SystemProgressSnapshot? {
        return try {
            val raw = preferences.getString(progressKey(userId), null)
                ?: return null

            val json = JSONObject(raw)
            val domainsArray = json.optJSONArray("domains")
                ?: JSONArray()

            val domains = mutableListOf<SystemDomainProgress>()

            for (index in 0 until domainsArray.length()) {
                val item = domainsArray.getJSONObject(index)

                val domain = runCatching {
                    SystemDevelopmentDomain.valueOf(
                        item.getString("domain")
                    )
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
        } catch (exception: Exception) {
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
                array.put(
                    JSONObject().apply {
                        put("recordId", record.recordId)
                        put("userId", record.userId)
                        put("domain", record.domain.name)
                        put("amount", record.amount)
                        put("reason", record.reason)
                        put("createdAt", record.createdAt)
                    }
                )
            }

            preferences.edit()
                .putString(historyKey(userId), array.toString())
                .commit()
        } catch (exception: Exception) {
            false
        }
    }

    fun loadExperienceHistory(
        userId: String
    ): List<SystemExperienceRecord> {
        return try {
            val raw = preferences.getString(historyKey(userId), null)
                ?: return emptyList()

            val array = JSONArray(raw)
            val records = mutableListOf<SystemExperienceRecord>()

            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)

                val domain = runCatching {
                    SystemDevelopmentDomain.valueOf(
                        item.getString("domain")
                    )
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
        } catch (exception: Exception) {
            emptyList()
        }
    }

    fun saveDailyProgress(
        progress: SystemDailyProgress
    ): Boolean {
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

            preferences.edit()
                .putString(dailyKey(progress.date), json.toString())
                .commit()
        } catch (exception: Exception) {
            false
        }
    }

    fun loadDailyProgress(date: String): SystemDailyProgress {
        return try {
            val raw = preferences.getString(dailyKey(date), null)
                ?: return SystemDailyProgress(date)

            val json = JSONObject(raw)
            val array = json.optJSONArray("activeDomains")
                ?: JSONArray()

            val domains = mutableListOf<SystemDevelopmentDomain>()

            for (index in 0 until array.length()) {
                val domain = runCatching {
                    SystemDevelopmentDomain.valueOf(
                        array.getString(index)
                    )
                }.getOrNull()

                if (domain != null) {
                    domains.add(domain)
                }
            }

            SystemDailyProgress(
                date = json.optString("date", date),
                completedTasks = json.optInt("completedTasks", 0),
                earnedExperience = json.optInt("earnedExperience", 0),
                activeDomains = domains.distinct()
            )
        } catch (exception: Exception) {
            SystemDailyProgress(date)
        }
    }

    fun deleteUserProgress(userId: String): Boolean {
        return preferences.edit()
            .remove(progressKey(userId))
            .remove(historyKey(userId))
            .commit()
    }

    private fun progressKey(userId: String) =
        "progress_$userId"

    private fun historyKey(userId: String) =
        "history_$userId"

    private fun dailyKey(date: String) =
        "daily_$date"
}
