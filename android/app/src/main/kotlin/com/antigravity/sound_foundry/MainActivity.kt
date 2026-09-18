package com.antigravity.sound_foundry

import android.content.ComponentName
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.media.AudioAttributes
import android.media.MediaMetadataRetriever
import android.media.MediaPlayer
import android.media.PlaybackParams
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity(), MediaPlaybackService.MediaActionListener {
    private val MEDIA_STORE_CHANNEL = "com.antigravity.sound_foundry/media_store"
    private val AUDIO_PLAYER_CHANNEL = "com.antigravity.sound_foundry/audio_player"

    private var mediaPlayer: MediaPlayer?
        get() = MediaPlaybackService.activePlayer
        set(value) {
            MediaPlaybackService.activePlayer = value
        }
    private var playerMethodChannel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var positionPollRunnable: Runnable? = null
    private var currentSpeed: Float = 1.0f

    private var isPrepared: Boolean
        get() = MediaPlaybackService.isPlayerPrepared
        set(value) {
            MediaPlaybackService.isPlayerPrepared = value
        }
    private var isPreparing: Boolean = false
    private var playWhenReady: Boolean = false
    private var isLoadCallbackInvoked: Boolean = false

    // Media notification service binding
    private var mediaService: MediaPlaybackService? = null
    private var isServiceBound: Boolean = false
    private var currentTrackTitle: String = ""
    private var currentTrackArtist: String = ""
    private var currentTrackAlbum: String = ""
    private var currentArtworkPath: String? = null

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as MediaPlaybackService.LocalBinder
            mediaService = binder.getService()
            mediaService?.actionListener = this@MainActivity
            isServiceBound = true

            // Push current metadata if we have a loaded track
            if (currentTrackTitle.isNotEmpty()) {
                mediaService?.updateMetadata(
                    currentTrackTitle, currentTrackArtist, currentTrackAlbum, currentArtworkPath
                )
                val isPlaying = try { mediaPlayer?.isPlaying ?: false } catch (_: Exception) { false }
                val pos = try { mediaPlayer?.currentPosition?.toLong() ?: 0L } catch (_: Exception) { 0L }
                val dur = try { mediaPlayer?.duration?.toLong() ?: 0L } catch (_: Exception) { 0L }
                mediaService?.updatePlaybackState(isPlaying, pos, dur)
            } else if (mediaPlayer?.isPlaying == true) {
                // Background playback was already running when app was opened/reopened
                val pos = try { mediaPlayer?.currentPosition?.toLong() ?: 0L } catch (_: Exception) { 0L }
                val dur = try { mediaPlayer?.duration?.toLong() ?: 0L } catch (_: Exception) { 0L }
                mediaService?.updatePlaybackState(true, pos, dur)
                startPositionPolling()
                notifyStatusChanged("playing")
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            mediaService = null
            isServiceBound = false
        }
    }

    // MediaActionListener callbacks from the notification service
    override fun onPlayRequested() {
        mainHandler.post {
            try {
                if (isPreparing) {
                    playWhenReady = true
                    return@post
                }
                mediaPlayer?.let { player ->
                    if (isPrepared && !player.isPlaying) {
                        player.start()
                        startPositionPolling()
                        notifyStatusChanged("playing")
                    }
                }
            } catch (_: Exception) {}
        }
    }

    override fun onPauseRequested() {
        mainHandler.post {
            try {
                playWhenReady = false
                mediaPlayer?.let { player ->
                    if (isPrepared && player.isPlaying) {
                        player.pause()
                        stopPositionPolling()
                        notifyStatusChanged("paused")
                    }
                }
            } catch (_: Exception) {}
        }
    }

    override fun onNextRequested() {
        mainHandler.post {
            playerMethodChannel?.invokeMethod("onMediaAction", mapOf("action" to "next"))
        }
    }

    override fun onPreviousRequested() {
        mainHandler.post {
            playerMethodChannel?.invokeMethod("onMediaAction", mapOf("action" to "previous"))
        }
    }

    override fun onStopRequested() {
        mainHandler.post {
            try {
                playWhenReady = false
                isPrepared = false
                isPreparing = false
                mediaPlayer?.let { player ->
                    try {
                        if (player.isPlaying) {
                            player.stop()
                        }
                    } catch (_: Exception) {}
                    stopPositionPolling()
                    notifyStatusChanged("idle")
                }
            } catch (_: Exception) {}
        }
    }

    private fun bindMediaService() {
        if (!isServiceBound) {
            val intent = Intent(this, MediaPlaybackService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
        }
    }

    private fun unbindMediaService() {
        if (isServiceBound) {
            mediaService?.stopForegroundNotification()
            try {
                unbindService(serviceConnection)
            } catch (_: Exception) {}
            isServiceBound = false
            mediaService = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. MediaStore Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_STORE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "queryAudioFiles" -> {
                    Thread {
                        try {
                            val audioList = queryMediaStoreAudio()
                            runOnUiThread {
                                result.success(audioList)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("QUERY_ERROR", e.message, null)
                            }
                        }
                    }.start()
                }
                "extractArtwork" -> {
                    val filePath = call.argument<String>("filePath")
                    val mediaUriStr = call.argument<String>("mediaUri")
                    Thread {
                        try {
                            val artPath = extractEmbeddedArtwork(filePath, mediaUriStr)
                            runOnUiThread {
                                result.success(artPath)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.success(null)
                            }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }

        // 2. Audio Player Channel for Real Android Playback (Local & Remote Streams)
        playerMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_PLAYER_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "load" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr.isNullOrEmpty()) {
                            result.error("INVALID_URI", "Media URI cannot be empty", null)
                            return@setMethodCallHandler
                        }

                        // Extract metadata for notification
                        currentTrackTitle = call.argument<String>("title") ?: "Unknown Title"
                        currentTrackArtist = call.argument<String>("artist") ?: "Unknown Artist"
                        currentTrackAlbum = call.argument<String>("album") ?: ""
                        currentArtworkPath = call.argument<String>("artworkPath")

                        try {
                            initMediaPlayer(uriStr) { success, durationMs, errorMsg ->
                                runOnUiThread {
                                    if (success) {
                                        // Start/bind the media service and show notification
                                        bindMediaService()
                                        mediaService?.updateMetadata(
                                            currentTrackTitle, currentTrackArtist,
                                            currentTrackAlbum, currentArtworkPath
                                        )
                                        mediaService?.updatePlaybackState(false, 0, durationMs.toLong())
                                        result.success(mapOf("duration" to durationMs))
                                    } else {
                                        result.error("LOAD_FAILED", errorMsg ?: "Failed to load audio", null)
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            result.error("LOAD_ERROR", e.message, null)
                        }
                    }
                    "play" -> {
                        try {
                            if (isPreparing) {
                                playWhenReady = true
                                notifyStatusChanged("loading")
                                result.success(null)
                                return@setMethodCallHandler
                            }
                            mediaPlayer?.let { player ->
                                if (isPrepared && !player.isPlaying) {
                                    player.start()
                                    startPositionPolling()
                                    notifyStatusChanged("playing")
                                }
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("PLAY_ERROR", e.message, null)
                        }
                    }
                    "pause" -> {
                        try {
                            playWhenReady = false
                            mediaPlayer?.let { player ->
                                if (isPrepared && player.isPlaying) {
                                    player.pause()
                                    stopPositionPolling()
                                    notifyStatusChanged("paused")
                                }
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("PAUSE_ERROR", e.message, null)
                        }
                    }
                    "stop" -> {
                        try {
                            playWhenReady = false
                            isPrepared = false
                            isPreparing = false
                            mediaPlayer?.let { player ->
                                try {
                                    if (player.isPlaying) {
                                        player.stop()
                                    }
                                } catch (_: Exception) {}
                                stopPositionPolling()
                                notifyStatusChanged("idle")
                            }
                            // Stop the notification service
                            unbindMediaService()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("STOP_ERROR", e.message, null)
                        }
                    }
                    "seek" -> {
                        val positionMs = call.argument<Int>("position") ?: 0
                        try {
                            mediaPlayer?.let { player ->
                                if (isPrepared) {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                        player.seekTo(positionMs.toLong(), MediaPlayer.SEEK_CLOSEST)
                                    } else {
                                        player.seekTo(positionMs)
                                    }
                                }
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SEEK_ERROR", e.message, null)
                        }
                    }
                    "setVolume" -> {
                        val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                        try {
                            mediaPlayer?.setVolume(volume, volume)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("VOLUME_ERROR", e.message, null)
                        }
                    }
                    "setSpeed" -> {
                        val speed = (call.argument<Double>("speed") ?: 1.0).toFloat()
                        currentSpeed = speed
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && mediaPlayer != null && isPrepared) {
                                val params = mediaPlayer!!.playbackParams ?: PlaybackParams()
                                params.speed = speed
                                mediaPlayer!!.playbackParams = params
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SPEED_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun initMediaPlayer(uriStr: String, callback: (Boolean, Int, String?) -> Unit) {
        stopPositionPolling()
        isPrepared = false
        isPreparing = true
        playWhenReady = false
        isLoadCallbackInvoked = false

        try {
            mediaPlayer?.apply {
                try {
                    reset()
                    release()
                } catch (_: Exception) {}
            }
            mediaPlayer = null

            val player = MediaPlayer()
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .build()
            )

            if (uriStr.startsWith("content://")) {
                player.setDataSource(applicationContext, Uri.parse(uriStr))
            } else if (uriStr.startsWith("assets/")) {
                val assetKey = flutterEngine?.dartExecutor?.let {
                    io.flutter.FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(uriStr)
                } ?: uriStr
                val afd = assets.openFd(assetKey)
                player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
            } else if (uriStr.startsWith("http://") || uriStr.startsWith("https://")) {
                val cleanUrl = uriStr.trim()
                try {
                    player.setWakeMode(applicationContext, android.os.PowerManager.PARTIAL_WAKE_LOCK)
                } catch (_: Exception) {}

                try {
                    val headers = HashMap<String, String>()
                    headers["User-Agent"] = "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36"
                    player.setDataSource(applicationContext, Uri.parse(cleanUrl), headers)
                } catch (_: Exception) {
                    player.reset()
                    player.setAudioAttributes(
                        AudioAttributes.Builder()
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .build()
                    )
                    player.setDataSource(cleanUrl)
                }
            } else {
                player.setDataSource(uriStr)
            }

            player.setOnPreparedListener { mp ->
                isPrepared = true
                isPreparing = false
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && currentSpeed != 1.0f) {
                    try {
                        val params = mp.playbackParams ?: PlaybackParams()
                        params.speed = currentSpeed
                        mp.playbackParams = params
                    } catch (_: Exception) {}
                }

                if (!isLoadCallbackInvoked) {
                    isLoadCallbackInvoked = true
                    callback(true, mp.duration, null)
                }

                if (playWhenReady) {
                    playWhenReady = false
                    try {
                        mp.start()
                        startPositionPolling()
                        notifyStatusChanged("playing")
                    } catch (_: Exception) {}
                }
            }

            player.setOnCompletionListener {
                stopPositionPolling()
                notifyStatusChanged("completed")
            }

            player.setOnErrorListener { _, what, extra ->
                isPrepared = false
                isPreparing = false
                playWhenReady = false
                stopPositionPolling()
                notifyStatusChanged("error")
                if (!isLoadCallbackInvoked) {
                    isLoadCallbackInvoked = true
                    callback(false, 0, "MediaPlayer error: what=$what, extra=$extra")
                }
                true
            }

            player.prepareAsync()
            mediaPlayer = player
        } catch (e: Exception) {
            isPrepared = false
            isPreparing = false
            playWhenReady = false
            if (!isLoadCallbackInvoked) {
                isLoadCallbackInvoked = true
                callback(false, 0, e.message)
            }
        }
    }

    private fun startPositionPolling() {
        stopPositionPolling()
        positionPollRunnable = object : Runnable {
            override fun run() {
                mediaPlayer?.let { player ->
                    try {
                        if (player.isPlaying) {
                            val pos = player.currentPosition
                            val dur = player.duration
                            playerMethodChannel?.invokeMethod("onPositionUpdate", mapOf(
                                "position" to pos,
                                "duration" to dur
                            ))
                            // Also sync position to the notification service
                            mediaService?.updatePlaybackState(true, pos.toLong(), dur.toLong())
                            mainHandler.postDelayed(this, 100)
                        }
                    } catch (_: Exception) {}
                }
            }
        }
        mainHandler.post(positionPollRunnable!!)
    }

    private fun stopPositionPolling() {
        positionPollRunnable?.let {
            mainHandler.removeCallbacks(it)
            positionPollRunnable = null
        }
    }

    private fun notifyStatusChanged(status: String) {
        mainHandler.post {
            playerMethodChannel?.invokeMethod("onStatusChanged", mapOf("status" to status))

            // Sync status to media notification service
            val playing = status == "playing"
            val pos = try { mediaPlayer?.currentPosition?.toLong() ?: 0L } catch (_: Exception) { 0L }
            val dur = try { mediaPlayer?.duration?.toLong() ?: 0L } catch (_: Exception) { 0L }

            when (status) {
                "playing" -> {
                    mediaService?.updatePlaybackState(true, pos, dur)
                }
                "paused" -> {
                    mediaService?.updatePlaybackState(false, pos, dur)
                }
                "completed", "idle" -> {
                    mediaService?.updatePlaybackState(false, 0, dur)
                }
            }
        }
    }

    private fun queryMediaStoreAudio(): List<Map<String, Any?>> {
        val audioList = mutableListOf<Map<String, Any?>>()
        val uri: Uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.SIZE
        )

        // Comprehensive audio query without restrictive _data WHERE clause that fails on scoped storage
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0 OR " +
                "${MediaStore.Audio.Media.MIME_TYPE} LIKE 'audio/%' OR " +
                "${MediaStore.Audio.Media.DISPLAY_NAME} LIKE '%.mp3' OR " +
                "${MediaStore.Audio.Media.DISPLAY_NAME} LIKE '%.m4a' OR " +
                "${MediaStore.Audio.Media.DISPLAY_NAME} LIKE '%.flac' OR " +
                "${MediaStore.Audio.Media.DISPLAY_NAME} LIKE '%.wav' OR " +
                "${MediaStore.Audio.Media.DISPLAY_NAME} LIKE '%.aac' OR " +
                "${MediaStore.Audio.Media.DISPLAY_NAME} LIKE '%.ogg'"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        contentResolver.query(uri, projection, selection, null, sortOrder)?.use { cursor ->
            val idCol = cursor.getColumnIndex(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndex(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndex(MediaStore.Audio.Media.ARTIST)
            val albumCol = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM)
            val durationCol = cursor.getColumnIndex(MediaStore.Audio.Media.DURATION)
            val dataCol = cursor.getColumnIndex(MediaStore.Audio.Media.DATA)
            val displayNameCol = cursor.getColumnIndex(MediaStore.Audio.Media.DISPLAY_NAME)
            val trackCol = cursor.getColumnIndex(MediaStore.Audio.Media.TRACK)
            val yearCol = cursor.getColumnIndex(MediaStore.Audio.Media.YEAR)
            val albumIdCol = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM_ID)
            val mimeCol = cursor.getColumnIndex(MediaStore.Audio.Media.MIME_TYPE)
            val sizeCol = cursor.getColumnIndex(MediaStore.Audio.Media.SIZE)

            while (cursor.moveToNext()) {
                val id = if (idCol != -1) cursor.getLong(idCol) else 0L
                val title = if (titleCol != -1) cursor.getString(titleCol) else null
                val artist = if (artistCol != -1) cursor.getString(artistCol) else null
                val album = if (albumCol != -1) cursor.getString(albumCol) else null
                val duration = if (durationCol != -1) cursor.getLong(durationCol) else 0L
                val data = if (dataCol != -1) cursor.getString(dataCol) else null
                val displayName = if (displayNameCol != -1) cursor.getString(displayNameCol) else null
                val track = if (trackCol != -1) cursor.getInt(trackCol) else null
                val year = if (yearCol != -1) cursor.getInt(yearCol) else null
                val albumId = if (albumIdCol != -1) cursor.getLong(albumIdCol) else -1L
                val mimeType = if (mimeCol != -1) cursor.getString(mimeCol) else null
                val size = if (sizeCol != -1) cursor.getLong(sizeCol) else 0L

                val contentUri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id).toString()

                val fallbackName = displayName?.substringBeforeLast('.')
                    ?: data?.substringAfterLast('/')?.substringBeforeLast('.')
                    ?: "Unknown Title"

                val cleanTitle = if (title.isNullOrBlank() || title.equals("<unknown>", ignoreCase = true)) {
                    fallbackName
                } else {
                    title.trim()
                }

                val cleanArtist = if (artist.isNullOrBlank() || artist.equals("<unknown>", ignoreCase = true)) {
                    "Unknown Artist"
                } else {
                    artist.trim()
                }

                val cleanAlbum = if (album.isNullOrBlank() || album.equals("<unknown>", ignoreCase = true)) {
                    "Unknown Album"
                } else {
                    album.trim()
                }

                val item = mapOf<String, Any?>(
                    "id" to id.toString(),
                    "title" to cleanTitle,
                    "artist" to cleanArtist,
                    "album" to cleanAlbum,
                    "durationMs" to duration,
                    "filePath" to (data ?: ""),
                    "contentUri" to contentUri,
                    "trackNumber" to track,
                    "year" to year,
                    "albumId" to albumId,
                    "mimeType" to mimeType,
                    "size" to size
                )

                audioList.add(item)
            }
        }

        return audioList
    }

    private fun extractEmbeddedArtwork(filePath: String?, mediaUriStr: String?): String? {
        val retriever = MediaMetadataRetriever()
        return try {
            if (!mediaUriStr.isNullOrBlank() && mediaUriStr.startsWith("content://")) {
                retriever.setDataSource(applicationContext, Uri.parse(mediaUriStr))
            } else if (!filePath.isNullOrBlank() && File(filePath).exists()) {
                retriever.setDataSource(filePath)
            } else if (!mediaUriStr.isNullOrBlank()) {
                retriever.setDataSource(applicationContext, Uri.parse(mediaUriStr))
            } else {
                return null
            }

            val picture = retriever.embeddedPicture ?: return null

            val cacheDir = File(cacheDir, "album_art_cache")
            if (!cacheDir.exists()) {
                cacheDir.mkdirs()
            }

            val hash = (filePath ?: mediaUriStr).hashCode().let { if (it < 0) -it else it }
            val isPng = picture.size > 8 && picture[0] == 0x89.toByte()
            val ext = if (isPng) ".png" else ".jpg"
            val targetFile = File(cacheDir, "art_$hash$ext")

            if (!targetFile.exists() || targetFile.length() == 0L) {
                FileOutputStream(targetFile).use { fos ->
                    fos.write(picture)
                    fos.flush()
                }
            }

            targetFile.absolutePath
        } catch (e: Exception) {
            null
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {}
        }
    }

    override fun onDestroy() {
        stopPositionPolling()
        val currentlyPlaying = try { mediaPlayer?.isPlaying ?: false } catch (_: Exception) { false }
        if (!currentlyPlaying) {
            unbindMediaService()
            try {
                mediaPlayer?.apply {
                    reset()
                    release()
                }
                mediaPlayer = null
                isPrepared = false
            } catch (_: Exception) {}
        } else {
            // When actively playing, unbind cleanly from the Activity without stopping background playback or releasing the player
            if (isServiceBound) {
                try {
                    unbindService(serviceConnection)
                } catch (_: Exception) {}
                isServiceBound = false
                mediaService = null
            }
        }
        super.onDestroy()
    }
}
