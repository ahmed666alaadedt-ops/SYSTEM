package com.system.irtqaa

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.firestore.FirebaseFirestore

data class SystemFirebaseAccount(
    val userId: String,
    val displayName: String,
    val email: String,
    val avatarUrl: String
)

class FirebaseSystemAccountRepository {

    private val auth = FirebaseAuth.getInstance()
    private val firestore = FirebaseFirestore.getInstance()

    fun currentUser(): FirebaseUser? {
        return auth.currentUser
    }

    fun signOut() {
        auth.signOut()
    }

    /**
     * تسجيل حساب جديد وإنشاء ملف اللاعب في Firestore.
     */
    fun register(
        email: String,
        password: String,
        displayName: String,
        callback: (Result<SystemFirebaseAccount>) -> Unit
    ) {
        val cleanEmail = email.trim()
        val cleanName = displayName.trim()

        if (cleanEmail.isBlank() ||
            password.length < 6 ||
            cleanName.isBlank() ||
            cleanName.length > 40
        ) {
            callback(
                Result.failure(
                    IllegalArgumentException(
                        "تأكد من البريد وكلمة المرور والاسم. كلمة المرور 6 أحرف على الأقل."
                    )
                )
            )
            return
        }

        auth.createUserWithEmailAndPassword(
            cleanEmail,
            password
        ).addOnSuccessListener { result ->

            val user = result.user

            if (user == null) {
                callback(
                    Result.failure(
                        Exception("تعذر إنشاء الحساب.")
                    )
                )
                return@addOnSuccessListener
            }

            createPlayerProfile(
                user = user,
                displayName = cleanName,
                callback = callback
            )

        }.addOnFailureListener { error ->
            callback(Result.failure(error))
        }
    }

    /**
     * تسجيل الدخول واسترجاع ملف اللاعب.
     */
    fun signIn(
        email: String,
        password: String,
        callback: (Result<SystemFirebaseAccount>) -> Unit
    ) {
        val cleanEmail = email.trim()

        if (cleanEmail.isBlank() || password.isBlank()) {
            callback(
                Result.failure(
                    IllegalArgumentException(
                        "أدخل البريد الإلكتروني وكلمة المرور."
                    )
                )
            )
            return
        }

        auth.signInWithEmailAndPassword(
            cleanEmail,
            password
        ).addOnSuccessListener { result ->

            val user = result.user

            if (user == null) {
                callback(
                    Result.failure(
                        Exception("تعذر التحقق من الحساب.")
                    )
                )
                return@addOnSuccessListener
            }

            loadPlayerProfile(user, callback)

        }.addOnFailureListener { error ->
            callback(Result.failure(error))
        }
    }

    /**
     * تحميل ملف اللاعب الحالي.
     */
    private fun loadPlayerProfile(
        user: FirebaseUser,
        callback: (Result<SystemFirebaseAccount>) -> Unit
    ) {
        val uid = user.uid

        firestore.collection("players")
            .document(uid)
            .get()
            .addOnSuccessListener { document ->

                if (document.exists()) {

                    val account = SystemFirebaseAccount(
                        userId = uid,
                        displayName =
                            document.getString("displayName") ?: "لاعب",
                        email =
                            document.getString("email")
                                ?: user.email.orEmpty(),
                        avatarUrl =
                            document.getString("avatarUrl").orEmpty()
                    )

                    callback(Result.success(account))

                } else {

                    val fallbackName =
                        user.displayName
                            ?: user.email?.substringBefore("@")
                            ?: "لاعب"

                    createPlayerProfile(
                        user = user,
                        displayName = fallbackName.take(40),
                        callback = callback
                    )
                }

            }
            .addOnFailureListener { error ->
                callback(Result.failure(error))
            }
    }

    /**
     * إنشاء ملف اللاعب وفق قواعد Firestore الحالية.
     */
    private fun createPlayerProfile(
        user: FirebaseUser,
        displayName: String,
        callback: (Result<SystemFirebaseAccount>) -> Unit
    ) {
        val uid = user.uid
        val email = user.email.orEmpty()
        val avatarUrl = user.photoUrl?.toString().orEmpty()

        val playerData = hashMapOf(
            "userId" to uid,
            "displayName" to displayName,
            "email" to email,
            "avatarUrl" to avatarUrl,
            "createdAt" to System.currentTimeMillis()
        )

        firestore.collection("players")
            .document(uid)
            .set(playerData)
            .addOnSuccessListener {

                callback(
                    Result.success(
                        SystemFirebaseAccount(
                            userId = uid,
                            displayName = displayName,
                            email = email,
                            avatarUrl = avatarUrl
                        )
                    )
                )

            }
            .addOnFailureListener { error ->
                callback(Result.failure(error))
            }
    }
}
