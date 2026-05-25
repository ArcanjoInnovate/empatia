import 'package:empatia/core/auth_guard/auth_guard.dart';
import 'package:empatia/features/profile/controller/profile_controller.dart';
import 'package:empatia/features/profile/data/repository/cloudinary_repository.dart';
import 'package:empatia/features/profile/data/repository/location_repository.dart';
import 'package:empatia/features/profile/data/repository/profile_repository.dart';
import 'package:empatia/features/profile/data/service/cloudinary_service.dart';
import 'package:empatia/features/profile/data/service/location_service.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Repositórios
        Provider<ProfileRepository>(
          create: (_) => ProfileRepository(),
        ),
        Provider<LocationRepository>(
          create: (_) => LocationRepository(),
        ),
        Provider<CloudinaryRepository>(
          create: (_) => CloudinaryRepository(),
        ),

        // 2. Services — recebem seus repositórios
        ProxyProvider<CloudinaryRepository, CloudinaryService>(
          update: (_, repo, __) => CloudinaryService(repo),
        ),
        ProxyProvider2<ProfileRepository, CloudinaryService, ProfileService>(
          update: (_, profileRepo, cloudinaryService, __) => 
              ProfileService(profileRepo, cloudinaryService),
        ),
        ProxyProvider<LocationRepository, LocationService>(
          update: (_, repo, __) => LocationService(repo),
        ),

        // 3. ProfileController — recebe ProfileService + LocationService
        ChangeNotifierProxyProvider2<ProfileService, LocationService, ProfileController>(
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
      ],
      child: MaterialApp(
        title: 'Empatia',
        theme: ThemeData(
          fontFamily: 'Poppins',
        ),
        home: const AuthGuard(),
      ),
    );
  }
}