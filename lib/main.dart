import 'firebase_options.dart';
import 'pages/user/user_home.dart';
import 'pages/auth/login_page.dart';
import 'services/auth_service.dart';
import 'pages/admin/admin_home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const RootApp(),
    );
  }
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 1,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 1,
            ),
          ),
          home: const RootRouter(),
          routes: {
            "/user": (_) => const UserHome(),
            "/admin": (_) => const AdminHome(),
          },
        );
      },
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    return StreamBuilder<AuthState>(
      stream: auth.authState,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final state = snapshot.data!;
        if (!state.signedIn) {
          return const LoginPage();
        }
        if (state.isAdmin) {
          return const AdminHome();
        } else {
          return const UserHome();
        }
      },
    );
  }
}
