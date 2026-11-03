package com.system.irtqaa

data class SystemNutritionGuidance(
    val goal: SystemFitnessGoal,
    val title: String,
    val recommendations: List<String>,
    val dailyHabits: List<String>,
    val safetyReminder: String
)

class SystemFitnessNutritionGuidance {

    fun buildGuidance(
        goal: SystemFitnessGoal
    ): SystemNutritionGuidance {

        val recommendations = when (goal) {

            SystemFitnessGoal.WEIGHT_LOSS -> listOf(
                "تناول وجبات متوازنة وبكميات مناسبة.",
                "أكثر من الخضروات والأطعمة الغنية بالألياف.",
                "قلل المشروبات السكرية والحلويات تدريجياً.",
                "تجنب التجويع والحرمان من الطعام."
            )

            SystemFitnessGoal.MUSCLE_GAIN -> listOf(
                "احرص على تناول مصدر بروتين متنوع مع وجباتك.",
                "تناول الكربوهيدرات لتوفير الطاقة للتمارين.",
                "نوّع مصادر الدهون الصحية.",
                "اجمع بين التغذية المناسبة وتمارين المقاومة والراحة."
            )

            SystemFitnessGoal.IMPROVE_ENDURANCE -> listOf(
                "تناول وجبات متوازنة توفر الطاقة.",
                "اهتم بالكربوهيدرات المناسبة قبل النشاط.",
                "تناول وجبة متوازنة بعد التمرين.",
                "عوّض السوائل التي تفقدها أثناء النشاط."
            )

            else -> listOf(
                "نوّع طعامك بين الخضروات والفواكه والبروتين والحبوب.",
                "اختر مصادر غذائية متنوعة ومتوازنة.",
                "قلل الأطعمة شديدة المعالجة قدر الإمكان.",
                "حافظ على مواعيد وجبات مناسبة لروتينك."
            )
        }

        val dailyHabits = listOf(
            "اشرب الماء بانتظام حسب حاجتك.",
            "تناول الطعام بوعي وتجنب الاستعجال.",
            "حافظ على نوم منتظم.",
            "اجعل اختياراتك الغذائية قابلة للاستمرار."
        )

        return SystemNutritionGuidance(
            goal = goal,
            title = "الإرشادات الغذائية اليومية",
            recommendations = recommendations,
            dailyHabits = dailyHabits,
            safetyReminder = "هذه إرشادات عامة وليست حمية طبية. إذا كانت لديك حالة صحية أو احتياجات غذائية خاصة، استشر اختصاصي تغذية."
        )
    }
}
