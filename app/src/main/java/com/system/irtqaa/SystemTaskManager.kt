package com.system.irtqaa

import android.content.Context

class SystemTaskManager(
    context: Context,
    private val userId: String,
    progressEngine: SystemProgressEngine
) {
    private val storage = SystemTaskStorage(context)

    private val engine = SystemTaskEngine(progressEngine)

    init {
        require(userId.isNotBlank()) {
            "User ID cannot be blank"
        }

        storage.loadTasks(userId).forEach { task ->
            engine.addTask(userId, task)
        }
    }

    fun addTask(
        task: SystemTaskDefinition
    ): SystemTaskDefinition {
        val added = engine.addTask(userId, task)
        save()
        return added
    }

    fun getTasks(): List<SystemTaskDefinition> {
        return engine.getTasks(userId)
    }

    fun getTask(
        taskId: String
    ): SystemTaskDefinition? {
        return engine.getTask(userId, taskId)
    }

    fun completeTask(
        taskId: String
    ): SystemTaskDefinition? {
        val completed = engine.completeTask(
            userId,
            taskId
        )

        if (completed != null) {
            save()
        }

        return completed
    }

    fun updateTaskStatus(
        taskId: String,
        status: SystemTaskStatus
    ): SystemTaskDefinition? {
        val updated = engine.updateTaskStatus(
            userId,
            taskId,
            status
        )

        if (updated != null) {
            save()
        }

        return updated
    }

    fun getTasksByDomain(
        domain: SystemDevelopmentDomain
    ): List<SystemTaskDefinition> {
        return engine.getTasksByDomain(
            userId,
            domain
        )
    }

    fun getOverdueTasks(): List<SystemTaskDefinition> {
        return engine.getOverdueTasks(userId)
    }

    fun getCompletedTaskCount(): Int {
        return engine.getCompletedTaskCount(userId)
    }

    fun getPendingTaskCount(): Int {
        return engine.getPendingTaskCount(userId)
    }

    fun removeTask(taskId: String): Boolean {
        val removed = engine.removeTask(
            userId,
            taskId
        )

        if (removed) {
            save()
        }

        return removed
    }

    fun save() {
        storage.saveTasks(
            userId,
            engine.getTasks(userId)
        )
    }
}
