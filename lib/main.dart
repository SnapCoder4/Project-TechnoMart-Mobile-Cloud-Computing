import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'pages/auth/login_page.dart';
import 'pages/admin/admin_home.dart';
import 'pages/user/user_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Technomart',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF020617),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF020617),
            elevation: 0,
          ),
          useMaterial3: false,
        ),
        home: RootRouter(),
        routes: {
          "/user": (_) => const UserHome(),
          "/admin": (_) => const AdminHome(),
        },
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  RootRouter({super.key});

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
          return LoginPage();
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
