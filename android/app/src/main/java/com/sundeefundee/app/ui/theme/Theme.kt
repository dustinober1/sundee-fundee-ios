package com.sundeefundee.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Art Deco Light color scheme — cream background, navy primary, orange accent
private val LightColorScheme = lightColorScheme(
    primary = Navy,
    onPrimary = TextCream,
    primaryContainer = CardBackground,
    onPrimaryContainer = TextPrimary,
    secondary = Gold,
    onSecondary = TextPrimary,
    secondaryContainer = GoldLight,
    tertiary = Orange,
    onTertiary = TextWhite,
    background = Cream,
    onBackground = TextPrimary,
    surface = CardBackground,
    onSurface = TextPrimary,
    surfaceVariant = Cream,
    onSurfaceVariant = TextSecondary,
    error = Error,
    onError = TextWhite,
    outline = Gold,
    outlineVariant = GoldLight
)

// Dark scheme — navy background, cream text (for potential future dark mode)
private val DarkColorScheme = darkColorScheme(
    primary = Cream,
    onPrimary = Navy,
    primaryContainer = Navy,
    onPrimaryContainer = TextCream,
    secondary = Gold,
    onSecondary = Navy,
    secondaryContainer = GoldDark,
    tertiary = Orange,
    onTertiary = TextWhite,
    background = Navy,
    onBackground = TextCream,
    surface = Navy,
    onSurface = TextCream,
    surfaceVariant = Color(0xFF1A2850),
    onSurfaceVariant = TextCream,
    error = Error,
    onError = TextWhite,
    outline = Gold,
    outlineVariant = GoldDark
)

@Composable
fun SundeeFundeeTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = ArtDecoTypography,
        shapes = ArtDecoShapes,
        content = content
    )
}

/**
 * Provides direct access to theme colors and typography from @Composable functions.
 * Usage: `SundeeFundeeTheme.colors.cream` or `SundeeFundeeTheme.typography.bodyLarge`
 */
object SundeeFundeeTheme {
    /** Access the current color scheme within a @Composable context. */
    val colors: SundeeFundeeColors
        @Composable get() = SundeeFundeeColors(
            cream = Cream,
            navy = Navy,
            orange = Orange,
            gold = Gold,
            goldLight = GoldLight,
            success = Success,
            warning = Warning,
            error = Error,
            textPrimary = TextPrimary,
            textSecondary = TextSecondary,
            textCream = TextCream,
            textWhite = TextWhite,
            cardBackground = CardBackground,
        )

    /** Access the current typography within a @Composable context. */
    val typography: androidx.compose.material3.Typography
        @Composable get() = MaterialTheme.typography
}

/** Flat color access object for convenient usage in screens. */
data class SundeeFundeeColors(
    val cream: Color,
    val navy: Color,
    val orange: Color,
    val gold: Color,
    val goldLight: Color,
    val success: Color,
    val warning: Color,
    val error: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val textCream: Color,
    val textWhite: Color,
    val cardBackground: Color,
)
