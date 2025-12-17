import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/models/kata_model.dart';
import 'lib/models/ohyo_model.dart';

void main() async {
  print("Testing offline cache functionality...");
  
  final prefs = await SharedPreferences.getInstance();
  
  // Check for cached katas
  final cachedKatasJson = prefs.getString('cached_katas');
  if (cachedKatasJson != null) {
    try {
      final kataMaps = jsonDecode(cachedKatasJson) as List;
      final katas = kataMaps.map((map) => Kata.fromMap(map)).toList();
      print("✅ Found ${katas.length} cached katas");
      print("📅 Cache timestamp: ${prefs.getString('katas_last_updated')}");
    } catch (e) {
      print("❌ Error reading cached katas: $e");
    }
  } else {
    print("ℹ️  No cached katas found");
  }
  
  // Check for cached ohyos
  final cachedOhyosJson = prefs.getString('cached_ohyos');
  if (cachedOhyosJson != null) {
    try {
      final ohyoMaps = jsonDecode(cachedOhyosJson) as List;
      final ohyos = ohyoMaps.map((map) => Ohyo.fromMap(map)).toList();
      print("✅ Found ${ohyos.length} cached ohyos");
      print("📅 Cache timestamp: ${prefs.getString('ohyos_last_updated')}");
    } catch (e) {
      print("❌ Error reading cached ohyos: $e");
    }
  } else {
    print("ℹ️  No cached ohyos found");
  }
  
  print("Offline cache test completed.");
}
