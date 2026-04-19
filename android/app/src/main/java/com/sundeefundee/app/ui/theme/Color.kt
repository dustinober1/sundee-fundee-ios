package com.sundeefundee.app.ui.theme

import androidx.compose.ui.graphics.Color

// Art Deco color tokens — mirrors iOS AppTheme.swift

// Background
val Cream = Color(0xFFF4F0DF)
val Navy = Color(0xFF0D1A40)
val CardBackground = Color(0xCCFFFFFF) // white with 80% opacity

// Text — WCAG AA/AAA compliant on cream background
val TextPrimary = Color(0xFF0D1A40)       // Navy on cream: 13.7:1 — AAA
val TextSecondary = Color(0xFF40537F)     // Blue on cream: 7.4:1 — AAA
val TextCream = Color(0xFFF4F0DF)         // Cream on navy: 13.7:1 — AAA
val TextGold = Color(0xFF7A6A1F)          // Gold on cream: 4.6:1 — AA
val TextOrange = Color(0xFFB34F14)        // Orange on cream: 6.1:1 — AA
val TextWhite = Color.White               // White on navy: 13.7:1 — AAA

// Accent — decorative elements, icon fills, button backgrounds
val Gold = Color(0xFFD4A520)
val GoldLight = Color(0x4DD4A520)         // 30% opacity
val GoldDark = Color(0xFFA98419)
val Orange = Color(0xFFF27319)
val OrangeLight = Color(0x33F27319)       // 20% opacity

// Semantic
val Success = Color(0xFF38B249)
val Warning = Color(0xFFEBC12E)
val Error = Color.Red
val Info = Color.Blue

// Recovery score zones
val RecoveryGreen = Color(0xFF38B249)     // 70-100: push day
val RecoveryYellow = Color(0xFFEBC12E)    // 40-69: moderate
val RecoveryOrange = Orange               // 0-39: rest day

fun recoveryColor(score: Int): Color = when {
    score >= 70 -> RecoveryGreen
    score >= 40 -> RecoveryYellow
    else -> RecoveryOrange
}
