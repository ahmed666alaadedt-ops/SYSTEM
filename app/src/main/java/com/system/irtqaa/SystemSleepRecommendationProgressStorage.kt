
package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

class SystemSleepRecommendationProgressStorage(
    context: Context
) {

    private val preferences = context.applicationContext
        .getSharedPreferences(
            "system_sleep_recommendation_progress",
            Context.MODE_PRIVATE
        )

    fun save(
        progress: List<SystemSleepRecommendationProgressItem>
    ) {
        val jsonArray = JSONArray()

        progress.forEach { item ->
            val jsonObject = JSONObject().apply {
                put("recommendation", item.recommendation)
                put("isCompleted", item.isCompleted)
            }

            jsonArray.put(jsonObject)
        }

        preferences.edit()
            .putString(STORAGE_KEY, jsonArray.toString())
            .apply()
    }

    fun load(): List<SystemSleepRecommendationProgressItem> {
        val savedData = preferences.getString(STORAGE_KEY, null)
            ?: return emptyList()

        return try {
            val jsonArray = JSONArray(savedData)
            val progress = mutableListOf<SystemSleepRecommendationProgressItem>()

            for (index in 0 until jsonArray.length()) {
                val item = jsonArray.getJSONObject(index)

                progress.add(
                    SystemSleepRecommendationProgressItem(
                        recommendation = item.getString("recommendation"),
                        isCompleted = item.optBoolean("isCompleted", false)
                    )
                )
            }

            progress
        } catch (exception: Exception) {
            emptyList()
        }
    }

    fun clear() {
        preferences.edit()
            .remove(STORAGE_KEY)
            .apply()
    }

    companion object {
        private const val STORAGE_KEY = "saved_recommendations"
    }
}
