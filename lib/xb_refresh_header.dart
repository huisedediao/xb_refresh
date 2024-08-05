import 'package:flutter/cupertino.dart';
import 'xb_refresh_config.dart';

class XBRefreshHeader extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRefresh;
  final XBRefreshBuilder? headerBeforeBuilder;
  final XBRefreshBuilder? headerReadyBuilder;
  final XBRefreshBuilder? headerLoadingBuilder;
  final XBRefreshBuilder? headerCompleteBuilder;
  final bool needShowComplete;

  /// 初始状态要不要显示正在刷新
  final bool initRefresh;

  /// 初始状态显示刷新的情况下，要不要延迟调用刷新回调
  final bool initRefreshDelay;

  /// 大于这个值可以刷新,也用于限制header的高度
  final double headerLoadingOffset;

  /// delay call loadmore
  final int delayCallRefreshMilliseconds;

  const XBRefreshHeader(
      {required this.child,
      this.onRefresh,
      this.headerBeforeBuilder,
      this.headerReadyBuilder,
      this.headerLoadingBuilder,
      this.headerCompleteBuilder,
      this.headerLoadingOffset = 60.0,
      this.needShowComplete = false,
      this.initRefresh = false,
      this.initRefreshDelay = true,
      this.delayCallRefreshMilliseconds = 0,
      Key? key})
      : super(key: key);

  @override
  XBRefreshHeaderState createState() => XBRefreshHeaderState();
}

