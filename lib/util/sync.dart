import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mno_navigator/publication.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sync is a bit of a misnomer - it should handle pretty much all position changes based on data external to the reader (EpubScreen)
class Sync {
  ReaderContext readerContext;
  String serverUrl =
      "http://10.0.0.2:8081/"; // Eventually we'll get this from settings
  String username =
      "dog3779"; //NOTE: we don't have to handle updating these because settings *should* be inaccessable from here
  String password = "78c5a32eb836ef6c354f76cc1f379974";
  String device = "ios";
  String device_id = "rooty_dev_test";
  int timestamp = 0;
  bool timestampLock = true;
  Dio dio = Dio();
  String? md5Sum;
  SharedPreferences? prefs =
  null; //TODO: replace this with some json db so we can efficently do this for multiple documents

  Future<void> pushProgress() async {
    //TODO: proper error handling for dio
    // TODO: Fix weird error that corrupts the database somehow
    for (var i = 0; i < readerContext.flattenedTableOfContents.length; i++) {
      if (readerContext.flattenedTableOfContents[i].href ==
          readerContext.currentSpineItem!.href.substring(1)) {
        // only run on our chapter
        if (md5Sum == null) {
          return;
        }
        var position = i + 2;
        await dio.put('/syncs/progress',
            data: {
              "progress": '/body/DocFragment[$position]',
              "device": device,
              "device_id": device_id,
              "document": md5Sum,
              "percentage": 0.0
            },
            options: Options(headers: {
              "x-auth-user": username,
              "x-auth-key": password,
            }));
      }
    }
  }

  Future<void> pullProgress() async {
    var data = await dio.get('/syncs/progress/$md5Sum',
        options: Options(headers: {
          "x-auth-user": username,
          "x-auth-key": password,
        }));
    print("HENCE FOLLOWS PROGRESS DATA");
    print(data);
    var result = data.data;
    if (result["device"] == this.device &&
        result[ "device_id" ] == this.device_id) {
      print("Quit on device matching");
      return;
    }
    if (result["timestamp"] * 1000 < this.timestamp) {
      print(timestamp);
      print("Quit on timestamp matching");
      return;
    }
    //TODO: to fix this, we need to fix the code running too fast. Maybe set the initial pullProgress to execute on the first pagination event? as that ensures that the code has "activated"
    var progress = result["progress"].split("[")[1];
    progress = progress.split("]")[0];
    var spineIndex = int.parse(progress);
    spineIndex -= 2;
    var link = readerContext.flattenedTableOfContents[spineIndex];
    readerContext.execute(
        GoToHrefCommand(link.href, null)
    );
    // grab from server
    // Check device type and ID
    // Check timestamps
    // Scroll the reader to new position
    // This goes in a different function (because we want to load from storage also)
    // Release timestamp lock
  }

  Future<bool> checkLogin() async {
    // Pull login info from preferences and do it there
    return true;
  }

  // Called when stuff is about to be unloaded
  void aboutToDie() {
    pushProgress();
    var locatorJson = readerContext.paginationInfo?.locator.json;
    prefs?.setString("locatorJson", locatorJson ?? "");
    prefs?.setInt("lastPageTimestamp", timestamp);
  }

  initialSync() async {
    // This function is also run at the start of the program (after Sync is initiated)
    // This means init logic CAN be put in here, and it will work asynchronously
    this.prefs = await SharedPreferences.getInstance();
    var lastPageTimestamp = prefs?.getInt("lastPageTimestamp");
    this.timestamp = lastPageTimestamp!;
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
        // TODO: handle last page turn timestamp
        if (!timestampLock) {
          timestamp = DateTime
              .now()
              .millisecondsSinceEpoch;
        }
        else {
          pullProgress().then((val) {
            this.timestampLock = false;
          });
        }
        if (currentHref != readerContext.currentSpineItem!.href) {
          currentHref = readerContext.currentSpineItem!.href;
          pushProgress();
        }
      },
      onDone: () => print('Done'),
      onError: (error) => print(error),
    );
    // Don't need to make this updatable becuase no settings editing from reader screen
    dio.options.baseUrl = serverUrl;


    // This should run once per book open so its safe to do an initial? sync here (maybe)
    // Execution order is REALLY sketchy so we lock lastTimestamp first after loading it (from god knows where)
    // This prevents issues where us opening and firing off page turn events causes stuff to happen
    // We actually first
  }
}
