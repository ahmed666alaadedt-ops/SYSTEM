package com.system.irtqaa

object SystemSleepRecommendation {

    fun generate(
        records: List<SystemSleepRecord>
    ): List<String> {

        val validRecords = records
            .filter { it.isValid }
            .sortedBy { it.date }
            .takeLast(7)

        if (validRecords.isEmpty()) {
            return listOf(
                "ابدأ بتسجيل نومك حتى يتعرف SYSTEM على نمط راحتك."
            )
        }

        val averageMinutes =
            validRecords.map { it.durationMinutes }.average()

        val averageQuality =
            validRecords.map { it.quality }.average()

        val recommendations = mutableListOf<String>()

        if (averageMinutes < 360) {
            recommendations.add(
                "حاول زيادة مدة نومك تدريجياً."
            )
        }

        if (averageQuality < 3.0) {
            recommendations.add(
                "حاول تهيئة غرفة هادئة ومريحة للنوم."
            )
        }

        if (validRecords.size < 5) {
            recommendations.add(
                "حافظ على تسجيل نومك بانتظام حتى تحصل على تحليل أدق."
            )
        }

        if (averageMinutes >= 420 && averageQuality >= 4.0) {
            recommendations.add(
                "أداء ممتاز! حافظ على نمط نومك المنتظم."
            )
        }

        if (recommendations.isEmpty()) {
            recommendations.add(
                "استمر على عادات نوم جيدة وراقب تطور مستواك."
            )
        }

        return recommendations
    }
}
