package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.data.factory.DataClientFactory
import com.sundeefundee.core.data.factory.HealthClientFactory
import com.sundeefundee.core.domain.benchmark.BenchmarkCatalog
import com.sundeefundee.core.domain.benchmark.BenchmarkReadinessCalculator
import com.sundeefundee.core.domain.benchmark.BenchmarkCategory
import com.sundeefundee.core.model.BenchmarkResult
import com.sundeefundee.core.model.CyclePhase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class BenchmarksViewModel @Inject constructor(
    private val dataClientFactory: DataClientFactory,
    private val healthClientFactory: HealthClientFactory
) : ViewModel() {

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage = _errorMessage.asStateFlow()

    private val _selectedCategory = MutableStateFlow(BenchmarkCategory.SUNDEE_FUNDEE.rawValue)
    val selectedCategory = _selectedCategory.asStateFlow()

    private val _benchmarks = MutableStateFlow(BenchmarkCatalog.benchmarksIn(BenchmarkCategory.SUNDEE_FUNDEE))
    val benchmarks = _benchmarks.asStateFlow()

    private val _userResults = MutableStateFlow<Map<String, List<BenchmarkResult>>>(emptyMap())
    val userResults = _userResults.asStateFlow()

    private val _cyclePhase = MutableStateFlow<CyclePhase?>(null)
    val cyclePhase = _cyclePhase.asStateFlow()

    private val _showScoreEntry = MutableStateFlow<String?>(null)
    val showScoreEntry = _showScoreEntry.asStateFlow()

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            loadUserResults()
            loadCyclePhase()
            updateBenchmarksForCategory()
            _isLoading.value = false
        }
    }

    fun selectCategory(category: String) {
        _selectedCategory.value = category
        updateBenchmarksForCategory()
    }

    fun saveResult(benchmarkId: String, score: Double, notes: String?) {
        viewModelScope.launch {
            val result = BenchmarkResult(
                id = java.util.UUID.randomUUID().toString(),
                benchmarkId = benchmarkId,
                score = score,
                notes = notes,
                date = kotlinx.datetime.Clock.System.now().toString(),
                cyclePhase = _cyclePhase.value
            )
            try {
                dataClientFactory.client.save(result, "BenchmarkResult")
                _showScoreEntry.value = null
                loadUserResults()
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }

    fun showScoreEntry(benchmarkId: String) {
        _showScoreEntry.value = benchmarkId
    }

    fun dismissScoreEntry() {
        _showScoreEntry.value = null
    }

    fun getReadiness(benchmarkId: String) = BenchmarkReadinessCalculator.calculateReadiness(
        phase = _cyclePhase.value,
        movementTags = emptyList()
    )

    fun getBestResult(benchmarkId: String): BenchmarkResult? {
        val results = _userResults.value[benchmarkId] ?: return null
        return results.maxByOrNull { it.score }
    }

    fun formatScore(scoringType: String, score: Double): String {
        return when (scoringType) {
            "time" -> {
                val minutes = score.toInt() / 60
                val seconds = score.toInt() % 60
                String.format("%d:%02d", minutes, seconds)
            }
            "roundsAndReps" -> {
                val rounds = score.toInt() / 10000
                val reps = score.toInt() % 10000
                "$rounds rounds + $reps reps"
            }
            "load" -> "${score.toInt()} lb"
            "reps" -> "${score.toInt()} reps"
            "calories" -> "${score.toInt()} cal"
            "distance" -> "${score.toInt()} m"
            else -> "${score.toInt()}"
        }
    }

    private suspend fun loadUserResults() {
        try {
            val records: List<BenchmarkResult> = dataClientFactory.client.fetchAll("BenchmarkResult")
            _userResults.value = records.groupBy { it.benchmarkId }
        } catch (_: Exception) {}
    }

    private suspend fun loadCyclePhase() {
        try {
            val healthClient = healthClientFactory.client
            if (healthClient.isAvailable) {
                val cycles = healthClient.fetchMenstrualCycles(
                    startDate = null, endDate = null, limit = 100
                )
                if (cycles.isNotEmpty()) {
                    val lastCycle = cycles.last()
                    val daysSince = (System.currentTimeMillis() -
                        lastCycle.startDate.toEpochMilliseconds()) / (1000 * 60 * 60 * 24)
                    _cyclePhase.value = when (daysSince.toInt()) {
                        in 0..4 -> CyclePhase.MENSTRUAL
                        in 5..13 -> CyclePhase.FOLLICULAR
                        in 14..16 -> CyclePhase.OVULATION
                        else -> CyclePhase.LUTEAL
                    }
                }
            }
        } catch (_: Exception) {}
    }

    private fun updateBenchmarksForCategory() {
        val category = BenchmarkCategory.entries.find { it.rawValue == _selectedCategory.value }
            ?: BenchmarkCategory.SUNDEE_FUNDEE
        _benchmarks.value = BenchmarkCatalog.benchmarksIn(category)
    }
}
