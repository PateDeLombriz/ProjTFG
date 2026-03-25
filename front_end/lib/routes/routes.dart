//import 'package:flutter/material.dart';
//
//class AppRoutes {
//    static const String home = '/';
//    static const String login = '/login';
//    static const String signup = '/signup';
//    static const String dashboard = '/dashboard';
//    static const String profile = '/profile';
//    static const String settings = '/settings';
//
//    static Map<String, WidgetBuilder> getRoutes() {
//        return {
//            home: (context) => const HomePage(),
//            login: (context) => const LoginPage(),
//            signup: (context) => const SignupPage(),
//            dashboard: (context) => const DashboardPage(),
//            profile: (context) => const ProfilePage(),
//            settings: (context) => const SettingsPage(),
//        };
//    }
//
//    static Route<dynamic> onGenerateRoute(RouteSettings settings) {
//        switch (settings.name) {
//            case home:
//                return MaterialPageRoute(builder: (_) => const HomePage());
//            case login:
//                return MaterialPageRoute(builder: (_) => const LoginPage());
//            default:
//                return MaterialPageRoute(builder: (_) => const NotFoundPage());
//        }
//    }
//}