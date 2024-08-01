import 'xb_refresh_config.dart';

class XBRefreshFooter extends StatefulWidget {
  final Widget child;
  final VoidCallback? onLoadMore;
  final XBRefreshBuilder? footerBeforeBuilder;
  final XBRefreshBuilder? footerReadyBuilder;
  final XBRefreshBuilder? footerLoadingBuilder;
  final XBRefreshBuilder? footerNoMoreBuilder;
  final XBRefreshBuilder? footerHasMoreBuilder;
  final bool needShowHasMoreFooter;

  /// delay call loadmore
  final int delayCallLoadMoreMilliseconds;

  ///大于这个值可以加载更多,也用于限制footer的高度
  final double footerLoadingOffset;

  const XBRefreshFooter(
      {required this.child,
      this.onLoadMore,
      this.footerBeforeBuilder,
      this.footerReadyBuilder,
      this.footerNoMoreBuilder,
      this.footerHasMoreBuilder,
      this.footerLoadingBuilder,
      this.needShowHasMoreFooter = false,
      this.footerLoadingOffset = 50.0,
      this.delayCallLoadMoreMilliseconds = 0,
      Key? key})
      : super(key: key);

  @override
  XBRefreshFooterState createState() => XBRefreshFooterState();
}

class XBRefreshFooterState extends State<XBRefreshFooter>
    with SingleTickerProviderStateMixin {
  XBLoadMoreState _footerState = XBLoadMoreState.before;
  double _footerTopPadding = 0.0;
  double _childBottomPadding = 0.0;
  bool _isUserAction = false;
  double _lastOffset = 0;
  double _maxOffset = 0;
  bool _isInProcess = false;
  bool _isCompleted = false;

  ///hasMore是否有数据更新
  endLoadMore(bool hasMore) {
    if (_footerState == XBLoadMoreState.loading) {
      if (hasMore == true) {
        if (widget.needShowHasMoreFooter) {
          setState(() {
            _footerState = XBLoadMoreState.hasMore;
          });
          Future.delayed(const Duration(seconds: 1), () {
            _afterHasMore();
          });
        } else {
          _afterHasMore();
        }
      } else {
        setState(() {
          _footerState = XBLoadMoreState.noMore;
        });
        Future.delayed(const Duration(seconds: 1), () {
          _resetFooter();
          setState(() {
            _childBottomPadding = 0;
            _isCompleted = true;
          });
          _endProcessIfPossible();
        });
      }
    }
  }

  receiveOffset(double offset, double maxOffset) {
    _maxOffset = maxOffset;
    bool upward = offset > _lastOffset;
    _lastOffset = offset;

    if (offset > _maxOffset) {
      if (_isCompleted && _isInProcess) return;

      if (_isInProcess == false && _isUserAction) {
        _isInProcess = true;
      }

      if (_footerState == XBLoadMoreState.loading ||
          _footerState == XBLoadMoreState.hasMore ||
          _footerState == XBLoadMoreState.noMore) {
        return;
      }
      double fitOffset = offset - maxOffset;
      if (fitOffset <= 0) {
        return;
      }

      double top = widget.footerLoadingOffset - fitOffset;
      if (top < 0) {
        top = 0;
      }
      setState(() {
        _footerTopPadding = top;
      });

      if (upward) {
        if (_isUserAction) {
          _footerUserActionRun(fitOffset);
        } else {
          setState(() {
            _footerState = XBLoadMoreState.before;
          });
        }
      } else {
        if (_isUserAction) {
          _footerUserActionRun(fitOffset);
        }
      }
    } else {
      _endProcessIfPossible();
    }
  }

  @override
  void initState() {
    super.initState();
    _footerTopPadding = widget.footerLoadingOffset;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(child: Container()),
            Container(
              height: widget.footerLoadingOffset,
              padding: EdgeInsets.only(top: _footerTopPadding),
              child: _buildFooterContent(),
            ),
          ],
        ),
        Listener(
          onPointerDown: (detail) {
            _isUserAction = true;
          },
          onPointerUp: (detail) {
            _isUserAction = false;

            if (_lastOffset + widget.footerLoadingOffset <= _maxOffset ||
                _maxOffset == 0) {
              _endProcessIfPossible();
            }

            if (_footerState == XBLoadMoreState.ready) {
              setState(() {
                _footerState = XBLoadMoreState.loading;
                _childBottomPadding = widget.footerLoadingOffset;
              });
              if (widget.onLoadMore != null) {
                Future.delayed(
                    Duration(
                        milliseconds: widget.delayCallLoadMoreMilliseconds),
                    () {
                  widget.onLoadMore!();
                });
              }
            }
          },
          child: Padding(
            padding: EdgeInsets.only(bottom: _childBottomPadding),
            child: widget.child,
          ),
        ),
      ],
    );
  }

  _afterHasMore() {
    setState(() {
      _childBottomPadding = 0;
      _resetFooter();
      _isCompleted = true;
    });
    _endProcessIfPossible();
  }

  _endProcessIfPossible() {
    if (_isUserAction == false &&
        _lastOffset <= _maxOffset &&
        _isInProcess == true &&
        _isCompleted == true) {
      setState(() {
        _isInProcess = false;
        _isCompleted = false;
      });
    }
  }

  _resetFooter() {
    setState(() {
      _footerState = XBLoadMoreState.before;
      _footerTopPadding = widget.footerLoadingOffset;
    });
  }

  _footerUserActionRun(double fitOffset) {
    if (fitOffset >= widget.footerLoadingOffset) {
      setState(() {
        _footerState = XBLoadMoreState.ready;
      });
    } else {
      setState(() {
        _footerState = XBLoadMoreState.before;
      });
    }
  }

  Widget _buildFooterContent() {
    Widget child;
    switch (_footerState) {
      case XBLoadMoreState.before:
        child = _footerBeforeDisplay();
        break;
      case XBLoadMoreState.ready:
        child = _footerReadyDisplay();
        break;
      case XBLoadMoreState.loading:
        child = _footerLoadingDisplay();
        break;
      case XBLoadMoreState.hasMore:
        child = _footerHasMoreDisplay();
        break;
      case XBLoadMoreState.noMore:
        child = _footerNoMoreDisplay();
        break;
      default:
        child = Container();
        break;
    }
    return child;
  }

  Widget _footerBeforeDisplay() {
    Widget child;
    if (widget.footerBeforeBuilder != null) {
      child = widget.footerBeforeBuilder!(widget.footerLoadingOffset);
    } else {
      child = const Text("上拉加载更多");
    }
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: child);
  }

  Widget _footerReadyDisplay() {
    Widget child;
    if (widget.footerReadyBuilder != null) {
      child = widget.footerReadyBuilder!(widget.footerLoadingOffset);
    } else {
      child = const Text("松开手开始加载");
    }
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: child);
  }

  Widget _footerLoadingDisplay() {
    Widget child;
    if (widget.footerLoadingBuilder != null) {
      child = widget.footerLoadingBuilder!(widget.footerLoadingOffset);
    } else {
      child = const Text("正在加载");
    }
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: child);
  }

  Widget _footerHasMoreDisplay() {
    Widget child;
    if (widget.footerHasMoreBuilder != null) {
      child = widget.footerHasMoreBuilder!(widget.footerLoadingOffset);
    } else {
      child = const Text("加载完成");
    }
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: child);
  }

  Widget _footerNoMoreDisplay() {
    Widget child;
    if (widget.footerNoMoreBuilder != null) {
      child = widget.footerNoMoreBuilder!(widget.footerLoadingOffset);
    } else {
      child = const Text("没有新数据啦~");
    }
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: child);
  }
}
