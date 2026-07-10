package com.framey.gallery

import android.content.Context
import android.content.ContentUris
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.util.ArrayList

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.framey.gallery/mediastore"
    private val PERMISSION_CHANNEL = "com.framey.gallery/permissions"
    private val PERMISSION_REQUEST_CODE = 1001
    private var permissionResult: MethodChannel.Result? = null
    private lateinit var mediaStoreManager: MediaStoreManager
    private lateinit var methodChannel: MethodChannel
    private lateinit var permissionChannel: MethodChannel

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        mediaStoreManager = MediaStoreManager(this)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        permissionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
        
        methodChannel.setMethodCallHandler { call, result ->
            android.util.Log.d("Framey", "Received method call: ${call.method}")
            
            when (call.method) {
                "getMediaItems" -> handleGetMediaItems(call, result)
                "getAlbums" -> handleGetAlbums(call, result)
                "getMediaThumbnail" -> handleGetMediaThumbnail(call, result)
                "getMediaBytes" -> handleGetMediaBytes(call, result)
                "deleteMediaItem" -> handleDeleteMediaItem(call, result)
                "moveToRecycleBin" -> handleMoveToRecycleBin(call, result)
                "restoreFromRecycleBin" -> handleRestoreFromRecycleBin(call, result)
                "checkPermissions" -> handleCheckPermissions(call, result)
                "requestPermissions" -> handleRequestPermissions(call, result)
                "deletePermanently" -> handleDeletePermanently(call, result)
                "emptyRecycleBin" -> handleEmptyRecycleBin(call, result)
                "hideMediaItem" -> handleHideMediaItem(call, result)
                "unhideMediaItem" -> handleUnhideMediaItem(call, result)
                "shareMediaItems" -> handleShareMediaItems(call, result)
                else -> result.notImplemented()
            }
        }

        permissionChannel.setMethodCallHandler { call, result ->
            android.util.Log.d("Framey", "Received permission method call: ${call.method}")
            
            when (call.method) {
                "checkMediaPermissions" -> checkMediaPermissions(result)
                "requestMediaPermissions" -> requestMediaPermissions(result)
                else -> result.notImplemented()
            }
        }
    }
    
    private fun checkMediaPermissions(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val hasImagesPermission = checkSelfPermission(android.Manifest.permission.READ_MEDIA_IMAGES) == android.content.pm.PackageManager.PERMISSION_GRANTED
                val hasVideosPermission = checkSelfPermission(android.Manifest.permission.READ_MEDIA_VIDEO) == android.content.pm.PackageManager.PERMISSION_GRANTED
                val granted = hasImagesPermission && hasVideosPermission
                result.success(granted)
            } else {
                val hasStoragePermission = checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE) == android.content.pm.PackageManager.PERMISSION_GRANTED
                result.success(hasStoragePermission)
            }
        } catch (e: Exception) {
            result.error("PERMISSION_ERROR", "Failed to check permissions: ${e.message}", null)
        }
    }
    
    private fun requestMediaPermissions(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val permissions = arrayOf(
                    android.Manifest.permission.READ_MEDIA_IMAGES,
                    android.Manifest.permission.READ_MEDIA_VIDEO
                )
                this.permissionResult = result
                requestPermissions(permissions, PERMISSION_REQUEST_CODE)
            } else {
                val permissions = arrayOf(android.Manifest.permission.READ_EXTERNAL_STORAGE)
                this.permissionResult = result
                requestPermissions(permissions, PERMISSION_REQUEST_CODE)
            }
        } catch (e: Exception) {
            result.error("PERMISSION_ERROR", "Failed to request permissions: ${e.message}", null)
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val result = this.permissionResult
            if (result != null) {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val imagesGranted = grantResults.isNotEmpty() && 
                            grantResults[permissions.indexOf(android.Manifest.permission.READ_MEDIA_IMAGES)] == android.content.pm.PackageManager.PERMISSION_GRANTED
                        val videosGranted = grantResults.isNotEmpty() && 
                            grantResults[permissions.indexOf(android.Manifest.permission.READ_MEDIA_VIDEO)] == android.content.pm.PackageManager.PERMISSION_GRANTED
                        val allGranted = imagesGranted && videosGranted
                        result.success(allGranted)
                    } else {
                        val storageGranted = grantResults.isNotEmpty() && 
                            grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED
                        result.success(storageGranted)
                    }
                } catch (e: Exception) {
                    result.error("PERMISSION_ERROR", "Failed to process permission result: ${e.message}", null)
                } finally {
                    this.permissionResult = null
                }
            }
        }
    }

    private fun handleGetMediaItems(call: MethodCall, result: MethodChannel.Result) {
        val albumId = call.argument<String?>("albumId")
        val mediaType = call.argument<String?>("mediaType")
        val limit = call.argument<Int>("limit") ?: 50
        val offset = call.argument<Int>("offset") ?: 0
        val includeTrashed = call.argument<Boolean>("includeTrashed") ?: false
        val includeHidden = call.argument<Boolean>("includeHidden") ?: false
        val searchQuery = call.argument<String?>("searchQuery")

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val mediaResult = mediaStoreManager.getMediaItems(albumId, mediaType, limit, offset, includeTrashed, includeHidden, searchQuery)
                mediaResult.fold(
                    onSuccess = { mediaItems ->
                        val jsonList = mediaItems.map { mediaItem ->
                            JSONObject().apply {
                                put("id", mediaItem.id)
                                put("uri", mediaItem.uri)
                                put("name", mediaItem.name)
                                put("type", mediaItem.type)
                                put("size", mediaItem.size)
                                put("dateAdded", mediaItem.dateAdded)
                                put("dateModified", mediaItem.dateModified)
                                put("width", mediaItem.width)
                                put("height", mediaItem.height)
                                put("duration", mediaItem.duration)
                                put("thumbnailUri", mediaItem.thumbnailPath)
                                val metadataObj = JSONObject()
                                mediaItem.metadata?.forEach { (key, value) ->
                                    metadataObj.put(key, value)
                                }
                                put("metadata", metadataObj)
                            }.toString()
                        }
                        runOnUiThread { result.success(jsonList) }
                    },
                    onFailure = { exception ->
                        runOnUiThread { result.error("MEDIA_ERROR", exception.message, null) }
                    }
                )
            } catch (e: Exception) {
                runOnUiThread { result.error("UNKNOWN_ERROR", e.message, null) }
            }
        }
    }

    private fun handleGetAlbums(call: MethodCall, result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val albumResult = mediaStoreManager.getAlbums()
                albumResult.fold(
                    onSuccess = { albums ->
                        val jsonList = albums.map { album ->
                            JSONObject().apply {
                                put("id", album.id)
                                put("name", album.name)
                                put("type", album.type)
                                put("coverUri", album.coverUri)
                                put("mediaCount", album.mediaCount)
                                put("lastModified", album.lastModified)
                                put("metadata", JSONObject(album.metadata ?: emptyMap<String, Any>()))
                            }.toString()
                        }
                        runOnUiThread { result.success(jsonList) }
                    },
                    onFailure = { exception ->
                        runOnUiThread { result.error("ALBUM_ERROR", exception.message, null) }
                    }
                )
            } catch (e: Exception) {
                runOnUiThread { result.error("UNKNOWN_ERROR", e.message, null) }
            }
        }
    }

    private fun getMediaId(call: MethodCall): Long? {
        // Safe casting from Integer/Long/Number
        return call.argument<Number>("mediaId")?.toLong()
    }

    private fun handleDeleteMediaItem(call: MethodCall, result: MethodChannel.Result) {
        val mediaId = getMediaId(call)
        if (mediaId == null) {
            result.error("INVALID_ARGUMENT", "mediaId is required", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val deleteResult = mediaStoreManager.moveToRecycleBin(mediaId)
                deleteResult.fold(
                    onSuccess = { success ->
                        runOnUiThread { result.success(success) }
                    },
                    onFailure = { exception ->
                        runOnUiThread { result.error("DELETE_ERROR", exception.message, null) }
                    }
                )
            } catch (e: Exception) {
                runOnUiThread { result.error("UNKNOWN_ERROR", e.message, null) }
            }
        }
    }

    private fun handleMoveToRecycleBin(call: MethodCall, result: MethodChannel.Result) {
        val mediaId = getMediaId(call)
        if (mediaId == null) {
            result.error("INVALID_ARGUMENT", "mediaId is required", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val moveResult = mediaStoreManager.moveToRecycleBin(mediaId)
                moveResult.fold(
                    onSuccess = { success ->
                        runOnUiThread { result.success(success) }
                    },
                    onFailure = { exception ->
                        runOnUiThread { result.error("MOVE_ERROR", exception.message, null) }
                    }
                )
            } catch (e: Exception) {
                runOnUiThread { result.error("UNKNOWN_ERROR", e.message, null) }
            }
        }
    }

    private fun handleRestoreFromRecycleBin(call: MethodCall, result: MethodChannel.Result) {
        val mediaId = getMediaId(call)
        if (mediaId == null) {
            result.error("INVALID_ARGUMENT", "mediaId is required", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val restoreResult = mediaStoreManager.restoreFromRecycleBin(mediaId)
                restoreResult.fold(
                    onSuccess = { success ->
                        runOnUiThread { result.success(success) }
                    },
                    onFailure = { exception ->
                        runOnUiThread { result.error("RESTORE_ERROR", exception.message, null) }
                    }
                )
            } catch (e: Exception) {
                runOnUiThread { result.error("UNKNOWN_ERROR", e.message, null) }
            }
        }
    }

    private fun handleDeletePermanently(call: MethodCall, result: MethodChannel.Result) {
        val mediaId = getMediaId(call)
        if (mediaId == null) {
            result.error("INVALID_ARGUMENT", "mediaId is required", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val deleteResult = mediaStoreManager.deletePermanently(mediaId)
                deleteResult.fold(
                    onSuccess = { success ->
                        runOnUiThread { result.success(success) }
                    },
                    onFailure = { exception ->
                        runOnUiThread { result.error("DELETE_ERROR", exception.message, null) }
                    }
                )
            } catch (e: Exception) {
                runOnUiThread { result.error("UNKNOWN_ERROR", e.message, null) }
            }
        }
    }

    private fun handleEmptyRecycleBin(call: MethodCall, result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val emptyResult = mediaStoreManager.emptyRecycleBin()
                emptyResult.fold(
                    onSuccess = { success ->
                        runOnUiThread { result.success(success) }
                    },
                    onFailure = { exception ->
                        runOnUiThread { result.error("EMPTY_ERROR", exception.message, null) }
                    }
                )
            } catch (e: Exception) {
                runOnUiThread { result.error("UNKNOWN_ERROR", e.message, null) }
            }
        }
    }

    private fun handleHideMediaItem(call: MethodCall, result: MethodChannel.Result) {
        val mediaId = getMediaId(call)
        if (mediaId == null) {
            result.error("INVALID_ARGUMENT", "mediaId is required", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val hideResult = mediaStoreManager.hideMediaItem(mediaId)
                hideResult.fold(
                    onSuccess = { success ->
                        runOnUiThread { result.success(success) }
                    },
                    onFailure = { exception ->
                        runOnUiThread { result.error("HIDE_ERROR", exception.message, null) }
                    }
                )
            } catch (e: Exception) {
                runOnUiThread { result.error("UNKNOWN_ERROR", e.message, null) }
            }
        }
    }

    private fun handleUnhideMediaItem(call: MethodCall, result: MethodChannel.Result) {
        val mediaId = getMediaId(call)
        if (mediaId == null) {
            result.error("INVALID_ARGUMENT", "mediaId is required", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val unhideResult = mediaStoreManager.unhideMediaItem(mediaId)
                unhideResult.fold(
                    onSuccess = { success ->
                        runOnUiThread { result.success(success) }
                    },
                    onFailure = { exception ->
                        runOnUiThread { result.error("UNHIDE_ERROR", exception.message, null) }
                    }
                )
            } catch (e: Exception) {
                runOnUiThread { result.error("UNKNOWN_ERROR", e.message, null) }
            }
        }
    }

    private fun handleCheckPermissions(call: MethodCall, result: MethodChannel.Result) {
        try {
            val permissions = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                listOf(
                    android.Manifest.permission.READ_MEDIA_IMAGES,
                    android.Manifest.permission.READ_MEDIA_VIDEO,
                    android.Manifest.permission.ACCESS_MEDIA_LOCATION
                )
            } else {
                listOf(
                    android.Manifest.permission.READ_EXTERNAL_STORAGE,
                    android.Manifest.permission.ACCESS_MEDIA_LOCATION
                )
            }

            val permissionStatus = permissions.associateWith { permission ->
                checkSelfPermission(permission) == android.content.pm.PackageManager.PERMISSION_GRANTED
            }

            result.success(permissionStatus)
        } catch (e: Exception) {
            result.error("PERMISSION_ERROR", e.message, null)
        }
    }

    private fun handleRequestPermissions(call: MethodCall, result: MethodChannel.Result) {
        try {
            val permissions = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                arrayOf(
                    android.Manifest.permission.READ_MEDIA_IMAGES,
                    android.Manifest.permission.READ_MEDIA_VIDEO,
                    android.Manifest.permission.ACCESS_MEDIA_LOCATION
                )
            } else {
                arrayOf(
                    android.Manifest.permission.READ_EXTERNAL_STORAGE,
                    android.Manifest.permission.ACCESS_MEDIA_LOCATION
                )
            }

            requestPermissions(permissions, 1001)
            result.success(true)
        } catch (e: Exception) {
            result.error("PERMISSION_ERROR", e.message, null)
        }
    }

    private fun handleGetMediaThumbnail(call: MethodCall, result: MethodChannel.Result) {
        val uriStr = call.argument<String>("uri") ?: return result.error("ARG_ERROR", "URI is required", null)
        val width = call.argument<Int>("width") ?: 200
        val height = call.argument<Int>("height") ?: 200

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val uri = Uri.parse(uriStr)
                val bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    try {
                        contentResolver.loadThumbnail(uri, android.util.Size(width, height), null)
                    } catch (e: Exception) {
                        null
                    }
                } else {
                    if (width > 512 || height > 512) {
                         try {
                             contentResolver.openInputStream(uri)?.use { input ->
                                  val options = BitmapFactory.Options().apply {
                                      inJustDecodeBounds = true
                                  }
                                  BitmapFactory.decodeStream(input, null, options)
                                  options.inSampleSize = calculateInSampleSize(options, width, height)
                                  options.inJustDecodeBounds = false
                                  contentResolver.openInputStream(uri)?.use { input2 ->
                                      BitmapFactory.decodeStream(input2, null, options)
                                  }
                             }
                         } catch (e: Exception) { null }
                    } else {
                        val id = try { ContentUris.parseId(uri) } catch (e: Exception) { -1L }
                        if (id != -1L) {
                            MediaStore.Images.Thumbnails.getThumbnail(contentResolver, id, MediaStore.Images.Thumbnails.MINI_KIND, null)
                        } else null
                    }
                }
                
                if (bitmap != null) {
                    val stream = java.io.ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 85, stream)
                    val bytes = stream.toByteArray()
                    runOnUiThread { result.success(bytes) }
                } else {
                    runOnUiThread { result.error("THUMB_ERROR", "Failed to load thumbnail", null) }
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("THUMB_ERROR", e.message, null) }
            }
        }
    }

    private fun calculateInSampleSize(options: BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        val (height: Int, width: Int) = options.outHeight to options.outWidth
        var inSampleSize = 1
        if (height > reqHeight || width > reqWidth) {
            val halfHeight: Int = height / 2
            val halfWidth: Int = width / 2
            while ((halfHeight / inSampleSize) >= reqHeight && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }

    private fun handleGetMediaBytes(call: MethodCall, result: MethodChannel.Result) {
        val uriStr = call.argument<String>("uri") ?: return result.error("ARG_ERROR", "URI is required", null)

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val uri = Uri.parse(uriStr)
                contentResolver.openInputStream(uri)?.use { inputStream ->
                    val bytes = inputStream.readBytes()
                    runOnUiThread { result.success(bytes) }
                } ?: runOnUiThread { result.error("BYTES_ERROR", "Failed to open stream", null) }
            } catch (e: OutOfMemoryError) {
                runOnUiThread { result.error("OOM_ERROR", "Image too large for memory", null) }
            } catch (e: Exception) {
                runOnUiThread { result.error("BYTES_ERROR", e.message, null) }
            }
        }
    }

    private fun handleShareMediaItems(call: MethodCall, result: MethodChannel.Result) {
        val uris = call.argument<List<String>>("uris") ?: return result.error("ARG_ERROR", "URIs required", null)
        val type = call.argument<String>("type") ?: "image/*"

        if (uris.isEmpty()) {
             result.error("ARG_ERROR", "No items to share", null)
             return
        }

        try {
            val uriList = ArrayList<Uri>()
            for (uriStr in uris) {
                uriList.add(Uri.parse(uriStr))
            }

            val shareIntent = Intent().apply {
                if (uriList.size == 1) {
                    action = Intent.ACTION_SEND
                    putExtra(Intent.EXTRA_STREAM, uriList[0])
                } else {
                    action = Intent.ACTION_SEND_MULTIPLE
                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, uriList)
                }
                setType(type)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            
            startActivity(Intent.createChooser(shareIntent, "Share Media"))
            result.success(true)
        } catch (e: Exception) {
             result.error("SHARE_ERROR", e.message, null)
        }
    }
}
