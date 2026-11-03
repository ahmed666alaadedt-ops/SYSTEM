
package com.system.irtqaa

object SystemNotificationEngine {

    fun addNotification(
        notifications: List<SystemNotification>,
        notification: SystemNotification,
        settings: SystemReminderSettings
    ): List<SystemNotification> {

        if (!settings.notificationsEnabled) return notifications

        if (
            notification.notificationId.isBlank() ||
            notification.userId.isBlank() ||
            notification.title.isBlank() ||
            notification.message.isBlank()
        ) {
            return notifications
        }

        if (notifications.any {
                it.notificationId == notification.notificationId
            }
        ) {
            return notifications
        }

        return notifications + notification
    }

    fun getUserNotifications(
        notifications: List<SystemNotification>,
        userId: String
    ): List<SystemNotification> {

        return notifications
            .filter { it.userId == userId }
            .sortedByDescending { it.createdAt }
    }

    fun getUnreadNotifications(
        notifications: List<SystemNotification>,
        userId: String
    ): List<SystemNotification> {

        return getUserNotifications(notifications, userId)
            .filter { !it.isRead }
    }

    fun markAsRead(
        notifications: List<SystemNotification>,
        notificationId: String,
        userId: String
    ): List<SystemNotification> {

        return notifications.map { notification ->
            if (
                notification.notificationId == notificationId &&
                notification.userId == userId
            ) {
                notification.copy(isRead = true)
            } else {
                notification
            }
        }
    }

    fun markAllAsRead(
        notifications: List<SystemNotification>,
        userId: String
    ): List<SystemNotification> {

        return notifications.map { notification ->
            if (notification.userId == userId) {
                notification.copy(isRead = true)
            } else {
                notification
            }
        }
    }

    fun removeNotification(
        notifications: List<SystemNotification>,
        notificationId: String,
        userId: String
    ): List<SystemNotification> {

        return notifications.filterNot {
            it.notificationId == notificationId &&
            it.userId == userId
        }
    }

    fun addReminder(
        reminders: List<SystemTaskReminder>,
        reminder: SystemTaskReminder
    ): List<SystemTaskReminder> {

        if (
            reminder.reminderId.isBlank() ||
            reminder.userId.isBlank() ||
            reminder.taskId.isBlank() ||
            reminder.reminderTime <= 0L
        ) {
            return reminders
        }

        if (reminders.any {
                it.reminderId == reminder.reminderId
            }
        ) {
            return reminders
        }

        return reminders + reminder
    }

    fun getDueReminders(
        reminders: List<SystemTaskReminder>,
        currentTime: Long,
        userId: String
    ): List<SystemTaskReminder> {

        return reminders.filter {
            it.userId == userId &&
            it.isEnabled &&
            it.reminderTime <= currentTime
        }
    }

    fun updateReminder(
        reminders: List<SystemTaskReminder>,
        reminderId: String,
        enabled: Boolean
    ): List<SystemTaskReminder> {

        return reminders.map { reminder ->
            if (reminder.reminderId == reminderId) {
                reminder.copy(isEnabled = enabled)
            } else {
                reminder
            }
        }
    }

    fun removeReminder(
        reminders: List<SystemTaskReminder>,
        reminderId: String,
        userId: String
    ): List<SystemTaskReminder> {

        return reminders.filterNot {
            it.reminderId == reminderId &&
            it.userId == userId
        }
    }
}
