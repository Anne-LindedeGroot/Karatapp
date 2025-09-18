# Video Implementation Guide for Karate Flutter App

This guide provides detailed steps to complete the video implementation for your karate app.

## ✅ Already Completed

1. **Kata Model Updated** - Added `videoUrls` field
2. **Video Player Widget** - Full-featured video player with controls
3. **Media Gallery** - Combined image and video gallery
4. **Video Service** - Complete video storage service
5. **Video Provider** - State management for videos
6. **Dependencies Added** - `video_player` and `chewie` packages

## 🔧 Step 3: Storage Setup (Supabase)

### 3.1 Create Video Storage Bucket

1. **Go to your Supabase Dashboard**
   - Navigate to Storage → Buckets
   - Click "New bucket"
   - Name: `kata_videos`
   - Make it **Private** ✅ (NOT public for better security)
   - Set file size limit: `52428800` (50MB)
   - Allowed MIME types: `video/*`
   - Click "Create bucket"

### 3.2 Set Up Storage Policies (RLS)

Add these policies in Supabase Dashboard → Storage → Policies:

```sql
-- Policy 1: Allow authenticated users to upload videos
CREATE POLICY "Allow authenticated uploads to kata_videos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'kata_videos' 
  AND auth.role() = 'authenticated'
);

-- Policy 2: Allow authenticated users to read videos (private access)
CREATE POLICY "Allow authenticated read access to kata_videos" ON storage.objects
FOR SELECT USING (
  bucket_id = 'kata_videos' 
  AND auth.role() = 'authenticated'
);

-- Policy 3: Allow authenticated users to delete videos
CREATE POLICY "Allow authenticated delete from kata_videos" ON storage.objects
FOR DELETE USING (
  bucket_id = 'kata_videos' 
  AND auth.role() = 'authenticated'
);

-- Policy 4: Allow authenticated users to update videos
CREATE POLICY "Allow authenticated update to kata_videos" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'kata_videos' 
  AND auth.role() = 'authenticated'
);
```

**Note**: Since the bucket is private, videos will be accessed via signed URLs that expire after a set time (2 hours by default), providing better security than public access.

### 3.3 Update Database Schema

Add the video URLs column to your kata table:

```sql
-- Add video_urls column to katas table
ALTER TABLE katas ADD COLUMN video_urls TEXT[];

-- Update existing katas to have empty video arrays (optional)
UPDATE katas SET video_urls = '{}' WHERE video_urls IS NULL;

-- OPTIONAL: Add index for better performance (only if you plan advanced video searches)
-- CREATE INDEX idx_katas_video_urls ON katas USING GIN(video_urls);
-- 
-- What this index does:
-- - Speeds up queries that search INSIDE the video_urls array
-- - Example: "Find all katas that contain a specific video URL"
-- - Uses GIN (Generalized Inverted Index) for array operations
-- 
-- Do you need it?
-- - NO for basic usage (just storing/retrieving videos per kata)
-- - YES if you plan to search across video URLs later
-- - Takes up extra storage space (~10-20% more)
-- 
-- You can always add it later if needed:
-- CREATE INDEX idx_katas_video_urls ON katas USING GIN(video_urls);
```

## 🚀 Step 4: Video Upload Integration

### 4.1 Update Your Kata Provider

Add video loading to your existing kata provider:

```dart
// In lib/providers/kata_provider.dart
import '../providers/video_provider.dart';

// Add this method to your KataNotifier class
Future<void> loadKataMedia(int kataId) async {
  // Load both images and videos
  await Future.wait([
    ref.read(imageNotifierProvider.notifier).loadKataImages(kataId),
    ref.read(videoNotifierProvider.notifier).loadKataVideos(kataId),
  ]);
}
```

### 4.2 Update Edit Kata Screen

Add video upload functionality to your edit kata screen:

