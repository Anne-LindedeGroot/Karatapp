-- Ohyo Images Storage Policies
-- Run these commands in your Supabase SQL Editor

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
