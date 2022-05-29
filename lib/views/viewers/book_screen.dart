import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rbook/views/viewers/model/in_memory_reader_annotation_repository.dart';
import 'package:rbook/views/viewers/ui/reader_app_bar.dart';
import 'package:rbook/views/viewers/ui/reader_toolbar.dart';
import 'package:md5_file_checksum/md5_file_checksum.dart';
import 'package:mno_commons/utils/functions.dart';
import 'package:mno_navigator/publication.dart';
import 'package:mno_server/mno_server.dart';
import 'package:mno_shared/publication.dart';
import 'package:mno_streamer/parser.dart';

abstract class BookScreen extends StatefulWidget {
  final FileAsset asset;
  final ReaderAnnotationRepository? readerAnnotationRepository;

  const BookScreen({
    Key? key,
    required this.asset,
    this.readerAnnotationRepository,
  }) : super(key: key);
}

abstract class BookScreenState<T extends BookScreen,
    PubController extends PublicationController> extends State<T> {
  late PubController publicationController;
  late ReaderContext readerContext;

  ReaderAnnotationRepository get readerAnnotationRepository =>
      widget.readerAnnotationRepository ?? InMemoryReaderAnnotationRepository();

  @override
  void initState() {
    super.initState();
    publicationController = createPublicationController(
        onServerClosed,
        null,
        openLocation,
        widget.asset,
        createStreamer(),
        readerAnnotationRepository,
        handlersProvider);
  }

  Future<bool> loadWebViewConfig() async {
    if (Platform.isAndroid) {
      await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
    return true;
  }

  Future<String?> get openLocation async => null;

  Future<Streamer> createStreamer() async => Streamer();

  Function0<List<RequestHandler>> get handlersProvider;

  PubController createPublicationController(
      Function onServerClosed,
      Function? onPageJump,
      Future<String?> locationFuture,
      FileAsset fileAsset,
      Future<Streamer> streamerFuture,
      ReaderAnnotationRepository readerAnnotationRepository,
      Function0<List<RequestHandler>> handlersProvider);

  Widget createPublicationNavigator({
    required WidgetBuilder waitingScreenBuilder,
    required WidgetErrorBuilder displayErrorBuilder,
    required Consumer<ReaderContext> onReaderContextCreated,
    required WrapperWidgetBuilder wrapper,
    required PubController publicationController,
  });

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: loadWebViewConfig(),
      initialData: false,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.data!) {
          return WillPopScope(
            onWillPop: onWillPop,
            child: Scaffold(
              body: createPublicationNavigator(
                waitingScreenBuilder: buildWaitingScreen,
                displayErrorBuilder: _displayErrorDialog,
                onReaderContextCreated: onReaderContextCreated,
                wrapper: buildWidgetWrapper,
                publicationController: publicationController,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      });

  Future<bool> onWillPop() async => true;

  Widget buildWaitingScreen(BuildContext context) => Center(
      child: SpinKitChasingDots(
          size: 100, color: Theme.of(context).colorScheme.secondary));

  void _displayErrorDialog(BuildContext context, UserException userException) {
    // TODO open error dialog
    Fimber.d("Display error dialog: $userException");
  }

  void onReaderContextCreated(ReaderContext readerContext) {
    this.readerContext = readerContext;
    var md5SumBuilt = false;
    var md5Sum = null;
    // Get md5sum for sync
    try {
      var filePath = readerContext.asset.file.path;
      Md5FileChecksum.getFileChecksum(filePath: filePath).then((checksum) {
        md5SumBuilt = true;
        md5Sum = checksum;
      });
    }
    catch (exception) {
      print("err");
    }
    readerContext.asset.file;
    var currentHref = "";
    readerContext.currentLocationStream.listen(
      (event) {
        if (currentHref != readerContext.currentSpineItem!.href) {
          currentHref = readerContext.currentSpineItem!.href;
          for (var i = 0; i<readerContext.flattenedTableOfContents.length; i++) {
            if (readerContext.flattenedTableOfContents[i].href == readerContext.currentSpineItem!.href.substring(1)) {
              // Push stuff here

              print(i);
            }
          }
        }

      },
      onDone: () => print('Done'),
      onError: (error) => print(error),
    );
    // Use locator here to do stuff?
  }

  Widget buildWidgetWrapper(BuildContext context, Widget child,
          List<Link> spineItems, ServerStarted state) =>
      Stack(
        children: <Widget>[
          buildBackground(),
          SafeArea(
            child: child,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ReaderToolbar(
              readerContext: readerContext,
              onSkipLeft: publicationController.onSkipLeft,
              onSkipRight: publicationController.onSkipRight,
            ),
          ),
          SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ReaderAppBar(
                readerContext: readerContext,
                publicationController: publicationController,
              ),
            ),
          ),
        ],
      );

  Widget buildBackground() => const SizedBox.shrink();

  void onServerClosed() => Navigator.pop(context);
}
