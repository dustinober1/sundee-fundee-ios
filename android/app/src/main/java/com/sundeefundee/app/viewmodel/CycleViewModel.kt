package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.data.factory.DataClientFactory
import com.sundeefundee.core.data.factory.HealthClientFactory
import com.sundeefundee.core.data.protocol.DataClient
import com.sundeefundee.core.data.protocol.HealthClient
import com.sundeefundee.core.domain.cycle.getPhaseRecommendation
import com.sundeefundee.core.model.CyclePhase
import com.sundeefundee.core.model.CyclePhaseInfo
import com.sundeefundee.core.model.CycleSettings
import com.sundeefundee.core.model.PeriodLogRecord
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.minus
import kotlinx.datetime.plus
import kotlinx.datetime.todayIn
import javax.inject.Inject

@HiltViewModel
class CycleViewModel @Inject constructor(
    private val dataClientFactory: DataClientFactory,
    private val healthClientFactory: HealthClientFactory
) : ViewModel() {

    private val client: DataClient get() = dataClientFactory.client
    private val healthClient: HealthClient get() = healthClientFactory.client

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage = _errorMessage.asStateFlow()

    private val _cyclePhase = MutableStateFlow<CyclePhase?>(null)
    val cyclePhase = _cyclePhase.asStateFlow()

    private val _cycleDay = MutableStateFlow<Int?>(null)
    val cycleDay = _cycleDay.asStateFlow()

    private val _phaseDescription = MutableStateFlow<String?>(null)
    val phaseDescription = _phaseDescription.asStateFlow()

    private val _periodLogs = MutableStateFlow<List<PeriodLogRecord>>(emptyList())
    val periodLogs = _periodLogs.asStateFlow()

    private val _cycleSettings = MutableStateFlow(CycleSettings())
    val cycleSettings = _cycleSettings.asStateFlow()

    private val _isSharkWeek = MutableStateFlow(false)
    val isSharkWeek = _isSharkWeek.asStateFlow()

    private val _calendarDays = MutableStateFlow<List<CalendarDay>>(emptyList())
    val calendarDays = _calendarDays.asStateFlow()

    private val _selectedDate = MutableStateFlow(Clock.System.todayIn(TimeZone.currentSystemDefault()))
    val selectedDate = _selectedDate.asStateFlow()

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _periodLogs.value = client.fetchAll("PeriodLogRecord")
                val settingsList: List<CycleSettings> = client.fetchAll("CycleSettings")
                _cycleSettings.value = settingsList.firstOrNull() ?: CycleSettings()

                computeCycleState()
                buildCalendarDays()
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
            _isLoading.value = false
        }
    }

    fun logPeriod(date: LocalDate) {
        viewModelScope.launch {
            val record = PeriodLogRecord(
                id = java.util.UUID.randomUUID().toString(),
                startDate = date.toString(),
                endDate = null
            )
            try {
                client.save(record, "PeriodLogRecord")
                loadData()
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }

    fun updateSettings(averageCycleLength: Int) {
        viewModelScope.launch {
            val settings = _cycleSettings.value.copy(averageCycleLengthDays = averageCycleLength)
            try {
                client.save(settings, "CycleSettings")
                _cycleSettings.value = settings
                computeCycleState()
                buildCalendarDays()
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }

    fun selectDate(date: LocalDate) {
        _selectedDate.value = date
    }

    private fun computeCycleState() {
        val logs = _periodLogs.value.sortedByDescending { it.startDate }
        if (logs.isEmpty()) return

        val lastPeriodStart = LocalDate.parse(logs.first().startDate)
        val today = Clock.System.todayIn(TimeZone.currentSystemDefault())
        val daysSinceStart = today.toEpochDays() - lastPeriodStart.toEpochDays()
        val cycleLength = _cycleSettings.value.averageCycleLengthDays

        _cycleDay.value = daysSinceStart + 1

        val phase = when {
            daysSinceStart < 5 -> CyclePhase.MENSTRUAL
            daysSinceStart < 14 -> CyclePhase.FOLLICULAR
            daysSinceStart < 17 -> CyclePhase.OVULATION
            daysSinceStart < cycleLength -> CyclePhase.LUTEAL
            else -> CyclePhase.MENSTRUAL
        }

        _cyclePhase.value = phase
        _isSharkWeek.value = phase == CyclePhase.MENSTRUAL

        val recommendation = getPhaseRecommendation(phase)
        _phaseDescription.value = recommendation.description
    }

    private fun buildCalendarDays() {
        val today = Clock.System.todayIn(TimeZone.currentSystemDefault())
        val startOfMonth = LocalDate(today.year, today.month, 1)
        val nextMonth = startOfMonth.plus(1, DateTimeUnit.MONTH)
        val daysInMonth = nextMonth.minus(1, DateTimeUnit.DAY).dayOfMonth
        val firstDayOfWeek = startOfMonth.dayOfWeek.ordinal

        val days = mutableListOf<CalendarDay>()
        repeat(firstDayOfWeek) { days.add(CalendarDay(null, null, false)) }

        val logs = _periodLogs.value
        for (dayNum in 1..daysInMonth) {
            val date = LocalDate(today.year, today.month, dayNum)
            val isToday = date == today
            val isPeriod = logs.any { log ->
                val start = LocalDate.parse(log.startDate)
                val end = log.endDate?.let { LocalDate.parse(it) } ?: start.plus(4, DateTimeUnit.DAY)
                date in start..end
            }
            days.add(CalendarDay(date, _cyclePhase.value, isPeriod, isToday))
        }

        _calendarDays.value = days
    }
}

data class CalendarDay(
    val date: LocalDate?,
    val phase: CyclePhase?,
    val isPeriod: Boolean = false,
    val isToday: Boolean = false
)
