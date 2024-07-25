library xb_refresh;

import 'xb_refresh_config.dart';
import 'xb_refresh_footer.dart';
import 'xb_refresh_header.dart';
import 'xb_refresh_controller.dart';

export 'xb_refresh_config.dart';
export 'xb_refresh_footer.dart';
export 'xb_refresh_header.dart';
export 'xb_refresh_controller.dart';

class XBRefresh extends StatefulWidget {
  final Widget child;
  final VoidCallback? onBeginRefresh;
  final VoidCallback? onBeginLoadMore;
  final XBRefreshBuilder? headerBeforeBuilder;
  final XBRefreshBuilder? headerReadyBuilder;
  final XBRefreshBuilder? headerLoadingBuilder;
  final XBRefreshBuilder? headerCompleteBuilder;
  final XBRefreshBuilder? footerBeforeBuilder;
  final XBRefreshBuilder? footerReadyBuilder;
  final XBRefreshBuilder? footerLoadingBuilder;
  final XBRefreshBuilder? footerNoMoreBuilder;
  final XBRefreshBuilder? footerHasMoreBuilder;
  final bool needShowHasMoreFooter;
  final bool needShowComplete;
  final double headerLoadingOffset;
  final double footerLoadingOffset;
  final bool needRefresh;
  final bool needLoadMore;
  final bool initRefresh;
  final XBRefreshController controller;

  const XBRefresh(
      {required this.controller,
      required this.child,
      this.onBeginRefresh,
      this.headerBeforeBuilder,
      this.headerReadyBuilder,
      this.headerLoadingBuilder,
      this.headerCompleteBuilder,
      this.headerLoadingOffset = 50.0,
      this.needShowComplete = false,
      this.onBeginLoadMore,
      this.footerBeforeBuilder,
      this.footerReadyBuilder,
      this.footerNoMoreBuilder,
      this.footerHasMoreBuilder,
      this.footerLoadingBuilder,
      this.needShowHasMoreFooter = false,
      this.footerLoadingOffset = 50.0,
      this.needRefresh = true,
      this.needLoadMore = true,
      this.initRefresh = false,
      Key? key})
      : super(key: key);

  @override
  XBRefreshState createState() => XBRefreshState();
}

class XBRefreshState extends State<XBRefresh> {
  late XBRefreshController controller;

  bool get childIsScrollView => widget.child is ScrollView;

  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    if (childIsScrollView) {
      final controller = (widget.child as ScrollView).controller;
      assert(controller != null,
          "XBRefresh child 为ScrollView的情况，必须有ScrollController");
      _controller = controller!;
    } else {
      _controller = ScrollController();
    }

    _controller.addListener(_controllerListen);
  }

  _controllerListen() {
    if (controller.refreshKey.currentState != null) {
      controller.refreshKey.currentState?.receiveOffset(_controller.offset);
    }
    if (controller.loadMoreKey.currentState != null) {
      controller.loadMoreKey.currentState?.receiveOffset(
          _controller.offset, _controller.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_controllerListen);
    if (childIsScrollView == false) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (childIsScrollView) {
      child = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
        ),
        child: widget.child,
      );
    } else {
      child = CustomScrollView(
        controller: _controller,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: widget.child),
        ],
      );
    }
    if (widget.needRefresh && widget.needLoadMore) {
      return _buildHeader(_buildFooter(child));
    } else if (widget.needLoadMore) {
      return _buildFooter(child);
    } else if (widget.needRefresh) {
      return _buildHeader(child);
    } else {
      return child;
    }
  }

  _buildHeader(Widget child) {
    return XBRefreshHeader(
      key: controller.refreshKey,
      initRefresh: widget.initRefresh,
      onBeginRefresh: widget.onBeginRefresh,
      headerBeforeBuilder: widget.headerBeforeBuilder,
      headerReadyBuilder: widget.headerReadyBuilder,
      headerLoadingBuilder: widget.headerLoadingBuilder,
      headerCompleteBuilder: widget.headerCompleteBuilder,
      needShowComplete: widget.needShowComplete,
      headerLoadingOffset: widget.headerLoadingOffset,
      child: child,
    );
  }

  _buildFooter(Widget child) {
    return XBRefreshFooter(
      key: controller.loadMoreKey,
      onBeginLoadMore: widget.onBeginLoadMore,
      footerBeforeBuilder: widget.footerBeforeBuilder,
      footerReadyBuilder: widget.footerReadyBuilder,
      footerLoadingBuilder: widget.footerLoadingBuilder,
      footerNoMoreBuilder: widget.footerNoMoreBuilder,
      footerHasMoreBuilder: widget.footerHasMoreBuilder,
      needShowHasMoreFooter: widget.needShowHasMoreFooter,
      footerLoadingOffset: widget.footerLoadingOffset,
      child: child,
    );
  }
}
