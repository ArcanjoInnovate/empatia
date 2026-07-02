import 'package:empatia/core/auth_guard/auth_guard.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/data/repositories/user_repository.dart';
import 'package:empatia/core/navigation/router_observer.dart';
import 'package:empatia/features/auth/presentation/pages/login_page.dart';
import 'package:empatia/features/donation/controller/donation_controller.dart';
import 'package:empatia/features/donation/data/repository/donation_repository.dart';
import 'package:empatia/features/donation/data/service/donation_service.dart';
import 'package:empatia/features/dream/controller/dream_controller.dart';
import 'package:empatia/features/dream/data/repository/dream_repository.dart';
import 'package:empatia/features/dream/data/repository/dreams_feed_repository.dart';
import 'package:empatia/features/dream/data/service/dream_service.dart';
import 'package:empatia/features/profile/controller/profile_controller.dart';
import 'package:empatia/features/profile/data/repository/storage_repository.dart';
import 'package:empatia/features/profile/data/repository/location_repository.dart';
import 'package:empatia/features/profile/data/repository/profile_repository.dart';
import 'package:empatia/features/profile/data/service/storage_service.dart';
import 'package:empatia/features/profile/data/service/location_service.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:empatia/features/request/controller/request_controller.dart';
import 'package:empatia/features/request/data/repository/request_repository.dart';
import 'package:empatia/features/request/data/service/request_service.dart';
import 'package:empatia/features/search/controller/search_controller.dart';
import 'package:empatia/features/search/controller/search_filter_controller.dart';
import 'package:empatia/features/search/data/repositories/search_location_repository.dart';
import 'package:empatia/features/search/data/repositories/search_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Reaaplica immersiveSticky sempre que o app volta ao foco.
  /// O Android reseta o modo ao exibir dialogs, bottom sheets,
  /// teclado virtual, notificações, etc.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── 1. Repositórios ──────────────────────────────────
        Provider<ProfileRepository>(create: (_) => ProfileRepository()),
        Provider<LocationRepository>(create: (_) => LocationRepository()),
        Provider<StorageRepository>(create: (_) => StorageRepository()),
        Provider<DonationRepository>(create: (_) => DonationRepository()),
        Provider<RequestRepository>(create: (_) => RequestRepository()),
        Provider<DreamRepository>(create: (_) => DreamRepository()),
        Provider<DreamsFeedRepository>(create: (_) => DreamsFeedRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<SearchRepository>(create: (_) => SearchRepository()),
        Provider<SearchLocationRepository>(
            create: (_) => SearchLocationRepository()),

        // ── 2. Services ──────────────────────────────────────
        ProxyProvider<StorageRepository, StorageService>(
          update: (_, repo, __) => StorageService(repo),
        ),
        ProxyProvider2<ProfileRepository, StorageService, ProfileService>(
          update: (_, profileRepo, storage, __) =>
              ProfileService(profileRepo, storage),
        ),
        ProxyProvider<LocationRepository, LocationService>(
          update: (_, repo, __) => LocationService(repo),
        ),
        ProxyProvider2<DonationRepository, StorageService, DonationService>(
          update: (_, repo, storage, __) =>
              DonationService(repo, storage),
        ),
        ProxyProvider<RequestRepository, RequestService>(
          update: (_, repo, __) => RequestService(repo),
        ),
        ProxyProvider3<DreamRepository, StorageService, DreamsFeedRepository, DreamService>(
          update: (_, repo, storage, feedRepo, __) =>
              DreamService(repo, storage, feedRepo),
        ),

        // ── 3. Stream do UserModel ───────────────────────────
        StreamProvider<UserModel?>(
          create: (context) => context.read<UserRepository>().watchCurrentUser(),
          initialData: null,
          catchError: (_, __) => null,
        ),

        // ── 4. Controllers ───────────────────────────────────
        ChangeNotifierProxyProvider2<ProfileService, LocationService,
            ProfileController>(
          create: (_) => ProfileController(
            ProfileService(
              ProfileRepository(),
              StorageService(StorageRepository()),
            ),
            LocationService(LocationRepository()),
          ),
          update: (_, profileService, locationService, __) =>
              ProfileController(profileService, locationService),
        ),
        ChangeNotifierProxyProvider2<DonationRepository, StorageService,
            DonationController>(
          create: (_) => DonationController(
            DonationService(
              DonationRepository(),
              StorageService(StorageRepository()),
            ),
          ),
          update: (_, repo, storage, __) =>
              DonationController(DonationService(repo, storage)),
        ),
        ChangeNotifierProxyProvider<RequestService, RequestController>(
          create: (_) =>
              RequestController(RequestService(RequestRepository())),
          update: (_, service, __) => RequestController(service),
        ),
        ChangeNotifierProxyProvider3<DreamRepository, StorageService,
            DreamsFeedRepository, DreamController>(
          create: (_) => DreamController(
            DreamService(
              DreamRepository(),
              StorageService(StorageRepository()),
              DreamsFeedRepository(),
            ),
          ),
          update: (_, repo, storage, feedRepo, __) =>
              DreamController(DreamService(repo, storage, feedRepo)),
        ),
        ChangeNotifierProxyProvider<SearchRepository, SearchController>(
          create: (_) => SearchController(SearchRepository()),
          update: (_, repo, __) => SearchController(repo),
        ),
        ChangeNotifierProxyProvider<SearchLocationRepository,
            SearchFilterController>(
          create: (_) => SearchFilterController(SearchLocationRepository()),
          update: (_, repo, __) => SearchFilterController(repo),
        ),
      ],
      child: MaterialApp(
        title: 'Empatia',
        // Chave global de navegação — usada pelo NotificationDisplayService
        // pra abrir o chat certo quando o usuário toca numa notificação
        // (local, composta pelo próprio app) mesmo sem um BuildContext
        // de tela disponível naquele momento.
        navigatorKey: rootNavigatorKey,
        // ── RouteObserver global ──────────────────────────────
        // Permite que widgets (ex.: WeeklyRankingWidget na Home) saibam,
        // via RouteAware, quando ficam cobertos por outra rota
        // (didPushNext) e quando voltam a ficar visíveis (didPopNext).
        // Usado para pausar timers/animações que rodam por baixo de
        // páginas empilhadas (ex.: PublicProfilePage), evitando que
        // "vazem" visualmente durante a transição de pop.
        navigatorObservers: [appRouteObserver],
        theme: ThemeData(
          fontFamily: 'Poppins',
          // ── Transições de página ──────────────────────────────
          // O Android, por padrão (Material 3), usa o
          // ZoomPageTransitionsBuilder. Esse builder faz um CROSSFADE de
          // opacidade entre a página que está saindo e a que está
          // entrando — ou seja, durante boa parte da animação as DUAS
          // telas ficam parcialmente visíveis e sobrepostas ao mesmo
          // tempo. Quando a página de saída tem conteúdo com texto/
          // ícones em posições que coincidem com a área da próxima tela
          // (como os cards de estatística e a seção "Filhos" do
          // PublicProfilePage), esse crossfade faz esse conteúdo
          // "vazar" visualmente por cima da tela seguinte por uma fração
          // de segundo, como um fantasma, antes de sumir — efeito
          // confirmado por captura de frames durante o teste.
          //
          // A CupertinoPageTransitionsBuilder usa um slide horizontal
          // com as duas telas sempre OPACAS (sem crossfade de opacidade),
          // então não existe essa janela de sobreposição visual.
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF2563EB),
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              );
            }

            if (snapshot.data != null) {
              return const AuthGuard();
            }

            return const LoginPage();
          },
        ),
      ),
    );
  }
}