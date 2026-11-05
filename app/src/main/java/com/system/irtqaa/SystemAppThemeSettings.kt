package com.system.irtqaa

import android.content.Context

data class SystemAppThemePalette(
    val id: String,
    val name: String,
    val description: String,
    val primary: Long,
    val secondary: Long,
    val background: Long,
    val surface: Long,
    val accent: Long
)

object SystemAppThemeCatalog {

    val modern = SystemAppThemePalette(
        id = "modern",
        name = "العالم الحديث",
        description = "هوية مستقبلية بالأزرق السماوي",
        primary = 0xFF42D9E8L,
        secondary = 0xFF4388B8L,
        background = 0xFF071B2BL,
        surface = 0xFF102B3CL,
        accent = 0xFFFFC857L
    )

    val historical = SystemAppThemePalette(
        id = "historical",
        name = "عالم التاريخ والأساطير",
        description = "ألوان الحضارات القديمة والذهب",
        primary = 0xFFE6B65CL,
        secondary = 0xFFB96E3EL,
        background = 0xFF28170FL,
        surface = 0xFF42291CL,
        accent = 0xFFFFD98AL
    )

    val fantasy = SystemAppThemePalette(
        id = "fantasy",
        name = "العالم الخيالي",
        description = "ألوان السحر والطاقة البنفسجية",
        primary = 0xFFB69BFFL,
        secondary = 0xFF5B72D6L,
        background = 0xFF17132FL,
        surface = 0xFF29234BL,
        accent = 0xFF80D8FFL
    )

    val greedIsland = SystemAppThemePalette(
        id = "greed",
        name = "جزيرة الطمع",
        description = "ألوان الجزيرة الزمردية الغامضة",
        primary = 0xFF65E6A6L,
        secondary = 0xFF36AFC0L,
        background = 0xFF08251FL,
        surface = 0xFF123C35L,
        accent = 0xFFFFD166L
    )

    val all = listOf(
        modern,
        historical,
        fantasy,
        greedIsland
    )

    fun getById(id: String): SystemAppThemePalette {
        return all.firstOrNull { it.id == id } ?: modern
    }
}

object SystemAppThemeSettings {

    private const val PREFS_NAME =
        "system_app_theme_settings"

    private const val KEY_SELECTED_THEME =
        "selected_theme_id"

    fun getSelectedTheme(
        context: Context
    ): SystemAppThemePalette {

        val preferences = context.applicationContext
            .getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )

        val selectedId = preferences.getString(
            KEY_SELECTED_THEME,
            SystemAppThemeCatalog.modern.id
        ) ?: SystemAppThemeCatalog.modern.id

        return SystemAppThemeCatalog.getById(selectedId)
    }

    fun saveSelectedTheme(
        context: Context,
        themeId: String
    ): Boolean {

        val theme = SystemAppThemeCatalog.all
            .firstOrNull { it.id == themeId }
            ?: return false

        return context.applicationContext
            .getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )
            .edit()
            .putString(
                KEY_SELECTED_THEME,
                theme.id
            )
            .commit()
    }

    fun resetToDefault(
        context: Context
    ): Boolean {
        return saveSelectedTheme(
            context,
            SystemAppThemeCatalog.modern.id
        )
    }
}
