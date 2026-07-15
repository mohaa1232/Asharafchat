import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/groups/presentation/group_chat_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final loggingIn = state.matchedLocation == '/login' ||
        state.matchedLocation == '/otp' ||
        state.matchedLocation == '/register';

    if (!loggedIn && !loggingIn) return '/login';
    if (loggedIn && loggingIn) return '/chats';
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/chats'),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/otp',
      builder: (context, state) =>
          OtpScreen(verificationId: state.extra as String? ?? ''),
    ),
    GoRoute(
        path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/chats', builder: (context, state) => const ChatListScreen()),
    GoRoute(
      path: '/chat/:chatId',
      builder: (context, state) => ChatScreen(
        chatId: state.pathParameters['chatId']!,
        peerName: (state.extra as Map?)?['peerName'] ?? 'Chat',
      ),
    ),
    GoRoute(
      path: '/group/:groupId',
      builder: (context, state) => GroupChatScreen(
        groupId: state.pathParameters['groupId']!,
        groupName: (state.extra as Map?)?['groupName'] ?? 'Group',
      ),
    ),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],
);
