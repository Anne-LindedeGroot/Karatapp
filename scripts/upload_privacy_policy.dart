import 'dart:io';

import 'package:supabase/supabase.dart';

Future<void> main() async {
  final env = _loadEnv(File('.env'));
  final supabaseUrl = env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] ?? '';
  final supabaseServiceRoleKey = env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  if (supabaseUrl.isEmpty || (supabaseAnonKey.isEmpty && supabaseServiceRoleKey.isEmpty)) {
    stderr.writeln('Missing SUPABASE_URL or SUPABASE_ANON_KEY/SUPABASE_SERVICE_ROLE_KEY in .env');
    exitCode = 1;
    return;
  }

  const bucketName = 'privacy_policy';
  const objectPath = 'privacy_policy_v2.html';
  const localFilePath = 'scripts/privacy_policy.html';

  final file = File(localFilePath);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $localFilePath');
    exitCode = 1;
    return;
  }

  final apiKey = supabaseServiceRoleKey.isNotEmpty ? supabaseServiceRoleKey : supabaseAnonKey;
  final client = SupabaseClient(supabaseUrl, apiKey);
  if (supabaseServiceRoleKey.isNotEmpty) {
    stdout.writeln('Using SUPABASE_SERVICE_ROLE_KEY for upload.');
  } else {
    stdout.writeln('Using SUPABASE_ANON_KEY for upload.');
  }

  try {
    if (supabaseServiceRoleKey.isNotEmpty) {
      final buckets = await client.storage.listBuckets();
      final hasBucket = buckets.any((bucket) => bucket.id == bucketName);
      if (!hasBucket) {
        stderr.writeln('Bucket not found: $bucketName');
        stderr.writeln('Create it in Supabase Storage and make it public.');
        exitCode = 1;
        return;
      }
    } else {
      stdout.writeln(
        'Skipping bucket existence check (anon key cannot list buckets).',
      );
    }

    final bytes = await file.readAsBytes();
    await client.storage.from(bucketName).uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'text/html',
            cacheControl: 'no-store',
            upsert: true,
          ),
        );

    final publicUrl = client.storage.from(bucketName).getPublicUrl(objectPath);
    stdout.writeln('Uploaded privacy policy to: $publicUrl');
  } catch (e) {
    stderr.writeln('Upload failed: $e');
    stderr.writeln('Make sure the bucket "$bucketName" exists and is public.');
    exitCode = 1;
  }
}

Map<String, String> _loadEnv(File file) {
  if (!file.existsSync()) {
    return {};
  }
  final map = <String, String>{};
  for (final rawLine in file.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final index = line.indexOf('=');
    if (index <= 0) {
      continue;
    }
    final key = line.substring(0, index).trim();
    final value = line.substring(index + 1).trim();
    map[key] = value;
  }
  return map;
}
