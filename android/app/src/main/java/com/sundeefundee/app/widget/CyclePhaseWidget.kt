package com.sundeefundee.app.widget

import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

class CyclePhaseWidget : GlanceAppWidget() {
    // TODO: Implement cycle phase widget (Phase 8)
}

class CyclePhaseWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = CyclePhaseWidget()
}
