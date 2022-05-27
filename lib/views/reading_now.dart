import 'package:flutter/material.dart';

class ReadingNowPage extends StatefulWidget {
  const ReadingNowPage({Key? key}) : super(key: key);

  @override
  State<ReadingNowPage> createState() => _ReadingNowPageState();
}

class _ReadingNowPageState extends State<ReadingNowPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Icon(
          Icons.book,
          size: 150,
        ),
      ),
    );
  }
}