class XBRefreshHeaderState extends State<XBRefreshHeader>
    with SingleTickerProviderStateMixin {
  XBRefreshState _headerState = XBRefreshState.before;
  double _headerTopPadding = 0.0;
  bool _isUserAction = false;
  double _lastOffset = 0;
  bool _isInProcess = false;
  bool _isCompleted = false;

  ///结束刷新
  endRefresh() {
    if (_headerState == XBRefreshState.loading) {
      if (widget.needShowComplete) {
        setState(() {
          _headerState = XBRefreshState.complete;
        });
        Future.delayed(const Duration(seconds: 1), () {
          _afterComplete();
        });
      } else {
        _afterComplete();
      }
    }
  }

  bool get isInProcess => _isInProcess;

  refresh([bool isInitRefresh = false]) {
    if (_headerState == XBRefreshState.loading) {
      return;
    }
    setState(() {
      _isInProcess = true;
      _headerState = XBRefreshState.loading;
      _headerTopPadding = 0;
    });
    _callRefresh(!isInitRefresh || widget.initRefreshDelay);
  }

  /// 供外部使用
  /// 立即调用刷新函数
  callRefresh() => _callRefresh(false);

  _callRefresh(bool isNeedDelay) {
    if (widget.onRefresh != null) {
      if (isNeedDelay) {
        Future.delayed(
            Duration(milliseconds: widget.delayCallRefreshMilliseconds), () {
          widget.onRefresh!();
        });
      } else {
        widget.onRefresh!();
      }
    }
  }

  receiveOffset(double offset) {
    bool upward = offset > _lastOffset;
    _lastOffset = offset;

    if (offset < 0) {
      if (_isCompleted && _isInProcess) return;

      if (_isInProcess == false && _isUserAction) {
        _isInProcess = true;
      }

      if (_headerState == XBRefreshState.loading ||
          _headerState == XBRefreshState.complete) {
        return;
      }

      double fitOffset = 0 - offset;
      if (fitOffset <= 0) {
        return;
      }
      double top = -widget.headerLoadingOffset + fitOffset;
      if (top > 0) {
        top = 0;
      }
      setState(() {
        _headerTopPadding = top;
      });

      if (upward) {
        if (_isUserAction) {
          _headerUserActionRun(fitOffset);
        } else {
          setState(() {
            _headerState = XBRefreshState.before;
          });
        }
      } else {
        if (_isUserAction) {
          _headerUserActionRun(fitOffset);
        }
      }
    } else {
      _endProcessIfPossible();
    }
  }

  @override
  void initState() {
    super.initState();
    _headerTopPadding = -widget.headerLoadingOffset;

    if (widget.initRefresh) {
      refresh(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Listener(
          onPointerDown: (detail) {
            _isUserAction = true;
          },
          onPointerUp: (detail) {
            _isUserAction = false;

            _endProcessIfPossible();

            if (_headerState == XBRefreshState.ready) {
              setState(() {
                _headerState = XBRefreshState.loading;
              });
              _callRefresh(true);
            }
          },
          child: widget.child,
        ),
        Positioned(
          top: _headerTopPadding,
          left: 0,
          right: 0,
          child: SizedBox(
            height: widget.headerLoadingOffset,
            child: _buildHeaderContent(),
          ),
        ),
      ],
    );
  }

  _afterComplete() {
    setState(() {
      _headerState = XBRefreshState.before;
      _headerTopPadding = -widget.headerLoadingOffset;
      _isCompleted = true;
    });
    _endProcessIfPossible();
  }

  _endProcessIfPossible() {
    if (_isUserAction == false &&
        _lastOffset >= 0 &&
        _isInProcess == true &&
        _isCompleted == true) {
      setState(() {
        _isInProcess = false;
        _isCompleted = false;
      });
    }
  }

  _headerUserActionRun(double fitOffset) {
    if (fitOffset >= widget.headerLoadingOffset) {
      setState(() {
        _headerState = XBRefreshState.ready;
      });
    } else {
      setState(() {
        _headerState = XBRefreshState.before;
      });
    }
  }

  Widget _buildHeaderContent() {
    Widget child;
    switch (_headerState) {
      case XBRefreshState.before:
        child = _headerBeforeDisplay();
        break;
      case XBRefreshState.ready:
        child = _headerReadyDisplay();
        break;
      case XBRefreshState.loading:
        child = _headerLoadingDisplay();
        break;
      case XBRefreshState.complete:
        child = _headerCompleteDisplay();
        break;
      default:
        child = Container();
        break;
    }
    return child;
  }

  Widget _headerBeforeDisplay() {
    Widget child;
    if (widget.headerBeforeBuilder != null) {
      child = widget.headerBeforeBuilder!(widget.headerLoadingOffset);
    } else {
      child = _buildArrow(false);
    }

    return Container(
        alignment: Alignment.center,
        height: widget.headerLoadingOffset,
        child: child);
  }

  Widget _headerReadyDisplay() {
    Widget child;
    if (widget.headerReadyBuilder != null) {
      child = widget.headerReadyBuilder!(widget.headerLoadingOffset);
    } else {
      child = _buildArrow(true);
    }
    return Container(
        alignment: Alignment.center,
        height: widget.headerLoadingOffset,
        child: child);
  }

  Widget _headerLoadingDisplay() {
    Widget child;
    if (widget.headerLoadingBuilder != null) {
      child = widget.headerLoadingBuilder!(widget.headerLoadingOffset);
    } else {
      child = _buildActivityIndicator();
    }
    return Container(
        alignment: Alignment.center,
        height: widget.headerLoadingOffset,
        child: child);
  }

  Widget _headerCompleteDisplay() {
    Widget child;
    if (widget.headerCompleteBuilder != null) {
      child = widget.headerCompleteBuilder!(widget.headerLoadingOffset);
    } else {
      child = _buildActivityIndicator();
    }
    return Container(
        alignment: Alignment.center,
        height: widget.headerLoadingOffset,
        child: child);
  }

  _buildArrow(bool upward) {
    String title = upward ? "↑" : "↓";
    return Text(
      title,
      style: const TextStyle(fontSize: 25),
    );
  }

  _buildActivityIndicator({bool animating = true}) {
    double width = 30;
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.5),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)]),
      width: width,
      height: width,
      alignment: Alignment.center,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(width * 0.5),
          child: Container(
              color: Colors.white,
              height: width,
              width: width,
              child: CupertinoActivityIndicator(
                animating: animating,
              ))),
    );
  }
}
