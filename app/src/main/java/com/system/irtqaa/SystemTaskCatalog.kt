
package com.system.irtqaa

import java.time.DayOfWeek
import java.time.LocalDate

enum class SystemFitnessGoal {
    GENERAL_HEALTH,
    WEIGHT_LOSS,
    MUSCLE_GAIN,
    IMPROVE_ENDURANCE
}

/**
 * Creates practical daily tasks for the five SYSTEM development domains.
 */
object SystemTaskCatalog {

    fun buildDailyTasks(
        date: LocalDate = LocalDate.now(),
        fitnessGoal: SystemFitnessGoal = SystemFitnessGoal.GENERAL_HEALTH
    ): List<SystemTaskDefinition> {
        val dayKey = date.toString()
        val tasks = mutableListOf<SystemTaskDefinition>()

        tasks += task(
            dayKey, "body_movement",
            movementTitle(fitnessGoal),
            movementDescription(fitnessGoal),
            SystemDevelopmentDomain.BODY, 15
        )

        tasks += task(
            dayKey, "body_nutrition",
            nutritionTitle(fitnessGoal),
            nutritionDescription(fitnessGoal),
            SystemDevelopmentDomain.BODY, 10
        )

        tasks += task(
            dayKey, "spirit_practice",
            "عبادة أو ممارسة روحية",
            "خصص وقتاً للصلاة أو قراءة القرآن أو الذكر أو الدعاء بحسب معتقدك والتزامك.",
            SystemDevelopmentDomain.SPIRIT, 10
        )

        tasks += task(
            dayKey, "mind_learning",
            "تعلم شيء جديد",
            "اقرأ أو تعلم مهارة لمدة 15 دقيقة، ثم دوّن معلومة واحدة استفدت منها.",
            SystemDevelopmentDomain.MIND, 10
        )

        tasks += task(
            dayKey, "awareness_reflection",
            "مراجعة النفس والتركيز",
            "خذ 5 دقائق بهدوء، لاحظ أفكارك ومشاعرك، واكتب هدفاً واحداً تريد التركيز عليه اليوم.",
            SystemDevelopmentDomain.AWARENESS, 10
        )

        tasks += task(
            dayKey, "discipline_planning",
            "تنظيم اليوم",
            "اكتب أهم ثلاث أولويات لليوم، وحدد وقتاً واقعياً لكل واحدة.",
            SystemDevelopmentDomain.DISCIPLINE, 10
        )

        if (date.dayOfWeek == DayOfWeek.SUNDAY) {
            tasks += task(
                dayKey, "weekly_check_in",
                "مراجعة التقدم الأسبوعية",
                "راجع نشاطك ونومك والتزامك. إذا كان هدفك تغيير الوزن، يمكنك تسجيل الوزن مرة أسبوعياً وفي ظروف متشابهة.",
                SystemDevelopmentDomain.BODY, 15,
                SystemTaskRepeat.WEEKLY
            )
        }

        return tasks
    }

    private fun movementTitle(goal: SystemFitnessGoal): String =
        when (goal) {
            SystemFitnessGoal.WEIGHT_LOSS -> "مشي لتحسين اللياقة ودعم خسارة الوزن"
            SystemFitnessGoal.MUSCLE_GAIN -> "تمرين مقاومة مناسب لمستواك"
            SystemFitnessGoal.IMPROVE_ENDURANCE -> "تمرين لتحسين التحمل"
            SystemFitnessGoal.GENERAL_HEALTH -> "حركة ونشاط يومي"
        }

    private fun movementDescription(goal: SystemFitnessGoal): String =
        when (goal) {
            SystemFitnessGoal.WEIGHT_LOSS ->
                "امشِ 20 دقيقة بوتيرة مريحة إلى متوسطة. ابدأ بـ10 دقائق إذا كنت مبتدئاً، وزد المدة تدريجياً. يمكن استبدال المشي بحركة منخفضة التأثير تناسب قدرتك."
            SystemFitnessGoal.MUSCLE_GAIN ->
                "نفّذ 15 إلى 20 دقيقة من تمارين المقاومة المناسبة لمستواك، مثل السكوات المعدّل وتمارين الدفع على الحائط. اترك وقتاً للتعافي وتوقف عند الألم."
            SystemFitnessGoal.IMPROVE_ENDURANCE ->
                "مارس المشي النشط أو ركوب الدراجة أو نشاطاً مناسباً لمدة 15 إلى 20 دقيقة، مع زيادة المدة تدريجياً حسب قدرتك."
            SystemFitnessGoal.GENERAL_HEALTH ->
                "مارس المشي أو حركة تحبها لمدة 20 دقيقة. إذا كنت قليل النشاط فابدأ بمدة أقصر وزدها تدريجياً."
        }

    private fun nutritionTitle(goal: SystemFitnessGoal): String =
        when (goal) {
            SystemFitnessGoal.WEIGHT_LOSS -> "اختيار وجبة متوازنة"
            SystemFitnessGoal.MUSCLE_GAIN -> "وجبة داعمة للتعافي والعضلات"
            SystemFitnessGoal.IMPROVE_ENDURANCE -> "وجبة متوازنة للطاقة"
            SystemFitnessGoal.GENERAL_HEALTH -> "تحسين اختيارك الغذائي"
        }

    private fun nutritionDescription(goal: SystemFitnessGoal): String =
        when (goal) {
            SystemFitnessGoal.WEIGHT_LOSS ->
                "اختر وجبة متوازنة تضم مصدراً للبروتين وخضاراً أو فاكهة، وانتبه لحجم الحصة. تجنب الحميات القاسية أو تجويع نفسك."
            SystemFitnessGoal.MUSCLE_GAIN ->
                "تناول وجبة متوازنة تحتوي على مصدر بروتين وكربوهيدرات وخضار، واهتم بوجباتك المنتظمة والتعافي."
            SystemFitnessGoal.IMPROVE_ENDURANCE ->
                "تناول وجبة متوازنة ومتنوعة، ولا تهمل الطعام والماء المناسبين لنشاطك."
            SystemFitnessGoal.GENERAL_HEALTH ->
                "أضف خضاراً أو فاكهة إلى إحدى وجباتك، واختر طعاماً متنوعاً ومتوازناً."
        }

    private fun task(
        dayKey: String,
        id: String,
        title: String,
        description: String,
        domain: SystemDevelopmentDomain,
        xp: Int,
        repeat: SystemTaskRepeat = SystemTaskRepeat.DAILY
    ): SystemTaskDefinition {
        return SystemTaskDefinition(
            taskId = "system_${dayKey}_${id}",
            title = title,
            description = description,
            domain = domain,
            experienceReward = xp,
            priority = SystemTaskPriority.NORMAL,
            repeat = repeat
        )
    }
}
