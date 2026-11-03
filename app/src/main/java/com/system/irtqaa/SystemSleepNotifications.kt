package com.system.irtqaa

object SystemSleepNotifications {

    fun bedtimeMessage(): String {
        return "حان وقت الراحة. استعد لنوم هادئ لاستعادة طاقتك."
    }

    fun wakeUpMessage(): String {
        return "صباح النشاط! يوم جديد وفرصة جديدة لتطوير مستواك."
    }

    fun sleepGoalAchievedMessage(): String {
        return "أحسنت! حققت هدف النوم اليوم. استمر بالتقدم."
    }

    fun sleepGoalMissedMessage(): String {
        return "لم تحقق هدف النوم اليوم. حاول تنظيم وقت راحتك."
    }

    fun getMessage(type: String): String {
        return when (type.uppercase()) {
            "BEDTIME" -> bedtimeMessage()
            "WAKE_UP" -> wakeUpMessage()
            "GOAL_ACHIEVED" -> sleepGoalAchievedMessage()
            "GOAL_MISSED" -> sleepGoalMissedMessage()
            else -> "لديك تنبيه جديد من نظام النوم SYSTEM."
        }
    }
}
