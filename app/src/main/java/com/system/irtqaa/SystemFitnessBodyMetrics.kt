package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.util.UUID

data class SystemBodyMetric(
    val id: String,
    val date: String,
    val weightKg: Double?,
    val waistCm: Double?,
    val note: String
)

data class SystemBodyMetricsSummary(
    val measurementCount: Int,
    val firstWeightKg: Double?,
    val latestWeightKg: Double?,
    val weightChangeKg: Double?,
    val firstWaistCm: Double?,
    val latestWaistCm: Double?,
    val waistChangeCm: Double?
)

class SystemFitnessBodyMetrics(
    context: Context,
    private val userId: String
) {

    private val preferences = context.applicationContext
        .getSharedPreferences(
            "system_fitness_body_metrics",
            Context.MODE_PRIVATE
        )

    private val storageKey = "body_metrics_$userId"

    init {
        require(userId.isNotBlank()) {
            "User ID cannot be empty"
        }
    }

    @Synchronized
    fun addMeasurement(
        weightKg: Double? = null,
        waistCm: Double? = null,
        date: LocalDate = LocalDate.now(),
        note: String = ""
    ): SystemBodyMetric {

        require(
            weightKg == null ||
                (weightKg.isFinite() && weightKg in 1.0..500.0)
        ) {
            "Invalid weight"
        }

        require(
            waistCm == null ||
                (waistCm.isFinite() && waistCm in 10.0..300.0)
        ) {
            "Invalid waist measurement"
        }

        require(weightKg != null || waistCm != null) {
            "At least one measurement is required"
        }

        val record = SystemBodyMetric(
            id = UUID.randomUUID().toString(),
            date = date.toString(),
            weightKg = weightKg,
            waistCm = waistCm,
            note = note.trim().take(150)
        )

        val records = getMeasurements().toMutableList()
        records.add(record)

        saveMeasurements(records)

        return record
    }

    @Synchronized
    fun getMeasurements(): List<SystemBodyMetric> {

        val saved = preferences.getString(storageKey, null)
            ?: return emptyList()

        return try {
            val array = JSONArray(saved)
            val records = mutableListOf<SystemBodyMetric>()

            for (i in 0 until array.length()) {
                val item = array.optJSONObject(i) ?: continue

                try {
                    val weight = if (item.isNull("weightKg")) {
                        null
                    } else {
                        item.getDouble("weightKg")
                    }

                    val waist = if (item.isNull("waistCm")) {
                        null
                    } else {
                        item.getDouble("waistCm")
                    }

                    val record = SystemBodyMetric(
                        id = item.getString("id"),
                        date = item.getString("date"),
                        weightKg = weight,
                        waistCm = waist,
                        note = item.optString("note", "")
                    )

                    LocalDate.parse(record.date)

                    val validWeight = weight == null ||
                        (weight.isFinite() && weight in 1.0..500.0)

                    val validWaist = waist == null ||
                        (waist.isFinite() && waist in 10.0..300.0)

                    if (
                        validWeight &&
                        validWaist &&
                        (weight != null || waist != null)
                    ) {
                        records.add(record)
                    }

                } catch (exception: Exception) {
                    continue
                }
            }

            records.sortedWith(
                compareBy<SystemBodyMetric> { it.date }
                    .thenBy { it.id }
            )

        } catch (exception: Exception) {
            emptyList()
        }
    }

    fun getSummary(): SystemBodyMetricsSummary {

        val records = getMeasurements()

        val weightRecords = records.filter {
            it.weightKg != null
        }

        val waistRecords = records.filter {
            it.waistCm != null
        }

        val firstWeight = weightRecords.firstOrNull()?.weightKg
        val latestWeight = weightRecords.lastOrNull()?.weightKg

        val firstWaist = waistRecords.firstOrNull()?.waistCm
        val latestWaist = waistRecords.lastOrNull()?.waistCm

        return SystemBodyMetricsSummary(
            measurementCount = records.size,
            firstWeightKg = firstWeight,
            latestWeightKg = latestWeight,
            weightChangeKg = if (
                firstWeight != null && latestWeight != null
            ) {
                latestWeight - firstWeight
            } else {
                null
            },
            firstWaistCm = firstWaist,
            latestWaistCm = latestWaist,
            waistChangeCm = if (
                firstWaist != null && latestWaist != null
            ) {
                latestWaist - firstWaist
            } else {
                null
            }
        )
    }

    fun getMeasurementsForDate(
        date: LocalDate = LocalDate.now()
    ): List<SystemBodyMetric> {
        return getMeasurements().filter {
            it.date == date.toString()
        }
    }

    @Synchronized
    fun deleteMeasurement(id: String): Boolean {

        val records = getMeasurements().toMutableList()

        val removed = records.removeAll {
            it.id == id
        }

        if (removed) {
            saveMeasurements(records)
        }

        return removed
    }

    @Synchronized
    fun clearAllMeasurements() {
        preferences.edit()
            .remove(storageKey)
            .apply()
    }

    private fun saveMeasurements(
        records: List<SystemBodyMetric>
    ) {

        val array = JSONArray()

        records.forEach { record ->
            val item = JSONObject()

            item.put("id", record.id)
            item.put("date", record.date)

            if (record.weightKg == null) {
                item.put("weightKg", JSONObject.NULL)
            } else {
                item.put("weightKg", record.weightKg)
            }

            if (record.waistCm == null) {
                item.put("waistCm", JSONObject.NULL)
            } else {
                item.put("waistCm", record.waistCm)
            }

            item.put("note", record.note)

            array.put(item)
        }

        preferences.edit()
            .putString(storageKey, array.toString())
            .apply()
    }
}
