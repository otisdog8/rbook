import 'package:flutter/material.dart';
import 'package:rbook/views/viewers/ui/annotations_panel.dart';
import 'package:rbook/views/viewers/ui/content_panel.dart';
import 'package:mno_navigator/publication.dart';

class ReaderNavigationScreen extends StatefulWidget {
  final ReaderContext readerContext;

  const ReaderNavigationScreen({Key? key, required this.readerContext})
      : super(key: key);

  @override
  State<ReaderNavigationScreen> createState() => _ReaderNavigationScreenState();
}

class _ReaderNavigationScreenState extends State<ReaderNavigationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.onPrimary,
            controller: _tabController,
            tabs: const [
              Tab(text: "Contents"),
              Tab(text: "Bookmarks"),
              Tab(text: "Highlights"),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              ContentPanel(
                readerContext: widget.readerContext,
              ),
              AnnotationsPanel(
                readerContext: widget.readerContext,
                annotationType: AnnotationType.bookmark,
              ),
              AnnotationsPanel(
                readerContext: widget.readerContext,
                annotationType: AnnotationType.highlight,
              ),
            ],
          ),
        ),
      );
}
