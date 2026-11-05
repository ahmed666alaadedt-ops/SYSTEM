package com.system.irtqaa

import android.content.Context

class FirebaseSystemProgressSync(context: Context) {

    private val storage = SystemProgressStorageV2(
        context.applicationContext
    )

    private val repository = FirebaseSystemProgressRepository()

    private val detailsSync = FirebaseSystemProgressDetailsSync(
        context.applicationContext
    )

    fun synchronize(
        userId: String,
        onComplete: (Boolean, Exception?) -> Unit
    ) {
        if (userId.isBlank()) {
            onComplete(
                false,
                IllegalArgumentException("Invalid user ID")
            )
            return
        }

        val localProgress = runCatching {
            storage.loadProgress(userId)
                ?.takeIf { it.userId == userId }
        }.getOrElse { error ->
            onComplete(false, error)
            return
        }

        repository.loadProgress(userId) { cloudProgress, loadError ->

            if (loadError != null) {
                onComplete(false, loadError)
                return@loadProgress
            }

            if (cloudProgress != null) {

                val shouldRestoreCloud =
                    localProgress == null ||
                    cloudProgress.updatedAt >= localProgress.updatedAt

                if (shouldRestoreCloud) {
                    val saved = storage.saveProgress(cloudProgress)

                    if (!saved) {
                        onComplete(
                            false,
                            IllegalStateException(
                                "Could not restore cloud progress"
                            )
                        )
                        return@loadProgress
                    }

                    synchronizeDetails(userId, onComplete)
                    return@loadProgress
                }

                repository.saveProgress(localProgress) {
                        success,
                        saveError ->

                    if (!success) {
                        onComplete(false, saveError)
                    } else {
                        synchronizeDetails(userId, onComplete)
                    }
                }

                return@loadProgress
            }

            if (localProgress != null) {
                repository.saveProgress(localProgress) {
                        success,
                        saveError ->

                    if (!success) {
                        onComplete(false, saveError)
                    } else {
                        synchronizeDetails(userId, onComplete)
                    }
                }

                return@loadProgress
            }

            // لا توجد بيانات تقدم محلية أو سحابية.
            // نسترجع السجلات التفصيلية دون إنشاء تقدم صفري.
            synchronizeDetails(userId, onComplete)
        }
    }

    private fun synchronizeDetails(
        userId: String,
        onComplete: (Boolean, Exception?) -> Unit
    ) {
        detailsSync.synchronize(
            userId = userId
        ) { success, error ->

            onComplete(success, error)
        }
    }
}
