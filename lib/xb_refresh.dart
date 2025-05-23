// ignore_for_file: invalid_use_of_protected_member

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
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
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
  final bool needShowRefreshComplete;
  final double headerLoadingOffset;
  final double footerLoadingOffset;
  final bool needRefresh;
  final bool needLoadMore;

  /// 初始状态要不要显示正在刷新
  final bool initRefresh;

  /// 初始状态显示刷新的情况下，要不要延迟调用刷新回调
  final bool initRefreshDelay;

  final XBRefreshController controller;

  /// delay call refresh
  final int delayCallRefreshMilliseconds;

  /// delay call loadmore
  final int delayCallLoadMoreMilliseconds;

  const XBRefresh(
      {required this.controller,
      required this.child,
      this.onRefresh,
      this.headerBeforeBuilder,
      this.headerReadyBuilder,
      this.headerLoadingBuilder,
      this.headerCompleteBuilder,
      this.headerLoadingOffset = 50.0,
      this.needShowRefreshComplete = false,
      this.onLoadMore,
      this.footerBeforeBuilder,
      this.footerReadyBuilder,
      this.footerNoMoreBuilder,
      this.footerHasMoreBuilder,
      this.footerLoadingBuilder,
      this.needShowHasMoreFooter = false,
      this.footerLoadingOffset = 50.0,
      this.needRefresh = true,
      this.needLoadMore = false,
      this.initRefresh = false,
      this.initRefreshDelay = true,
      this.delayCallRefreshMilliseconds = 0,
      this.delayCallLoadMoreMilliseconds = 0,
      Key? key})
      : assert(!needRefresh || onRefresh != null,
            "needRefresh为true时，onRefresh不能为空"),
        assert(!needLoadMore || onLoadMore != null,
            "needLoadMore为true时，onLoadMore不能为空"),
        super(key: key);

  @override
  XBRefreshState createState() => XBRefreshState();
}

class XBRefreshState extends State<XBRefresh> {
  late XBRefreshController refreshController;

  bool get childHasController => _childHasController(widget.child);

  bool _childHasController(Widget child) {
    if (child is ScrollView) {
      return child.controller != null;
    }
    if (child is SingleChildScrollView) {
      return child.controller != null;
    }
    return false;
  }

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    refreshController = widget.controller;

    _setupScrollController();
  }

  _setupScrollController() {
    if (childHasController) {
      if (widget.child is ScrollView) {
        _scrollController = (widget.child as ScrollView).controller!;
      } else if (widget.child is SingleChildScrollView) {
        _scrollController = (widget.child as SingleChildScrollView).controller!;
      }
    } else {
      _scrollController = ScrollController();
    }

    _scrollController.addListener(_controllerListen);
  }

  _controllerListen() {
    if (refreshController.refreshKey.currentState != null) {
      refreshController.refreshKey.currentState
          ?.receiveOffset(_scrollController.offset);
    }
    if (refreshController.loadMoreKey.currentState != null) {
      refreshController.loadMoreKey.currentState?.receiveOffset(
          _scrollController.offset, _scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_controllerListen);
    if (childHasController == false) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant XBRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      /// 移除监听
      _scrollController.removeListener(_controllerListen);
      if (_childHasController(oldWidget.child) == false) {
        _scrollController.dispose();
      }
      _setupScrollController();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (widget.child is SingleChildScrollView) {
      final scsv = widget.child as SingleChildScrollView;
      child = CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        scrollDirection: scsv.scrollDirection,
        reverse: scsv.reverse,
        primary: scsv.primary,
        dragStartBehavior: scsv.dragStartBehavior,
        restorationId: scsv.restorationId,
        slivers: [
          SliverPadding(
            padding: scsv.padding ?? EdgeInsets.zero,
            sliver: SliverList(
              delegate:
                  SliverChildListDelegate([scsv.child ?? const SizedBox()]),
            ),
          ),
        ],
      );
    } else if (widget.child is ScrollView) {
      if (childHasController) {
        child = ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
          ),
          child: widget.child,
        );
      } else {
        ScrollView childView = widget.child as ScrollView;
        List<Widget>? slivers;

        if (childView is BoxScrollView) {
          Widget sliver = childView.buildChildLayout(context);
          if (childView.padding != null) {
            slivers = [
              SliverPadding(
                sliver: sliver,
                padding: childView.padding!,
              )
            ];
          } else {
            slivers = [sliver];
          }
        } else {
          slivers = List.from(childView.buildSlivers(context), growable: true);
        }

        child = CustomScrollView(
          controller: _scrollController,
          cacheExtent: childView.cacheExtent,
          key: childView.key,
          scrollDirection: childView.scrollDirection,
          semanticChildCount: childView.semanticChildCount,
          primary: childView.primary,
          clipBehavior: childView.clipBehavior,
          keyboardDismissBehavior: childView.keyboardDismissBehavior,
          anchor: childView.anchor,
          restorationId: childView.restorationId,
          center: childView.center,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: slivers,
          dragStartBehavior: childView.dragStartBehavior,
          reverse: childView.reverse,
        );
      }
    } else {
      child = CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverFillRemaining(
            child: widget.child,
          )
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
      key: refreshController.refreshKey,
      initRefresh: widget.initRefresh,
      initRefreshDelay: widget.initRefreshDelay,
      onRefresh: widget.onRefresh,
      headerBeforeBuilder: widget.headerBeforeBuilder,
      headerReadyBuilder: widget.headerReadyBuilder,
      headerLoadingBuilder: widget.headerLoadingBuilder,
      headerCompleteBuilder: widget.headerCompleteBuilder,
      needShowComplete: widget.needShowRefreshComplete,
      headerLoadingOffset: widget.headerLoadingOffset,
      delayCallRefreshMilliseconds: widget.delayCallRefreshMilliseconds,
      child: child,
    );
  }

  _buildFooter(Widget child) {
    return XBRefreshFooter(
      key: refreshController.loadMoreKey,
      onLoadMore: widget.onLoadMore,
      footerBeforeBuilder: widget.footerBeforeBuilder,
      footerReadyBuilder: widget.footerReadyBuilder,
      footerLoadingBuilder: widget.footerLoadingBuilder,
      footerNoMoreBuilder: widget.footerNoMoreBuilder,
      footerHasMoreBuilder: widget.footerHasMoreBuilder,
      needShowHasMoreFooter: widget.needShowHasMoreFooter,
      footerLoadingOffset: widget.footerLoadingOffset,
      delayCallLoadMoreMilliseconds: widget.delayCallLoadMoreMilliseconds,
      child: child,
    );
  }
}
