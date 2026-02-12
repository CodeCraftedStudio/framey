package com.framey.gallery

import android.content.Context
import android.content.ContentUris
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

            val trashIds = getTrashedItems().keys
            val hidIds = getHiddenItems()

            val selection = StringBuilder()
            val selectionArgs = mutableListOf<String>()

            // 1. Core Filter: Only images and videos
            selection.append("(${MediaStore.Files.FileColumns.MEDIA_TYPE}=? OR ${MediaStore.Files.FileColumns.MEDIA_TYPE}=?)")
            selectionArgs.add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString())
            selectionArgs.add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())

            // 2. Trash/Hidden Filters
            if (includeTrashed) {
                if (trashIds.isNotEmpty()) {
                    selection.append(" AND ${MediaStore.MediaColumns._ID} IN (${trashIds.joinToString(",")})")
                } else {
                    return@withContext Result.success(emptyList<MediaItem>()) // No trashed items exist
                }
            } else if (includeHidden) {
                if (hidIds.isNotEmpty()) {
                    selection.append(" AND ${MediaStore.MediaColumns._ID} IN (${hidIds.joinToString(",")})")
                } else {
                    return@withContext Result.success(emptyList<MediaItem>()) // No hidden items exist
                }
            } else {
                // Regular view: exclude both
                if (trashIds.isNotEmpty()) {
                    selection.append(" AND ${MediaStore.MediaColumns._ID} NOT IN (${trashIds.joinToString(",")})")
                }
                if (hidIds.isNotEmpty()) {
                    selection.append(" AND ${MediaStore.MediaColumns._ID} NOT IN (${hidIds.joinToString(",")})")
                }
            }

            // 3. Album Filter
            if (albumId != null && albumId != "-1" && albumId != "-2" && albumId != "-3") {
                selection.append(" AND ${MediaStore.MediaColumns.BUCKET_ID} = ?")
                selectionArgs.add(albumId)
            }

            // 4. Media Type Filter (Override)
            if (mediaType != null) {
                selection.append(" AND ${MediaStore.MediaColumns.MIME_TYPE} LIKE ?")
                selectionArgs.add("${mediaType.lowercase()}/%")
            }

            // 5. Search Filter
            if (searchQuery != null && searchQuery.isNotEmpty()) {
                selection.append(" AND ${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?")
                selectionArgs.add("%$searchQuery%")
            }

            val queryUri = MediaStore.Files.getContentUri("external")
            val sortOrder = "${MediaStore.MediaColumns.DATE_ADDED} DESC"

            context.contentResolver.query(
                queryUri,
                projection,
                selection.toString(),
                selectionArgs.toTypedArray(),
                sortOrder
            )?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val nameCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
                val mimeCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
                val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                val addedCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_ADDED)
                val modifiedCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
                val wCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.WIDTH)
                val hCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.HEIGHT)
                val dCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DURATION)

                var processedItems = 0
                var currentPos = 0

                while (cursor.moveToNext()) {
                    if (currentPos >= offset && processedItems < limit) {
                        val id = cursor.getLong(idCol)
                        val mime = cursor.getString(mimeCol)
                        
                        val baseUri = if (mime?.startsWith("video/") == true) {
                            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                        } else {
                            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                        }
                        
                        mediaList.add(MediaItem(
                            id = id,
                            uri = ContentUris.withAppendedId(baseUri, id).toString(),
                            name = cursor.getString(nameCol),
                            type = if (mime?.startsWith("video/") == true) "video" else "image",
                            size = cursor.getLong(sizeCol),
                            dateAdded = cursor.getLong(addedCol),
                            dateModified = cursor.getLong(modifiedCol),
                            width = if (cursor.isNull(wCol)) null else cursor.getInt(wCol),
                            height = if (cursor.isNull(hCol)) null else cursor.getInt(hCol),
                            duration = if (cursor.isNull(dCol)) null else cursor.getInt(dCol),
                            thumbnailPath = generateThumbnail(context, ContentUris.withAppendedId(baseUri, id), mime),
                            metadata = if (includeTrashed) mapOf("deletedAt" to (getTrashedItems()[id] ?: 0L)) else null
                        ))
                        processedItems++
                    }
                    currentPos++
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
            val bucketNames = mutableMapOf<String, String>()

            val uris = arrayOf(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            )

            for (uri in uris) {
                val projection = arrayOf(
                    MediaStore.MediaColumns.BUCKET_ID,
                    MediaStore.MediaColumns.BUCKET_DISPLAY_NAME,
                    MediaStore.MediaColumns._ID,
                    MediaStore.MediaColumns.DATE_MODIFIED,
                    MediaStore.MediaColumns.DATA
                )
                
                context.contentResolver.query(uri, projection, selection, null, null)?.use { cursor ->
                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                    val bucketNameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.BUCKET_DISPLAY_NAME)
                    val bucketIdColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.BUCKET_ID)
                    val dateModifiedColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
                    val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)

                    while (cursor.moveToNext()) {
                        val bucketId = cursor.getString(bucketIdColumn) ?: "Unknown"
                        val bucketName = cursor.getString(bucketNameColumn) ?: "Unknown"
                        val mediaId = cursor.getLong(idColumn)
                        val dateModified = cursor.getLong(dateModifiedColumn)
                        val dataPath = cursor.getString(dataColumn)
                        
                        bucketCounts[bucketId] = bucketCounts.getOrDefault(bucketId, 0) + 1
                        bucketNames[bucketId] = bucketName
                        
                        if (!bucketCovers.containsKey(bucketId)) {
                            bucketCovers[bucketId] = dataPath ?: ContentUris.withAppendedId(uri, mediaId).toString()
                        }
                        
                        val currentLast = bucketLastModified.getOrDefault(bucketId, 0L)
                        if (dateModified > currentLast) {
                            bucketLastModified[bucketId] = dateModified
                        }
                    }
                }
            }
            
            val albumList = bucketCounts.map { (id, count) ->
                Album(
                    id = id,
                    name = bucketNames[id] ?: "Unknown",
                    type = "system",
                    coverUri = bucketCovers[id],
                    mediaCount = count,
                    lastModified = bucketLastModified[id]
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
