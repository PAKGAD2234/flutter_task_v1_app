import 'package:flutter/material.dart';
import 'package:flutter_task_v1_app/views/splash_screen_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


// --------------------------------
void main() async {
  // ----ตั้งค่าการใช้งาน supabase ที่จะทำงาน----
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ujoqexbpwijwhwshrghx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqb3FleGJwd2lqd2h3c2hyZ2h4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1NjkwNDUsImV4cCI6MjA5MTE0NTA0NX0.nKt_Y1aCbKDVJdnlBaWhW9oJyqQ_bDHSeLjjeE3lIzo',
  );

  runApp(
    FlutterTaskV1App(),
  );
}

class FlutterTaskV1App extends StatefulWidget {
  const FlutterTaskV1App({super.key});

  @override
  State<FlutterTaskV1App> createState() => _FlutterTaskV1AppState();
}

class _FlutterTaskV1AppState extends State<FlutterTaskV1App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreenUi(),
      theme: ThemeData(
        textTheme: GoogleFonts.kanitTextTheme(
          Theme.of(context).textTheme
        ),
      ),
    );
  }
}