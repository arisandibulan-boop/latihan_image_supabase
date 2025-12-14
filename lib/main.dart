import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const SupabaseUrl = 'https://mtjpgthpfealtbupwgfm.supabase.co';
const SupabaseAnonKey = 'sb_publishable_O2hXXaFf9Pv62u4oBUZnWg_AXLSiY7v';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SupabaseUrl, anonKey: SupabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, super

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'supabase foto', home: MyHomePage());
  }
}
