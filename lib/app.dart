import 'package:empatia/core/auth_guard/auth_guard.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/data/repositories/user_repository.dart';
import 'package:empatia/features/auth/presentation/pages/login_page.dart';
import 'package:empatia/features/donation/controller/donation_controller.dart';
import 'package:empatia/features/donation/data/repository/donation_repository.dart';
import 'package:empatia/features/donation/data/service/donation_service.dart';
import 'package:empatia/features/dream/controller/dream_controller.dart';
import 'package:empatia/features/dream/data/repository/dream_repository.dart';
import 'package:empatia/features/dream/data/repository/dreams_feed_repository.dart';
import 'package:empatia/features/dream/data/service/dream_service.dart';
import 'package:empatia/features/profile/controller/profile_controller.dart';
import 'package:empatia/features/profile/data/repository/cloudinary_repository.dart';
import 'package:empatia/features/profile/data/repository/location_repository.dart';
import 'package:empatia/features/profile/data/repository/profile_repository.dart';
import 'package:empatia/features/profile/data/service/cloudinary_service.dart';
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
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── 1. Repositórios ──────────────────────────────────
        Provider<ProfileRepository>(create: (_) => ProfileRepository()),
        Provider<LocationRepository>(create: (_) => LocationRepository()),
        Provider<CloudinaryRepository>(create: (_) => CloudinaryRepository()),
        Provider<DonationRepository>(create: (_) => DonationRepository()),
        Provider<RequestRepository>(create: (_) => RequestRepository()),
        Provider<DreamRepository>(create: (_) => DreamRepository()),
        Provider<DreamsFeedRepository>(create: (_) => DreamsFeedRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<SearchRepository>(create: (_) => SearchRepository()),
        Provider<SearchLocationRepository>(
            create: (_) => SearchLocationRepository()),

        // ── 2. Services ──────────────────────────────────────
        ProxyProvider<CloudinaryRepository, CloudinaryService>(
          update: (_, repo, __) => CloudinaryService(repo),
        ),
        ProxyProvider2<ProfileRepository, CloudinaryService, ProfileService>(
          update: (_, profileRepo, cloudinary, __) =>
              ProfileService(profileRepo, cloudinary),
        ),
        ProxyProvider<LocationRepository, LocationService>(
          update: (_, repo, __) => LocationService(repo),
        ),
        ProxyProvider2<DonationRepository, CloudinaryService, DonationService>(
          update: (_, repo, cloudinary, __) =>
              DonationService(repo, cloudinary),
        ),
        ProxyProvider<RequestRepository, RequestService>(
          update: (_, repo, __) => RequestService(repo),
        ),
        ProxyProvider3<DreamRepository, CloudinaryService, DreamsFeedRepository, DreamService>(
          update: (_, repo, cloudinary, feedRepo, __) =>
              DreamService(repo, cloudinary, feedRepo),
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
              CloudinaryService(CloudinaryRepository()),
            ),
            LocationService(LocationRepository()),
          ),
          update: (_, profileService, locationService, __) =>
              ProfileController(profileService, locationService),
        ),
        ChangeNotifierProxyProvider2<DonationRepository, CloudinaryService,
            DonationController>(
          create: (_) => DonationController(
            DonationService(
              DonationRepository(),
              CloudinaryService(CloudinaryRepository()),
            ),
          ),
          update: (_, repo, cloudinary, __) =>
              DonationController(DonationService(repo, cloudinary)),
        ),
        ChangeNotifierProxyProvider<RequestService, RequestController>(
          create: (_) =>
              RequestController(RequestService(RequestRepository())),
          update: (_, service, __) => RequestController(service),
        ),
        ChangeNotifierProxyProvider3<DreamRepository, CloudinaryService,
            DreamsFeedRepository, DreamController>(
          create: (_) => DreamController(
            DreamService(
              DreamRepository(),
              CloudinaryService(CloudinaryRepository()),
              DreamsFeedRepository(),
            ),
          ),
          update: (_, repo, cloudinary, feedRepo, __) =>
              DreamController(DreamService(repo, cloudinary, feedRepo)),
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
        theme: ThemeData(fontFamily: 'Poppins'),
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