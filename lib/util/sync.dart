import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mno_navigator/publication.dart';
import 'package:crypto/crypto.dart';

class Sync {
  ReaderContext readerContext;
  String serverUrl =
      "http://10.0.0.2:8081/"; // Eventually we'll get this from settings
  String username = "dog3779"; //NOTE: we don't have to handle updating these because settings *should* be inaccessable from here
  String password = "78c5a32eb836ef6c354f76cc1f379974";
  String device = "ios";
  String device_id = "rooty_dev_test";
  Dio dio = Dio();
  String? md5Sum;

  void pushProgress() async {
    for (var i = 0; i < readerContext.flattenedTableOfContents.length; i++) {
      if (readerContext.flattenedTableOfContents[i].href ==
          readerContext.currentSpineItem!.href.substring(1)) {
        // only run on our chapter
        if (md5Sum == null) {
          return;
        }
        var position = i+2;
        await dio.put(
          '/syncs/progress',
          data: {
            "progress": '/body/DocFragment[$position]',
            "device": device,
            "device_id": device_id,
            "document": md5Sum,
            "percentage": 0.0
          },
          options: Options(
            headers: {
              "x-auth-user": username,
              "x-auth-key": password,
            }
          )
        );
      }
    }
  }

  void pullProgress() async {

  }

  Future<bool> checkLogin() async {
    // Pull login info from preferences and do it there
    return true;
  }



  Sync(this.readerContext) {
    // Get md5sum for sync
    try {
      var filePath = readerContext.asset.file.path.split("/");
      var bytes = utf8.encode(filePath[filePath.length - 1]);
      var digest = md5.convert(bytes);
      md5Sum = digest.toString();
    } catch (exception) {
      print("err");
    }
    var currentHref = "";
    readerContext.currentLocationStream.listen(
      (event) {
        if (currentHref != readerContext.currentSpineItem!.href) {
          currentHref = readerContext.currentSpineItem!.href;
          pushProgress();
        }
      },
      onDone: () => print('Done'),
      onError: (error) => print(error),
    );

    dio.options.baseUrl = serverUrl;
  }
}
