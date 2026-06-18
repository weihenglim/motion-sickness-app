package dev.davidv.motionsickness.motion

import android.annotation.TargetApi
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import dev.davidv.motionsickness.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

/**
 * Provides a Quick Settings tile to start/stop the MotionCuesService.
 */
@TargetApi(Build.VERSION_CODES.N)
class MotionCuesTileService : TileService() {

    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private var collectJob: Job? = null

    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
        collectJob?.cancel()
        collectJob = scope.launch {
            MotionCuesService.isRunning.collectLatest {
                updateTileState()
            }
        }
    }

    override fun onStopListening() {
        super.onStopListening()
        collectJob?.cancel()
    }

    override fun onClick() {
        super.onClick()
        if (MotionCuesService.isRunning.value) {
            MotionCuesService.stop(this)
        } else {
            MotionCuesService.start(this)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    private fun updateTileState() {
        val isRunning = MotionCuesService.isRunning.value
        qsTile?.apply {
            state = if (isRunning) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
            label = getString(R.string.motion_cues_tile_label)
            updateTile()
        }
    }
}