```dart
// In lib/screens/edit_kata_screen.dart
import '../providers/video_provider.dart';
import '../services/video_service.dart';
import '../utils/video_utils.dart';

// Add these methods to your EditKataScreen state class:

Future<void> _pickAndUploadVideo() async {
  try {
    final videoFile = await VideoService.pickVideoFromGallery();
    if (videoFile != null) {
      await ref.read(videoNotifierProvider.notifier)
          .uploadVideos([videoFile], widget.kata.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error uploading video: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _recordAndUploadVideo() async {
  try {
    final videoFile = await VideoService.recordVideoWithCamera();
    if (videoFile != null) {
      await ref.read(videoNotifierProvider.notifier)
          .uploadVideos([videoFile], widget.kata.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video recorded and uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error recording video: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Add video upload buttons to your UI:
Widget _buildVideoUploadSection() {
  return Consumer(
    builder: (context, ref, child) {
      final isUploading = ref.watch(isUploadingVideosProvider(widget.kata.id));
      final videos = ref.watch(cachedKataVideosProvider(widget.kata.id));
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Videos (${videos.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          // Upload buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isUploading ? null : _pickAndUploadVideo,
                icon: const Icon(Icons.video_library),
                label: const Text('Pick Video'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isUploading ? null : _recordAndUploadVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('Record Video'),
              ),
            ],
          ),
          
          if (isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          
          // Video list
          if (videos.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...videos.map((videoUrl) => _buildVideoItem(videoUrl)),
          ],
        ],
      );
    },
  );
}

Widget _buildVideoItem(String videoUrl) {
  return Card(
    child: ListTile(
      leading: VideoThumbnail(
        videoUrl: videoUrl,
        width: 60,
        height: 40,
      ),
      title: Text(VideoService.extractFileNameFromUrl(videoUrl) ?? 'Video'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteVideo(videoUrl),
      ),
      onTap: () => _playVideo(videoUrl),
    ),
  );
}

Future<void> _deleteVideo(String videoUrl) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Video?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await ref.read(videoNotifierProvider.notifier)
          .deleteVideo(videoUrl, widget.kata.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void _playVideo(String videoUrl) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Video Player')),
        body: VideoPlayerWidget(
          videoUrl: videoUrl,
          showControls: true,
          autoPlay: true,
        ),
      ),
    ),
  );
}
```

### 4.3 Update Kata Card Media Loading

Update your kata card to load videos:

```dart
// In lib/widgets/collapsible_kata_card.dart
// Add this to your _buildMediaSection method:

// Load videos if not cached and not loading
WidgetsBinding.instance.addPostFrameCallback((_) {
  ref.read(imageNotifierProvider.notifier).loadKataImages(kata.id);
  ref.read(videoNotifierProvider.notifier).loadKataVideos(kata.id);
});
```

## 📱 Step 5: Testing Your Implementation

### 5.1 Install Dependencies

```bash
flutter pub get
```

### 5.2 Test Video Upload

1. Run your app: `flutter run`
2. Navigate to edit kata screen
3. Try uploading a video from gallery
4. Try recording a video with camera
5. Verify videos appear in the kata card

### 5.3 Test Video Playback

1. Tap on a kata card with videos
2. Verify the media gallery opens
3. Test video playback controls
4. Test switching between images and videos

## 🔧 Troubleshooting

### Common Issues:

1. **"Bucket not found" error**
   - Ensure you created the `kata_videos` bucket in Supabase
   - Make sure it's set to private with proper RLS policies

2. **"Access denied" error**
   - Check your RLS policies are correctly set up
   - Ensure user is authenticated

3. **Video won't play**
   - Check video format is supported (MP4, MOV, etc.)
   - Verify video URL is accessible
   - Check video file size (max 50MB)

4. **Upload fails**
   - Check internet connection
   - Verify video file isn't corrupted
   - Check file size limits (50MB max)

5. **"Exceeds global limit" error**
   - This is normal - 50MB is the Supabase free tier limit
   - Your app is correctly configured for 50MB
   - No action needed unless you want to upgrade your Supabase plan

### Debug Commands:

```bash
# Check for compilation errors
flutter analyze

# Run with verbose logging
flutter run --verbose

# Check dependencies
flutter pub deps
```

## 🎯 Next Steps (Optional Enhancements)

1. **Video Compression**: Add video compression before upload
2. **Thumbnail Generation**: Generate video thumbnails server-side
3. **Progress Indicators**: Show upload progress for large videos
4. **Video Metadata**: Store and display video duration, resolution
5. **Streaming**: Implement adaptive streaming for better performance

## 📋 Checklist

- [ ] Created `kata_videos` bucket in Supabase
- [ ] Set up storage policies (RLS)
- [ ] Updated database schema with `video_urls` column
- [ ] Added video upload functionality to edit kata screen
- [ ] Updated kata card to load videos
- [ ] Tested video upload from gallery
- [ ] Tested video recording with camera
- [ ] Tested video playback in media gallery
- [ ] Verified error handling works correctly

## 🎉 Completion

Once you've completed all steps, your karate app will support:

- ✅ Image and video uploads
- ✅ Smart media preview in kata cards
- ✅ Combined media gallery with tabs
- ✅ Video playback with controls
- ✅ Error handling and retry mechanisms
- ✅ Proper storage organization by kata ID

Your users can now upload both images for quick reference and videos for complete kata demonstrations!
