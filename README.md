# Flutter App with Supabase Integration

This Flutter app demonstrates how to integrate Supabase into a Flutter application, including authentication and database functionality.

## Features

- Supabase client setup
- User authentication (sign up, sign in, sign out)
- Database operations (CRUD)
- Real-time data updates

## Setup Instructions

### 1. Create a Supabase Project

1. Go to [https://app.supabase.com/](https://app.supabase.com/)
2. Create a new project or select an existing one
3. In the project dashboard, find "Project Settings" -> "API"
4. Copy the "Project URL" and "anon public" key

### 2. Configure Supabase in the App

1. Open `lib/supabase_client.dart`
2. Replace `YOUR_SUPABASE_URL` with your actual Supabase Project URL
3. Replace `YOUR_SUPABASE_ANON_KEY` with your actual Supabase anon key

### 3. Set up Database Tables

1. Go to the Supabase dashboard
2. Navigate to "Table Editor"
3. Create a table named "Katas" with the following columns:
   - id (int8, primary key)
   - name (text)
   - description (text)
   - style (text, optional)
   - photos (text, optional)
4. Update the table name in `lib/screens/home_screen.dart` in the `_loadData` method if needed

### 4. Set up Storage Bucket

1. Go to the Supabase dashboard
2. Navigate to "Storage"
3. Click "Create Bucket"
4. Name it `kata_images`
5. Set it as "Public"
6. Click "Create bucket"

### 5. Run the App

```bash
flutter pub get
flutter run
```

## Project Structure

```
├── docs/                     # Documentation files
│   ├── README.md            # Documentation index
│   ├── HOST_SETUP_INSTRUCTIONS.md
│   ├── KATAS_RLS_IMPLEMENTATION_GUIDE.md
│   └── ... (other guides)
├── database/                 # SQL scripts and database files
│   ├── README.md            # Database documentation
│   ├── supabase_forum_tables.sql
│   ├── supabase_katas_table.sql
│   └── ... (other SQL files)
├── lib/                     # Main application code
│   ├── main.dart            # App entry point
│   ├── supabase_client.dart # Supabase client configuration
│   ├── models/              # Data models
│   ├── providers/           # State management
│   ├── screens/             # UI screens
│   ├── services/            # Business logic services
│   ├── utils/               # Utility functions
│   └── widgets/             # Reusable UI components
├── test/                    # Test files
├── assets/                  # Static assets (images, etc.)
└── README.md               # This file
```

## Dependencies

- `supabase: ^2.8.0` - Supabase client for Flutter
- `flutter: sdk: flutter` - Flutter SDK

## Usage

1. Launch the app
2. Sign up for a new account or sign in with existing credentials
3. After signing in, you can load data from your Supabase database
4. Sign out when finished

## Next Steps

To extend this app, you can:

1. Add more database operations
2. Implement real-time subscriptions
3. Add more screens for specific features
4. Implement password reset functionality
5. Add email verification flows

## examples

// Update Choin no kata ipone with images
await Supabase.instance.client.from("Katas").update({
"description": "Je zegt je kata naam dus in dit geval Choin no kata ipone dan buig je en ga je in Yoi staan. Dan wacht je tot je Its hoort en mag je beginnen. Je begint links met een lage wering daarna stap je in en maak je een gelijkwaardige stoot. Daarna draai je 360 graden naar rechts en weer je met een lage wering. Stap je in met een stoot. Dan draai je 90 graden en kom je in het midden uit met een lage wering. Dan 3 hoge weringen. Daarna draai je schuin 90 graden/kwartslag naar links met een lage wering. Stap je in met een stoot. Daarna draai je schuin een kwartslag naar rechts met een lage wering. Stap je in met een stoot. Daarna draai je een kwartslag en kom je uit in het midden met een lage wering. Daarna 3 keer een gelijkwaardige stoot. Dan draai je schuin een kwartslag naar links met een lage wering, en stap je in met een stoot. Daarna draai je schuin een kwartslag naar rechts met een lage wering. Stap je in met een stoot. Daarna draai je een kwartslag en kom je uit in het midden met een lage wering. Daarna 3 keer een gelijkwaardige stoot.",
"photos": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT1v7itIMkaVdYMEMXIdNJVXsDbTvkTnxeHSnrkmwFBPSqGtD8Z_NcTB4UMUj5lwxrBBBU&usqp=CAU,https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ1i9QzYvXzXvJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQ&usqp=CAU",
"style": "Wado Ryu"
}).eq('name', 'Choin no kata ipone');

 // Update Pinan nidan       
 await Supabase.instance.client.from("Katas").update({
"description": "Tweede kata in de Pinan reeks",
"photos": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT1v7itIMkaVdYMEMXIdNJVXsDbTvkTnxeHSnrkmwFBPSqGtD8Z_NcTB4UMUj5lwxrBBBU&usqp=CAU,https://encrypted-tbn0.gstatic.com/ images?q=tbn:ANd9GcQ1i9QzYvXzXvJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQ&usqp=CAU",        
}).eq('name', 'Pinan nidan');
      
// Update Pinan shodan
await Supabase.instance.client.from("Katas").update({         
"description": "Eerste kata in de Pinan reeks",
"photos": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT1v7itIMkaVdYMEMXIdNJVXsDbTvkTnxeHSnrkmwFBPSqGtD8Z_NcTB4UMUj5lwxrBBBU&usqp=CAU,https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ1i9QzYvXzXvJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQyJQ&usqp=CAU,https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT1v7itIMkaVdYMEMXIdNJVXsDbTvkTnxeHSnrkmwFBPSqGtD8Z_NcTB4UMUj5lwxrBBBU&usqp=CAU",
         "style": "Wado Ryu"
}).eq('name', 'Pinan shodan');

// Add a small delay to ensure updates are processed
await Future.delayed(const Duration(seconds: 1));
// Reload data
_loadKatas();

## scripts

# List storage buckets
cd scripts && dart run list_buckets.dart

# Analyze katas data
cd scripts && dart run analyze_katas.dart

# Check storage access
cd scripts && dart run check_storage.dart

# Move images to storage (when ready)
cd scripts && dart run move_images_to_storage.dart

# run manual cleanup using the test app we created
flutter run test_orphaned_images_cleanup.dart
