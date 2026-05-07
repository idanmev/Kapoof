import 'package:flutter/material.dart';
import 'package:kapoof/core/theme.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';

class PlayScreen extends StatefulWidget {
  final String htmlContent;
  final String creationType;

  const PlayScreen({
    super.key,
    required this.htmlContent,
    required this.creationType,
  });

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.creationType != 'story') {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadHtmlString(widget.htmlContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    final typeName = widget.creationType == 'dartgame'
        ? 'Game'
        : widget.creationType == 'story'
            ? 'Story'
            : 'Drawing';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Your Magic $typeName',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: isTablet ? 20.0 : 24.0,
            fontWeight: FontWeight.w800,
            color: AppColors.onBackground,
          ),
        ),
        backgroundColor: AppColors.surface,
        toolbarHeight: isTablet ? 56.0 : 64.0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: NeobrutalistButton(
            size: isTablet ? 40.0 : 48.0,
            onTap: () => Navigator.pop(context),
            backgroundColor: AppColors.surface,
            child: Icon(Icons.close,
                color: AppColors.onBackground, size: isTablet ? 18.0 : 22.0),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            color: AppColors.onBackground,
          ),
        ),
      ),
      body: widget.creationType == 'story'
          ? _buildStoryReader(isTablet)
          : WebViewWidget(controller: _controller),
    );
  }

  Widget _buildStoryReader(bool isTablet) {
    final storyController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(widget.htmlContent);

    return Container(
      margin: EdgeInsets.all(isTablet ? 20.0 : 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 24.0 : 28.0),
        border: Border.all(
            color: AppColors.onBackground, width: isTablet ? 3.0 : 4.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.onBackground,
            offset: Offset(isTablet ? 5.0 : 7.0, isTablet ? 5.0 : 7.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 21.0 : 24.0),
        child: WebViewWidget(controller: storyController),
      ),
    );
  }
}
