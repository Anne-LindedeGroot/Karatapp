# Supabase Setup for Ohyo Feature

## Overview
This document contains the SQL commands to set up the ohyo tables and storage in Supabase, matching the structure of your existing kata tables.

## 1. Ohyo Table
Run this SQL in your Supabase SQL Editor to create the main ohyo table:

```sql
CREATE TABLE ohyo (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  style TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  video_urls TEXT[],
  "order" INTEGER DEFAULT 0
);
```

## 2. Ohyo Comments Table
Run this SQL in your Supabase SQL Editor to create the ohyo comments table:

```sql
CREATE TABLE ohyo_comments (
  id SERIAL PRIMARY KEY,
  ohyo_id INTEGER NOT NULL REFERENCES ohyo(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  author_id TEXT NOT NULL,
  author_name TEXT NOT NULL,
  author_avatar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_ohyo_comments_ohyo_id ON ohyo_comments(ohyo_id);
CREATE INDEX idx_ohyo_comments_created_at ON ohyo_comments(created_at DESC);
```

## 3. Ohyo Images Storage Bucket
Create the storage bucket through the Supabase Dashboard:

1. Go to **Storage** → **Buckets** in your Supabase dashboard
2. Click **"New bucket"**
3. Set bucket name to: `ohyo_images`
4. ✅ Check the **"Public"** checkbox to make it publicly accessible
5. Click **"Create bucket"**

### Storage Bucket Policies
After creating the bucket, you need to set up storage policies. Go to **Storage** → **Policies** in your Supabase dashboard and create these policies for the `ohyo_images` bucket:

```sql
-- Allow everyone to view ohyo images
CREATE POLICY "Anyone can view ohyo images" ON storage.objects
  FOR SELECT USING (bucket_id = 'ohyo_images');

-- Allow authenticated users to upload ohyo images
CREATE POLICY "Authenticated users can upload ohyo images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'ohyo_images'
    AND auth.role() = 'authenticated'
  );

-- Allow authenticated users to update ohyo images
CREATE POLICY "Authenticated users can update ohyo images" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'ohyo_images'
    AND auth.role() = 'authenticated'
  );

-- Allow authenticated users to delete ohyo images
CREATE POLICY "Authenticated users can delete ohyo images" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'ohyo_images'
    AND auth.role() = 'authenticated'
  );
```

## Table Structure Comparison

### Ohyo Table (vs Kata Table)
| Column | Ohyo | Kata | Notes |
|--------|------|------|-------|
| id | SERIAL PRIMARY KEY | SERIAL PRIMARY KEY | Same |
| name | TEXT NOT NULL | TEXT NOT NULL | Same |
| description | TEXT | TEXT | Same |
| category | TEXT | style (TEXT) | Changed from "style" to "category" |
| created_at | TIMESTAMP WITH TIME ZONE DEFAULT NOW() | TIMESTAMP WITH TIME ZONE DEFAULT NOW() | Same |
| video_urls | TEXT[] | TEXT[] | Same |
| order | INTEGER DEFAULT 0 | INTEGER DEFAULT 0 | Same |

### Ohyo Comments Table (vs Kata Comments Table)
| Column | Ohyo Comments | Kata Comments | Notes |
|--------|---------------|---------------|-------|
| id | SERIAL PRIMARY KEY | SERIAL PRIMARY KEY | Same |
| ohyo_id | INTEGER NOT NULL REFERENCES ohyo(id) | kata_id INTEGER NOT NULL REFERENCES katas(id) | Changed reference |
| content | TEXT NOT NULL | TEXT NOT NULL | Same |
| author_id | TEXT NOT NULL | TEXT NOT NULL | Same |
| author_name | TEXT NOT NULL | TEXT NOT NULL | Same |
| author_avatar | TEXT | TEXT | Same |
| created_at | TIMESTAMP WITH TIME ZONE DEFAULT NOW() | TIMESTAMP WITH TIME ZONE DEFAULT NOW() | Same |
| updated_at | TIMESTAMP WITH TIME ZONE DEFAULT NOW() | TIMESTAMP WITH TIME ZONE DEFAULT NOW() | Same |

## Row Level Security (RLS) Policies
You'll also want to set up Row Level Security policies for the ohyo tables. Here are the recommended policies (same as your kata tables):

### For ohyo table:
```sql
-- Enable RLS
ALTER TABLE ohyo ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read ohyo
CREATE POLICY "Anyone can view ohyo" ON ohyo
  FOR SELECT USING (true);

-- Allow authenticated users to create ohyo
CREATE POLICY "Authenticated users can create ohyo" ON ohyo
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to update ohyo
CREATE POLICY "Authenticated users can update ohyo" ON ohyo
  FOR UPDATE USING (auth.role() = 'authenticated');

-- Allow authenticated users to delete ohyo
CREATE POLICY "Authenticated users can delete ohyo" ON ohyo
  FOR DELETE USING (auth.role() = 'authenticated');
```

### For ohyo_comments table:
```sql
-- Enable RLS
ALTER TABLE ohyo_comments ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read comments
CREATE POLICY "Anyone can view ohyo comments" ON ohyo_comments
  FOR SELECT USING (true);

-- Allow authenticated users to create comments
CREATE POLICY "Authenticated users can create ohyo comments" ON ohyo_comments
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to update comments
CREATE POLICY "Authenticated users can update ohyo comments" ON ohyo_comments
  FOR UPDATE USING (auth.role() = 'authenticated');

-- Allow authenticated users to delete comments
CREATE POLICY "Authenticated users can delete ohyo comments" ON ohyo_comments
  FOR DELETE USING (auth.role() = 'authenticated');
```

## Next Steps
1. Run the SQL commands in your Supabase SQL Editor
2. Create the `ohyo_images` storage bucket
3. Set up RLS policies if needed
4. Test the ohyo functionality in your app

Your ohyo feature should now be fully functional with the same capabilities as your kata feature!</contents>
</xai:function_call">Create the documentation file with complete setup instructions
