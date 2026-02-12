package com.framey.gallery

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.util.Date
import org.json.JSONArray
import org.json.JSONObject

enum class AlbumType {
    SYSTEM, CUSTOM, AI_FACES, AI_LOCATIONS, HIDDEN, RECYCLE_BIN
}

data class MediaItem(
    val id: Long,
    val uri: String,
    val name: String,
    val type: String, // "image" or "video"
    val size: Long,
    val dateAdded: Long,
    val dateModified: Long,
    val width: Int?,
    val height: Int?,
    val duration: Int?, // in seconds for videos
    val thumbnailPath: String?,
    val metadata: Map<String, Any>? = null
)

data class Album(
    val id: String,
    val name: String,
    val type: String, // "system", "custom", "ai_faces", "ai_locations", "hidden", "recycle_bin"
    val coverUri: String?,
    val mediaCount: Int,
    val lastModified: Long?,
    val metadata: Map<String, Any>? = null
)

class MediaStoreManager(private val context: Context) {
    
    private val prefs = context.getSharedPreferences("framey_recycle_bin", Context.MODE_PRIVATE)
    
    private fun getTrashedItems(): Map<Long, Long> {
        val json = prefs.getString("trashed_items", "{}") ?: "{}"
        val obj = JSONObject(json)
        val map = mutableMapOf<Long, Long>()
        obj.keys().forEach { key ->
            map[key.toLong()] = obj.getLong(key)
        }
        return map
    }
    
    private fun saveTrashedItems(map: Map<Long, Long>) {
        val obj = JSONObject()
        map.forEach { (id, timestamp) ->
            obj.put(id.toString(), timestamp)
        }
        prefs.edit().putString("trashed_items", obj.toString()).apply()
    }

    private fun getHiddenItems(): Set<Long> {
        val json = prefs.getString("hidden_items", "[]") ?: "[]"
        val arr = JSONArray(json)
        val set = mutableSetOf<Long>()
        for (i in 0 until arr.length()) {
            set.add(arr.getLong(i))
        }
        return set
    }

    private fun saveHiddenItems(set: Set<Long>) {
        val arr = JSONArray()
        set.forEach { arr.put(it) }
        prefs.edit().putString("hidden_items", arr.toString()).apply()
    }

