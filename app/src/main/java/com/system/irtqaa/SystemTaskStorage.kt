package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

class SystemTaskStorage(context: Context) {

    private val preferences = context.applicationContext
        .getSharedPreferences(
            "system_tasks_storage",
            Context.MODE_PRIVATE
        )

    private fun deletedKey(userId: String): String {
        return "${userId}_deleted_task_ids"
    }

    fun saveTasks(
        userId: String,
        tasks: List<SystemTaskDefinition>
    ) {
        require(userId.isNotBlank())

        val array = JSONArray()

        tasks.forEach { task ->
            val item = JSONObject().apply {
                put("taskId", task.taskId)
                put("title", task.title)
                put("description", task.description)
                put("domain", task.domain.name)
                put("experienceReward", task.experienceReward)
                put("priority", task.priority.name)
                put("repeat", task.repeat.name)
                put("status", task.status.name)
                put("createdAt", task.createdAt)

                put(
                    "dueAt",
                    task.dueAt ?: JSONObject.NULL
                )

                put(
                    "completedAt",
                    task.completedAt ?: JSONObject.NULL
                )
            }

            array.put(item)
        }

        preferences.edit()
            .putString(userId, array.toString())
            .apply()
    }

    fun loadTasks(
        userId: String
    ): List<SystemTaskDefinition> {

        val savedData = preferences.getString(
            userId,
            null
        ) ?: return emptyList()

        return try {
            val array = JSONArray(savedData)
            val result = mutableListOf<SystemTaskDefinition>()

            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)

                val task = SystemTaskDefinition(
                    taskId = item.getString("taskId"),
                    title = item.getString("title"),
                    description = item.optString("description", ""),
                    domain = SystemDevelopmentDomain.valueOf(
                        item.getString("domain")
                    ),
                    experienceReward = item.getInt("experienceReward"),
                    priority = SystemTaskPriority.valueOf(
                        item.getString("priority")
                    ),
                    repeat = SystemTaskRepeat.valueOf(
                        item.getString("repeat")
                    ),
                    status = SystemTaskStatus.valueOf(
                        item.getString("status")
                    ),
                    createdAt = item.getLong("createdAt"),
                    dueAt = if (
                        item.isNull("dueAt")
                    ) null else item.getLong("dueAt"),
                    completedAt = if (
                        item.isNull("completedAt")
                    ) null else item.getLong("completedAt")
                )

                result.add(task)
            }

            result
        } catch (exception: Exception) {
            emptyList()
        }
    }

    fun saveDeletedTaskIds(
        userId: String,
        taskIds: Set<String>
    ) {
        require(userId.isNotBlank())

        val array = JSONArray()

        taskIds.forEach { taskId ->
            array.put(taskId)
        }

        preferences.edit()
            .putString(deletedKey(userId), array.toString())
            .apply()
    }

    fun loadDeletedTaskIds(
        userId: String
    ): Set<String> {
        require(userId.isNotBlank())

        val savedData = preferences.getString(
            deletedKey(userId),
            null
        ) ?: return emptySet()

        return try {
            val array = JSONArray(savedData)
            buildSet {
                for (index in 0 until array.length()) {
                    val taskId = array.optString(index)
                    if (taskId.isNotBlank()) {
                        add(taskId)
                    }
                }
            }
        } catch (exception: Exception) {
            emptySet()
        }
    }

    fun addDeletedTaskId(
        userId: String,
        taskId: String
    ) {
        require(userId.isNotBlank())
        require(taskId.isNotBlank())

        val deletedIds = loadDeletedTaskIds(userId).toMutableSet()
        deletedIds.add(taskId)

        saveDeletedTaskIds(userId, deletedIds)
    }

    fun removeDeletedTaskId(
        userId: String,
        taskId: String
    ) {
        val deletedIds = loadDeletedTaskIds(userId).toMutableSet()
        deletedIds.remove(taskId)

        saveDeletedTaskIds(userId, deletedIds)
    }

    fun clearTasks(userId: String) {
        preferences.edit()
            .remove(userId)
            .apply()
    }
}
