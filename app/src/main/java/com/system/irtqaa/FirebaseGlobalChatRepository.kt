package com.system.irtqaa

import com.google.firebase.functions.FirebaseFunctions

/**
 * ربط الدردشة العالمية مع Firebase Cloud Functions
 */
class FirebaseGlobalChatRepository {

    private val functions: FirebaseFunctions =
        FirebaseFunctions.getInstance()

    /**
     * إرسال رسالة إلى الدردشة العالمية.
     * الرسالة تُرسل للمراجعة قبل ظهورها للجميع.
     */
    fun submitGlobalMessage(
        text: String,
        callback: (Result<String>) -> Unit
    ) {
        val cleanText = text.trim()

        if (cleanText.isEmpty()) {
            callback(
                Result.failure(
                    IllegalArgumentException(
                        "اكتب رسالة قبل الإرسال."
                    )
                )
            )
            return
        }

        if (cleanText.length > 1000) {
            callback(
                Result.failure(
                    IllegalArgumentException(
                        "الرسالة يجب ألا تتجاوز 1000 حرف."
                    )
                )
            )
            return
        }

        functions
            .getHttpsCallable("submitGlobalMessage")
            .call(
                mapOf(
                    "text" to cleanText
                )
            )
            .addOnSuccessListener { result ->

                val data = result.data as? Map<*, *>
                val messageId =
                    data?.get("messageId") as? String

                if (messageId.isNullOrBlank()) {
                    callback(
                        Result.failure(
                            Exception(
                                "تم الاتصال بالخادم لكن لم يصل معرّف الرسالة."
                            )
                        )
                    )
                    return@addOnSuccessListener
                }

                callback(
                    Result.success(messageId)
                )
            }
            .addOnFailureListener { error ->
                callback(
                    Result.failure(error)
                )
            }
    }
}