    suspend fun getMediaItems(
        albumId: String? = null,
        mediaType: String? = null,
        limit: Int = 50,
        offset: Int = 0,
        includeTrashed: Boolean = false,
        includeHidden: Boolean = false,
        searchQuery: String? = null
    ): Result<List<MediaItem>> = withContext(Dispatchers.IO) {
        try {
            val mediaList = mutableListOf<MediaItem>()
            val selection = StringBuilder()
            val selectionArgs = mutableListOf<String>()
            
            val trashedIds = getTrashedItems().keys
            val hiddenIds = getHiddenItems()
            
            if (!includeTrashed && trashedIds.isNotEmpty()) {
                selection.append("${MediaStore.MediaColumns._ID} NOT IN (${trashedIds.joinToString(",")})")
            }

            if (!includeHidden && !includeTrashed && hiddenIds.isNotEmpty()) {
                if (selection.isNotEmpty()) selection.append(" AND ")
                selection.append("${MediaStore.MediaColumns._ID} NOT IN (${hiddenIds.joinToString(",")})")
            }
            
            if (albumId != null) {
                if (selection.isNotEmpty()) selection.append(" AND ")
                selection.append("${MediaStore.MediaColumns.BUCKET_DISPLAY_NAME} = ?")
                selectionArgs.add(albumId)
            }
            
            if (mediaType != null) {
                if (selection.isNotEmpty()) selection.append(" AND ")
                when (mediaType.lowercase()) {
                    "image" -> {
                        selection.append("${MediaStore.MediaColumns.MIME_TYPE} LIKE ?")
                        selectionArgs.add("image/%")
                    }
                    "video" -> {
                        selection.append("${MediaStore.MediaColumns.MIME_TYPE} LIKE ?")
                        selectionArgs.add("video/%")
                    }
                }
            }

            if (searchQuery != null && searchQuery.isNotEmpty()) {
                if (selection.isNotEmpty()) selection.append(" AND ")
                selection.append("(${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ? OR ${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?)")
                selectionArgs.add("%$searchQuery%")
                selectionArgs.add("%$searchQuery%")
            }
            
            val projection = arrayOf(
                MediaStore.MediaColumns._ID,
                MediaStore.MediaColumns.DISPLAY_NAME,
                MediaStore.MediaColumns.MIME_TYPE,
                MediaStore.MediaColumns.SIZE,
                MediaStore.MediaColumns.DATE_ADDED,
                MediaStore.MediaColumns.DATE_MODIFIED,
                MediaStore.MediaColumns.WIDTH,
                MediaStore.MediaColumns.HEIGHT,
                MediaStore.MediaColumns.DURATION,
                MediaStore.MediaColumns.DATA
            )
            
            val sortOrder = "${MediaStore.MediaColumns.DATE_ADDED} DESC"
            val contentUri = MediaStore.Files.getContentUri("external")
            
            val query = context.contentResolver.query(
                contentUri,
                projection,
                selection.toString().takeIf { it.isNotEmpty() },
                selectionArgs.takeIf { it.isNotEmpty() }?.toTypedArray(),
                sortOrder
            )
            
            query?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
                val mimeTypeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
                val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                val dateAddedColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_ADDED)
                val dateModifiedColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
                val widthColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.WIDTH)
                val heightColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.HEIGHT)
                val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DURATION)
                val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                
                var currentPosition = 0
                var itemsAdded = 0
                
                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idColumn)
                    
                    // If we are looking for trashed items, only include them
                    if (includeTrashed && !trashedIds.contains(id)) continue
                    // If we are looking for hidden items, only include them
                    if (includeHidden && !hiddenIds.contains(id)) continue
                    // Regular items handling already partially done via SQL, but for safety:
                    if (!includeTrashed && !includeHidden && (trashedIds.contains(id) || hiddenIds.contains(id))) continue
                    
                    if (currentPosition >= offset && itemsAdded < limit) {
                        val name = cursor.getString(nameColumn)
                        val mimeType = cursor.getString(mimeTypeColumn)
                        val size = cursor.getLong(sizeColumn)
                        val dateAdded = cursor.getLong(dateAddedColumn)
                        val dateModified = cursor.getLong(dateModifiedColumn)
                        val dataPath = cursor.getString(dataColumn)
                        
                        val width = if (cursor.isNull(widthColumn)) null else cursor.getLong(widthColumn).toInt()
                        val height = if (cursor.isNull(heightColumn)) null else cursor.getLong(heightColumn).toInt()
                        val duration = if (cursor.isNull(durationColumn)) null else cursor.getLong(durationColumn).toInt()
                        
                        val mediaUri = dataPath ?: Uri.withAppendedPath(contentUri, id.toString()).toString()
                        val thumbnailPath = generateThumbnail(context, Uri.withAppendedPath(contentUri, id.toString()), mimeType)
                        
                        val mediaItem = MediaItem(
                            id = id,
                            uri = mediaUri,
                            name = name,
                            type = if (mimeType?.startsWith("image/") == true) "image" else "video",
                            size = size,
                            dateAdded = dateAdded,
                            dateModified = dateModified,
                            width = width,
                            height = height,
                            duration = duration,
                            thumbnailPath = thumbnailPath,
                            metadata = if (includeTrashed) mapOf("deletedAt" to (getTrashedItems()[id] ?: 0L)) else null
                        )
                        mediaList.add(mediaItem)
                        itemsAdded++
                    }
                    currentPosition++
                }
            }
            Result.success(mediaList)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun getAlbums(): Result<List<Album>> = withContext(Dispatchers.IO) {
        try {
            val trashedIds = getTrashedItems().keys
            val hiddenIds = getHiddenItems()
            val excluded = (trashedIds + hiddenIds).joinToString(",")
            val selection = if (excluded.isNotEmpty()) {
                "${MediaStore.MediaColumns._ID} NOT IN ($excluded)"
            } else null

            val bucketCounts = mutableMapOf<String, Int>()
            val bucketCovers = mutableMapOf<String, String?>()
            val bucketLastModified = mutableMapOf<String, Long>()
            val bucketIds = mutableMapOf<String, String>()

            val uris = arrayOf(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            )

            for (uri in uris) {
                val projection = arrayOf(
                    MediaStore.MediaColumns.BUCKET_ID,
                    MediaStore.MediaColumns.BUCKET_DISPLAY_NAME,
                    MediaStore.MediaColumns._ID,
                    MediaStore.MediaColumns.DATE_MODIFIED
                )
                
                context.contentResolver.query(uri, projection, selection, null, null)?.use { cursor ->
                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                    val bucketNameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.BUCKET_DISPLAY_NAME)
                    val bucketIdColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.BUCKET_ID)
                    val dateModifiedColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)

                    while (cursor.moveToNext()) {
                        val bucketName = cursor.getString(bucketNameColumn) ?: "Unknown"
                        val bucketId = cursor.getString(bucketIdColumn)
                        val mediaId = cursor.getLong(idColumn)
                        val dateModified = cursor.getLong(dateModifiedColumn)
                        
                        bucketCounts[bucketName] = bucketCounts.getOrDefault(bucketName, 0) + 1
                        bucketIds[bucketName] = bucketId
                        
                        if (!bucketCovers.containsKey(bucketName)) {
                            bucketCovers[bucketName] = ContentUris.withAppendedId(uri, mediaId).toString()
                        }
                        
                        val currentLast = bucketLastModified.getOrDefault(bucketName, 0L)
                        if (dateModified > currentLast) {
                            bucketLastModified[bucketName] = dateModified
                        }
                    }
                }
            }
            
            val albumList = bucketCounts.map { (name, count) ->
                Album(
                    id = bucketIds[name] ?: name,
                    name = name,
                    type = "system",
                    coverUri = bucketCovers[name],
                    mediaCount = count,
                    lastModified = bucketLastModified[name]
                )
            }.toMutableList()
            
            albumList.addAll(getSpecialAlbums())
            Result.success(albumList)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    private fun getSpecialAlbums(): List<Album> {
        val trashedCount = getTrashedItems().size
        val hiddenCount = getHiddenItems().size
        return listOf(
            Album(id = "-1", name = "Favorites", type = "custom", coverUri = null, mediaCount = 0, lastModified = null),
            Album(id = "-2", name = "Hidden", type = "hidden", coverUri = null, mediaCount = hiddenCount, lastModified = null),
            Album(id = "-3", name = "Recycle Bin", type = "recycle_bin", coverUri = null, mediaCount = trashedCount, lastModified = null),
        )
    }

    suspend fun hideMediaItem(mediaId: Long): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val hidden = getHiddenItems().toMutableSet()
            hidden.add(mediaId)
            saveHiddenItems(hidden)
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun unhideMediaItem(mediaId: Long): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val hidden = getHiddenItems().toMutableSet()
            hidden.remove(mediaId)
            saveHiddenItems(hidden)
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    private fun generateThumbnail(context: Context, uri: Uri, mimeType: String?): String? {
        return try {
            val thumbnailFile = File(context.cacheDir, "thumb_${uri.lastPathSegment?.hashCode()}.jpg")
            if (thumbnailFile.exists()) return thumbnailFile.absolutePath
            
            val bitmap = if (mimeType?.startsWith("image/") == true) {
                context.contentResolver.openInputStream(uri)?.use { input ->
                    BitmapFactory.decodeStream(input, null, BitmapFactory.Options().apply { inSampleSize = 4 })
                }
            } else if (mimeType?.startsWith("video/") == true) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    try { context.contentResolver.loadThumbnail(uri, android.util.Size(512, 512), null) }
                    catch (e: Exception) { null }
                } else {
                    try {
                        val retriever = android.media.MediaMetadataRetriever()
                        retriever.setDataSource(context, uri)
                        retriever.frameAtTime
                    } catch (e: Exception) { null }
                }
            } else null
            
            bitmap?.let { bmp ->
                FileOutputStream(thumbnailFile).use { out -> bmp.compress(Bitmap.CompressFormat.JPEG, 85, out) }
                thumbnailFile.absolutePath
            }
        } catch (e: Exception) { null }
    }
    
    suspend fun moveToRecycleBin(mediaId: Long): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val trashed = getTrashedItems().toMutableMap()
            trashed[mediaId] = System.currentTimeMillis()
            saveTrashedItems(trashed)
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun restoreFromRecycleBin(mediaId: Long): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val trashed = getTrashedItems().toMutableMap()
            trashed.remove(mediaId)
            saveTrashedItems(trashed)
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deletePermanently(mediaId: Long): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val uri = Uri.withAppendedPath(MediaStore.Files.getContentUri("external"), mediaId.toString())
            val deleted = context.contentResolver.delete(uri, null, null) > 0
            if (deleted) {
                val trashed = getTrashedItems().toMutableMap()
                trashed.remove(mediaId)
                saveTrashedItems(trashed)
            }
            Result.success(deleted)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun emptyRecycleBin(): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val trashed = getTrashedItems()
            var allDeleted = true
            trashed.keys.forEach { id ->
                val uri = Uri.withAppendedPath(MediaStore.Files.getContentUri("external"), id.toString())
                if (context.contentResolver.delete(uri, null, null) <= 0) {
                    allDeleted = false
                }
            }
            saveTrashedItems(emptyMap())
            Result.success(allDeleted)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
