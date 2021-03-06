import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:dfunc/dfunc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbook/views/viewers/book_screen.dart';
import 'package:rbook/views/viewers/model/fonts.dart';
import 'package:mno_commons/utils/functions.dart';
import 'package:mno_navigator/epub.dart';
import 'package:mno_navigator/publication.dart';
import 'package:mno_server/mno_server.dart';
import 'package:mno_shared/publication.dart';
import 'package:mno_streamer/parser.dart';

class EpubScreen extends BookScreen {
  final String? location;
  final int? settings;
  final Map<String, dynamic>? theme;

  const EpubScreen(
      {Key? key,
      required FileAsset asset,
      ReaderAnnotationRepository? readerAnnotationRepository,
      this.location,
      this.settings,
      this.theme})
      : super(
            key: key,
            asset: asset,
            readerAnnotationRepository: readerAnnotationRepository);

  factory EpubScreen.fromPath(
      {Key? key,
      required String filePath,
      ReaderAnnotationRepository? readerAnnotationRepository,
      String? location,
      String? settings,
      String? theme}) {
    Map<String, dynamic>? decodedTheme;
    try {
      decodedTheme = json.decode(theme!);
    } catch (e) {
      debugPrint('failure to decode theme: $e');
    }
    return EpubScreen(
      key: key,
      asset: FileAsset(File(filePath)),
      readerAnnotationRepository: readerAnnotationRepository,
      location: location,
      settings: int.tryParse(settings ?? '100'),
      theme: decodedTheme,
    );
  }

  factory EpubScreen.fromFile(
      {Key? key,
      required File file,
      ReaderAnnotationRepository? readerAnnotationRepository,
      String? location,
      String? settings,
      String? theme}) {
    Map<String, dynamic>? decodedTheme;
    try {
      decodedTheme = json.decode(theme!);
    } catch (e) {
      debugPrint('failure to decode theme: $e');
    }
    return EpubScreen(
      key: key,
      asset: FileAsset(file),
      readerAnnotationRepository: readerAnnotationRepository,
      location: location,
      settings: int.tryParse(settings ?? '100'),
      theme: decodedTheme,
    );
  }

  @override
  State<StatefulWidget> createState() => EpubScreenState();
}

class EpubScreenState extends BookScreenState<EpubScreen, EpubController> with WidgetsBindingObserver {
  late ViewerSettingsBloc _viewerSettingsBloc;
  late ReaderThemeBloc _readerThemeBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewerSettingsBloc =
        ViewerSettingsBloc(EpubReaderState("", widget.settings ?? 100));
    debugPrint(widget.theme.toString());
    _readerThemeBloc = ReaderThemeBloc(widget.theme != null
        ? ReaderThemeConfig.fromJson(widget.theme!)
        : ReaderThemeConfig.defaultTheme);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> onWillPop() async {
    try {
      sync.aboutToDie();
      readerContext.paginationInfo?.let((paginationInfo) =>
          readerAnnotationRepository.savePosition(paginationInfo));
      Navigator.pop(context, {
        'locator': readerContext.paginationInfo?.locator.json,
        'settings': _viewerSettingsBloc.viewerSettings.fontSize.toString(),
        'theme': json.encode(_readerThemeBloc.currentTheme.toJson()),
      });
    } catch (e) {
      // perhaps a snackbar notification can be added to indicate that there was a problem saving last location and settings
      debugPrint('error returning location and settings');
    }

    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    sync.processLifecycleState(state);
  }

  @override
  Future<String?> get openLocation async {
    if (widget.location != null) {
      return widget.location;
    }
    return readerAnnotationRepository
        .getPosition()
        .then((position) => position?.location);
  }

  @override
  EpubController createPublicationController(
          Function onServerClosed,
          Function? onPageJump,
          Future<String?> locationFuture,
          FileAsset fileAsset,
          Future<Streamer> streamerFuture,
          ReaderAnnotationRepository readerAnnotationRepository,
          Function0<List<RequestHandler>> handlersProvider) =>
      EpubController(onServerClosed, onPageJump, locationFuture, fileAsset,
          streamerFuture, readerAnnotationRepository, handlersProvider, null);

  @override
  Widget createPublicationNavigator({
    required WidgetBuilder waitingScreenBuilder,
    required WidgetErrorBuilder displayErrorBuilder,
    required Consumer<ReaderContext> onReaderContextCreated,
    required WrapperWidgetBuilder wrapper,
    required EpubController publicationController,
  }) =>
      EpubNavigator(
          waitingScreenBuilder: waitingScreenBuilder,
          displayErrorBuilder: displayErrorBuilder,
          onReaderContextCreated: onReaderContextCreated,
          wrapper: wrapper,
          epubController: publicationController);

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => _viewerSettingsBloc),
          BlocProvider(create: (context) => _readerThemeBloc),
        ],
        child: super.build(context),
      );

  @override
  Widget buildBackground() => BlocBuilder(
        bloc: _readerThemeBloc,
        builder: (BuildContext context, ReaderThemeState state) => Container(
          color: state.readerTheme.backgroundColor,
        ),
      );

  @override
  Function0<List<RequestHandler>> get handlersProvider => () => [
        AssetsRequestHandler(
          'packages/mno_navigator/assets',
          assetProvider: _AssetProvider(),
        ),
        FetcherRequestHandler(
            readerContext.publication!, () => readerContext.viewportWidth,
            googleFonts: Fonts.googleFonts)
      ];
}

class _AssetProvider implements AssetProvider {
  @override
  Future<ByteData> load(String path) => rootBundle.load(path);
}
