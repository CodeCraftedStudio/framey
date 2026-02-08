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
    
    suspend fun getMediaItems(
        albumId: String? = null,
        mediaType: String? = null,
        limit: Int = 50,
        offset: Int = 0
    ): Result<List<MediaItem>> = withContext(Dispatchers.IO) {
        try {
            val mediaList = mutableListOf<MediaItem>()
            val selection = StringBuilder()
            val selectionArgs = mutableListOf<String>()
            
            android.util.Log.d("Framey", "Getting media items: albumId=$albumId, mediaType=$mediaType, limit=$limit, offset=$offset")
            
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
            
            // Query only valid columns required by the app
            val projection = arrayOf(
                MediaStore.MediaColumns._ID,
                MediaStore.MediaColumns.DISPLAY_NAME,
                MediaStore.MediaColumns.MIME_TYPE,
                MediaStore.MediaColumns.SIZE,
                MediaStore.MediaColumns.DATE_ADDED,
                MediaStore.MediaColumns.DATE_MODIFIED,
                MediaStore.MediaColumns.WIDTH,
                MediaStore.MediaColumns.HEIGHT,
                MediaStore.MediaColumns.DURATION
            )
            
            // Use proper Android MediaStore sort order without SQL LIMIT syntax
            val sortOrder = "${MediaStore.MediaColumns.DATE_ADDED} DESC"
            
            // Query MediaStore.Files for both images and videos
            val contentUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Files.getContentUri("external")
            } else {
                MediaStore.Files.getContentUri("external")
            }
            
            val query = context.contentResolver.query(
                contentUri,
                projection,
                selection.toString().takeIf { it.isNotEmpty() },
                selectionArgs.takeIf { it.isNotEmpty() }?.toTypedArray(),
                sortOrder
            )
            
            query?.use { cursor ->
                android.util.Log.d("Framey", "Cursor count: ${cursor.count}")
                
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
                val mimeTypeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
                val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                val dateAddedColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_ADDED)
                val dateModifiedColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
                val widthColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.WIDTH)
                val heightColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.HEIGHT)
                val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DURATION)
                
                // Apply offset and limit manually to avoid SQL injection
                var currentPosition = 0
                var itemsAdded = 0
                
                while (cursor.moveToNext() && itemsAdded < limit) {
                    if (currentPosition >= offset) {
                        val id = cursor.getLong(idColumn)
                        val name = cursor.getString(nameColumn)
                        val mimeType = cursor.getString(mimeTypeColumn)
                        val size = cursor.getLong(sizeColumn)
                        val dateAdded = cursor.getLong(dateAddedColumn)
                        val dateModified = cursor.getLong(dateModifiedColumn)
                        
                        // Handle nullable columns safely
                        val width = if (cursor.isNull(widthColumn)) null else cursor.getLong(widthColumn).toInt()
                        val height = if (cursor.isNull(heightColumn)) null else cursor.getLong(heightColumn).toInt()
                        val duration = if (cursor.isNull(durationColumn)) null else cursor.getLong(durationColumn).toInt()
                        
                        // Create proper content URI
                        val contentUri = Uri.withAppendedPath(
                            MediaStore.Files.getContentUri("external"),
                            id.toString()
                        )
                        
                        val thumbnailPath = generateThumbnail(context, contentUri, mimeType)
                        
                        val mediaItem = MediaItem(
                            id = id,
                            uri = contentUri.toString(),
                            name = name,
                            type = if (mimeType.startsWith("image/")) "image" else "video",
                            size = size,
                            dateAdded = dateAdded,
                            dateModified = dateModified,
                            width = width,
                            height = height,
                            duration = duration,
                            thumbnailPath = thumbnailPath
                        )
                        
                        mediaList.add(mediaItem)
                        itemsAdded++
                    }
                    currentPosition++
                }
            }
            
            android.util.Log.d("Framey", "Returning ${mediaList.size} media items")
            Result.success(mediaList)
        } catch (e: Exception) {
            android.util.Log.e("Framey", "Error getting media items", e)
            Result.failure(e)
        }
    }
    
    suspend fun getAlbums(): Result<List<Album>> = withContext(Dispatchers.IO) {
        try {
            val albumList = mutableListOf<Album>()
            
            // Get system albums
            val projection = arrayOf(
                MediaStore.Images.Media.BUCKET_ID,
                MediaStore.Images.Media.BUCKET_DISPLAY_NAME,
                MediaStore.Images.Media._ID
            )
            
            val query = context.contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                "${MediaStore.Images.Media.BUCKET_DISPLAY_NAME}"
            )
            
            // Group by bucket and count manually
            val bucketCounts = mutableMapOf<String, Int>()
            query?.use { cursor ->
                val bucketIdColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_ID)
                val bucketNameColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME)
                
                while (cursor.moveToNext()) {
                    val bucketName = cursor.getString(bucketNameColumn) ?: "Unknown"
                    bucketCounts[bucketName] = bucketCounts.getOrDefault(bucketName, 0) + 1
                }
            }
            
            // Create albums from grouped data
            bucketCounts.forEach { (bucketName, count) ->
                val album = Album(
                    id = bucketName, // Use bucket name as ID
                    name = bucketName,
                    type = "system",
                    coverUri = null, // TODO: Get cover image
                    mediaCount = count,
                    lastModified = null,
                    metadata = null
                )
                albumList.add(album)
            }
            
            // Add special albums
            albumList.addAll(getSpecialAlbums())
            
            Result.success(albumList)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    private fun getSpecialAlbums(): List<Album> {
        return listOf(
            Album(
                id = "-1",
                name = "Favorites",
                type = "custom",
                coverUri = null,
                mediaCount = 0,
                lastModified = null,
                metadata = null
            ),
            Album(
                id = "-2",
                name = "Hidden",
                type = "hidden",
                coverUri = null,
                mediaCount = 0,
                lastModified = null,
                metadata = null
            ),
            Album(
                id = "-3",
                name = "Recycle Bin",
                type = "recycle_bin",
                coverUri = null,
                mediaCount = 0,
                lastModified = null,
                metadata = null
            ),
        )
    }
    
    private fun generateThumbnail(context: Context, uri: Uri, mimeType: String?): String? {
        return try {
            val thumbnailFile = File(context.cacheDir, "thumb_${uri.lastPathSegment?.hashCode()}.jpg")
            
            if (thumbnailFile.exists()) {
                thumbnailFile.absolutePath
            } else {
                val bitmap = if (mimeType?.startsWith("image/") == true) {
                    // Generate image thumbnail
                    context.contentResolver.openInputStream(uri)?.use { input ->
                        BitmapFactory.decodeStream(input, null, BitmapFactory.Options().apply {
                            inSampleSize = 4 // Better thumbnail quality
                        })
                    }
                } else if (mimeType?.startsWith("video/") == true) {
                    // Generate video thumbnail
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        try {
                            // Android Q+ thumbnail extraction
                            val size = android.util.Size(512, 512)
                            context.contentResolver.loadThumbnail(uri, size, null)
                        } catch (e: Exception) {
                            android.util.Log.w("Framey", "Failed to load video thumbnail", e)
                            null
                        }
                    } else {
                        // Fallback for older Android versions
                        try {
                            val retriever = android.media.MediaMetadataRetriever()
                            retriever.setDataSource(context, uri)
                            retriever.frameAtTime
                        } catch (e: Exception) {
                            android.util.Log.w("Framey", "Failed to extract video frame", e)
                            null
                        }
                    }
                } else {
                    null
                }
                
                bitmap?.let { bmp ->
                    FileOutputStream(thumbnailFile).use { out ->
                        bmp.compress(Bitmap.CompressFormat.JPEG, 85, out)
                    }
                    thumbnailFile.absolutePath
                } ?: run {
                    android.util.Log.w("Framey", "Failed to generate thumbnail for $uri")
                    null
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("Framey", "Error generating thumbnail", e)
            null
        }
    }
    
    suspend fun deleteMediaItem(mediaId: Long): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val uri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, mediaId.toString())
            val deleted = context.contentResolver.delete(uri, null, null) > 0
            Result.success(deleted)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun moveToRecycleBin(mediaId: Long): Result<Boolean> {
        // TODO: Implement soft delete logic
        return deleteMediaItem(mediaId)
    }
    
    suspend fun restoreFromRecycleBin(mediaId: Long): Result<Boolean> {
        // TODO: Implement restore logic
        return Result.success(true)
    }
}
