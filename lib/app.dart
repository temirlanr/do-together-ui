import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/core_providers.dart';

class DoTogetherApp extends ConsumerStatefulWidget {
  const DoTogetherApp({super.key});

  @override
  ConsumerState<DoTogetherApp> createState() => _DoTogetherAppState();
}

class _DoTogetherAppState extends ConsumerState<DoTogetherApp> {
  StreamSubscription<void>? _sessionExpiredSub;

  @override
  void initState() {
    super.initState();
    // Listen for session expiry from the ApiClient (e.g. refresh token rejected)
    // and immediately log the user out so the router redirects to login.
    _sessionExpiredSub =
        ref.read(apiClientProvider).sessionExpiredStream.listen((_) {
      ref.read(authProvider.notifier).logout();
    });
  }

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DoTogether',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
