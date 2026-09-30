import SundeeFundeeKit
import SwiftUI
import WidgetKit

@main
struct SundeeFundeeWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ReadinessWidget()
        CyclePhaseWidget()
        NextWorkoutWidget()
    }
}
