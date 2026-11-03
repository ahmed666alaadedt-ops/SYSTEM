package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalDateTime

class SystemSleepStorage(context: Context) {

    private val preferences = context.getSharedPreferences(
        "system_sleep_storage",
        Context.MODE_PRIVATE
    )

    fun saveRecords(
        userId: String,
        records: List<SystemSleepRecord>
    ): Boolean {

        if (userId.isBlank()) return false
        if (records.any { !it.isValid }) return false

        val array = JSONArray()

        records.forEach { record ->
            val item = JSONObject().apply {
                put("date", record.date.toString())
                put("bedtime", record.bedtime.toString())
                put("wakeUpTime", record.wakeUpTime.toString())
                put("quality", record.quality)
                put("notes", record.notes)
            }

            array.put(item)
        }

        return preferences.edit()
            .putString("sleep_$userId", array.toString())
            .commit()
    }

    fun loadRecords(
        userId: String
    ): List<SystemSleepRecord> {

        if (userId.isBlank()) return emptyList()

        val raw = preferences.getString(
            "sleep_$userId",
            null
        ) ?: return emptyList()

        return try {
            val array = JSONArray(raw)

            buildList {
                for (index in 0 until array.length()) {

                    val item = array.getJSONObject(index)

                    val record = SystemSleepRecord(
                        date = LocalDate.parse(
                            item.getString("date")
                        ),
                        bedtime = LocalDateTime.parse(
                            item.getString("bedtime")
                        ),
                        wakeUpTime = LocalDateTime.parse(
                            item.getString("wakeUpTime")
                        ),
                        quality = item.getInt("quality"),
                        notes = item.optString("notes", "")
                    )

                    if (record.isValid) {
                        add(record)
                    }
                }
            }

        } catch (_: Exception) {
            emptyList()
        }
    }

    fun clearRecords(userId: String): Boolean {

        if (userId.isBlank()) return false

        return preferences.edit()
            .remove("sleep_$userId")
            .commit()
    }
}
