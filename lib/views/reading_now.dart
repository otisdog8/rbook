import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rbook/views/viewers/epub_screen.dart';
import 'package:path_provider/path_provider.dart';

class ReadingNowPage extends StatefulWidget {
  const ReadingNowPage({Key? key}) : super(key: key);

  @override
  State<ReadingNowPage> createState() => _ReadingNowPageState();
}

class _ReadingNowPageState extends State<ReadingNowPage> {
  String _path = "/data/user/0/dev.rooty.rbook/app_flutter/war-and-peace.epub";

  void downloadFile(Directory directory) {
    print(directory.path);
    if (File("${directory.path}/war-and-peace.epub").existsSync()) {
      print("Exists");
      print("${directory.path}/war-and-peace.epub");
    } else {
      print(
          "Downloading!!!! YOU SHOULD NOT BE SEEING THIS!!! (unless this is the first time running this project");
      Dio dio = Dio();
      dio.download("https://www.feedbooks.com/book/83.epub",
          "${directory.path}/war-and-peace.epub");
    }
    setState(() {
      _path = "${directory.path}/war-and-peace.epub";
    });
  }

  @override
  void initState() {
    super.initState();
    // I put the logic for handling downloads here even though it DEFINITELY SHOULD NOT be in here
    getApplicationDocumentsDirectory()
        .then((directory) => {downloadFile(directory)}); //hell

    // Handle permissions - only needed once we use different directories

    // Figure out the file and path of file to download
    // Determine if exists
    // Actually download the file
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: TextButton(
              onPressed: () {
                // THINGS TO DO to figure out sync:
                // Convert DocFragment from koreader sync to spine index (or more likely, href (pain in the ass))
                // Or - convert xpointer (what Kobo outputs) into a CFI
                // Also need a way to convert back to what KOreader wants - DocFragment should work well for this
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) =>
                          EpubScreen.fromPath(filePath: _path,)),
                );
              },
              child: Text('Read book'))),
    );
  }
}
