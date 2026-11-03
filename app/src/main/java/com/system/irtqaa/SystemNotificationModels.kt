
package com.system.irtqaa

enum class SystemNotificationType {
    TASK_REMINDER,
    TASK_OVERDUE,
    DAILY_REMINDER,
    LEVEL_UP,
    ACHIEVEMENT,
    VOICE_INVITATION,
    FRIEND_REQUEST,
    SYSTEM_MESSAGE
}

enum class SystemNotificationPriority {
    LOW,
    NORMAL,
    HIGH
}

data class SystemNotification(
    val notificationId: String,
    val userId: String,
    val title: String,
    val message: String,
    val type: SystemNotificationType,
    val priority: SystemNotificationPriority =
        SystemNotificationPriority.NORMAL,
    val createdAt: Long = System.currentTimeMillis(),
    val scheduledAt: Long? = null,
    val isRead: Boolean = false,
    val relatedTaskId: String? = null
)

data class SystemReminderSettings(
    val notificationsEnabled: Boolean = true,
    val soundEnabled: Boolean = true,
    val vibrationEnabled: Boolean = true,
    val taskRemindersEnabled: Boolean = true,
    val overdueRemindersEnabled: Boolean = true,
    val voiceAlertsEnabled: Boolean = true,
    val quietHoursEnabled: Boolean = false,
    val quietHoursStart: String = "22:00",
    val quietHoursEnd: String = "07:00"
)

data class SystemTaskReminder(
    val reminderId: String,
    val userId: String,
    val taskId: String,
    val reminderTime: Long,
    val repeatDaily: Boolean = false,
    val isEnabled: Boolean = true,
    val soundName: String? = null
)
