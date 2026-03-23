package com.sundeefundee.ui.features.benchmarks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.domain.model.Benchmark
import com.sundeefundee.domain.model.BenchmarkDefinition
import com.sundeefundee.domain.repository.BenchmarkRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

/**
 * UI State for the Benchmarks screen.
 */
data class BenchmarksUiState(
    val isLoading: Boolean = true,
    val benchmarks: List<BenchmarkWithDefinition> = emptyList(),
    val userBenchmarks: Map<String, Benchmark> = emptyMap(), // benchmarkId to Benchmark
    val showLogScoreDialog: Boolean = false,
    val selectedBenchmark: BenchmarkDefinition? = null,
    val userBenchmark: Benchmark? = null,
    val error: String? = null
)

/**
 * Benchmark with its definition for display.
 */
data class BenchmarkWithDefinition(
    val definition: BenchmarkDefinition,
    val userBenchmark: Benchmark?,
    val isPR: Boolean = false
)

/**
 * ViewModel for the Benchmarks screen.
 */
@HiltViewModel
class BenchmarksViewModel @Inject constructor(
    private val benchmarkRepository: BenchmarkRepository
) : ViewModel() {

    private val _userId = MutableStateFlow<String?>(null)
    private val _showLogScoreDialog = MutableStateFlow(false)
    private val _selectedBenchmark = MutableStateFlow<BenchmarkDefinition?>(null)
    private val _error = MutableStateFlow<String?>(null)

    // All benchmark definitions
    private val benchmarkDefinitions: StateFlow<List<BenchmarkDefinition>> =
        benchmarkRepository.getAllBenchmarks()
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // User's benchmarks
    private val userBenchmarks: StateFlow<Map<String, Benchmark>> = _userId
        .flatMapLatest { id ->
            if (id != null) {
                benchmarkRepository.getUserBenchmarks(id).flatMapLatest { benchmarks ->
                    flowOf(benchmarks.associateBy { it.benchmarkId })
                }
            } else {
                flowOf(emptyMap())
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyMap())

    // Combined UI state
    val uiState: StateFlow<BenchmarksUiState> = combine(
        benchmarkDefinitions,
        userBenchmarks,
        _showLogScoreDialog,
        _selectedBenchmark
    ) { definitions, userBench, showDialog, selected ->
        val benchmarksWithDefinitions = definitions.map { def ->
            val userB = userBench[def.id]
            BenchmarkWithDefinition(
                definition = def,
                userBenchmark = userB,
                isPR = userB != null
            )
        }.sortedBy { it.definition.name }

        val selectedUserBenchmark = selected?.id?.let { userBench[it] }

        BenchmarksUiState(
            isLoading = false,
            benchmarks = benchmarksWithDefinitions,
            userBenchmarks = userBench,
            showLogScoreDialog = showDialog,
            selectedBenchmark = selected,
            userBenchmark = selectedUserBenchmark,
            error = _error.value
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        BenchmarksUiState()
    )

    /**
     * Sets the current user ID for data loading.
     */
    fun setUserId(id: String) {
        _userId.value = id
    }

    /**
     * Loads benchmarks for the given user.
     */
    fun loadBenchmarks(userId: String) {
        _userId.value = userId
        viewModelScope.launch {
            try {
                benchmarkRepository.seedBenchmarksFromBundle()
            } catch (e: Exception) {
                _error.value = "Failed to load benchmarks: ${e.message}"
            }
        }
    }

    /**
     * Shows the log score dialog.
     */
    fun showLogScoreDialog(benchmark: BenchmarkDefinition) {
        _selectedBenchmark.value = benchmark
        _showLogScoreDialog.value = true
    }

    /**
     * Hides the log score dialog.
     */
    fun hideLogScoreDialog() {
        _showLogScoreDialog.value = false
        _selectedBenchmark.value = null
    }

    /**
     * Logs a benchmark score.
     */
    fun logBenchmarkScore(score: Double, notes: String?) {
        val userId = _userId.value ?: return
        val benchmarkId = _selectedBenchmark.value?.id ?: return

        viewModelScope.launch {
            try {
                val benchmark = Benchmark(
                    id = UUID.randomUUID().toString(),
                    odUserID = userId,
                    benchmarkId = benchmarkId,
                    score = score,
                    achievedDate = System.currentTimeMillis(),
                    notes = notes
                )
                benchmarkRepository.logBenchmark(benchmark)
                hideLogScoreDialog()
            } catch (e: Exception) {
                _error.value = "Failed to log score: ${e.message}"
            }
        }
    }

    /**
     * Clears any error state.
     */
    fun clearError() {
        _error.value = null
    }
}
