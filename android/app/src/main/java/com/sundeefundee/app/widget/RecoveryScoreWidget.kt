package com.sundeefundee.app.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

class RecoveryScoreWidget : GlanceAppWidget() {
    // TODO: Implement recovery score widget (Phase 8)
}

class RecoveryScoreWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = RecoveryScoreWidget()
}
