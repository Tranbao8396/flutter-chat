import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:multi_message/models/chat_screen_model.dart';
import 'package:multi_message/screens/chat_screen.dart';
import 'package:multi_message/screens/home_screen.dart';
import 'package:multi_message/screens/login_screen.dart';
import 'package:multi_message/screens/sign_up_screen.dart';
import 'package:multi_message/services/authentication.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as ChatScreenModel;
          return MaterialPageRoute(
            builder: (context) {
              return ChatScreen(
                receiverEmail: args.email,
                receiverUserId: args.userId,
                receiveruserName: args.userName,
              );
            },
          );
        }
        return null;
      },
      routes: {
        '/': (context) => FlutterSplashScreen.fadeIn(
              childWidget: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Messenger',
                    style: GoogleFonts.poppins(
                      fontSize: 36.0,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ".",
                    style: GoogleFonts.poppins(
                      fontSize: 36.0,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              useImmersiveMode: true,
              nextScreen: Authentication.isLoggedIn()
                  ? const HomeScreen()
                  : LoginScreen(),
              backgroundColor: Theme.of(context).primaryColor,
            ),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => const HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Messenger',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color.fromARGB(255, 58, 58, 58),
          onPrimary: Colors.white,
          secondary: Colors.white,
          onSecondary: const Color.fromARGB(255, 37, 37, 37),
          primaryContainer: Colors.blue,
          onPrimaryContainer: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}