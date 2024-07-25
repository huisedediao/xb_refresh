// ignore_for_file: sized_box_for_whitespace, deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'xb_refresh_config.dart';

class XBRefreshHeader extends StatefulWidget {
  final Widget child;
  final VoidCallback? onBeginRefresh;
  final XBRefreshBuilder? headerBeforeBuilder;
  final XBRefreshBuilder? headerReadyBuilder;
  final XBRefreshBuilder? headerLoadingBuilder;
  final XBRefreshBuilder? headerCompleteBuilder;
  final bool needShowComplete;

  ///初始状态要不要显示正在刷新
  final bool initRefresh;

  ///大于这个值可以刷新,也用于限制header的高度
  final double headerLoadingOffset;

  const XBRefreshHeader(
      {required this.child,
      this.onBeginRefresh,
      this.headerBeforeBuilder,
      this.headerReadyBuilder,
      this.headerLoadingBuilder,
      this.headerCompleteBuilder,
      this.headerLoadingOffset = 60.0,
      this.needShowComplete = false,
      this.initRefresh = false,
      Key? key})
      : super(key: key);

  @override
  XBRefreshHeaderState createState() => XBRefreshHeaderState();
}

class XBRefreshHeaderState extends State<XBRefreshHeader>
    with SingleTickerProviderStateMixin {
  late XBHeaderBuilderVM _headerBuilderVM;
  late XBHeaderPositionVM _headerOffsetVM;
  bool _isUserAction = false;
  double _lastOffset = 0;
  bool _isInProcess = false;
  bool _isCompleted = false;

  ///结束刷新
  endRefresh() {
    if (_headerBuilderVM.state == XBRefreshState.loading) {
      if (widget.needShowComplete) {
        _headerBuilderVM.state = XBRefreshState.complete;
        Future.delayed(const Duration(seconds: 1), () {
          _afterComplete();
        });
      } else {
        _afterComplete();
      }
    }
  }

  refresh() {
    if (_headerBuilderVM.state == XBRefreshState.loading) {
      return;
    }
    _isInProcess = true;
    _headerBuilderVM.state = XBRefreshState.loading;
    _headerOffsetVM.top = 0;
    if (widget.onBeginRefresh != null) {
      widget.onBeginRefresh!();
    }
  }

  receiveOffset(double offset) {
    bool upward = offset > _lastOffset;
    _lastOffset = offset;

    if (offset < 0) {
      ///已完成刷新但是还在流程里，说明没有等到非用户操作的offset = 0
      if (_isCompleted && _isInProcess) return;

      if (_isInProcess == false && _isUserAction) {
        ///进入流程
        _isInProcess = true;
      }

      if (_headerBuilderVM.state == XBRefreshState.loading ||
          _headerBuilderVM.state == XBRefreshState.complete) {
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
      _headerOffsetVM.top = top;

      if (upward) {
        if (_isUserAction) {
          _headerUserActionRun(fitOffset);
        } else {
          _headerBuilderVM.state = XBRefreshState.before;
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

    _headerBuilderVM = XBHeaderBuilderVM();
    _headerOffsetVM = XBHeaderPositionVM(-widget.headerLoadingOffset);

    if (widget.initRefresh) {
      refresh();
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

              if (_headerBuilderVM.state == XBRefreshState.ready) {
                _headerBuilderVM.state = XBRefreshState.loading;
                if (widget.onBeginRefresh != null) {
                  widget.onBeginRefresh!();
                }
              }
            },
            child: widget.child),
        ChangeNotifierProvider(
          create: (ctx) {
            return _headerBuilderVM;
          },
          child: Consumer(builder: (ctx, XBHeaderBuilderVM vm, child) {
            Widget child;
            if (vm.state == XBRefreshState.before) {
              child = _headerBeforeDispaly();
            } else if (vm.state == XBRefreshState.ready) {
              child = _headerReadyDispaly();
            } else if (vm.state == XBRefreshState.loading) {
              child = _headerLoadingDispaly();
            } else if (vm.state == XBRefreshState.complete) {
              child = _headerCompleteDispaly();
            } else {
              child = Container();
            }
            return ChangeNotifierProvider(
              create: (ctx) {
                return _headerOffsetVM;
              },
              child: Consumer(
                builder: (ctx, XBHeaderPositionVM vm, reChild) {
                  return Positioned(
                    top: vm.top,
                    left: 0,
                    right: 0,
                    child: Container(
                      //                        color: Colors.grey,
                      height: widget.headerLoadingOffset,
                      child: reChild,
                    ),
                  );
                },
                child: child,
              ),
            );
          }),
        ),
      ],
    );
  }

  _afterComplete() {
    _headerBuilderVM.state = XBRefreshState.before;
    if (_headerOffsetVM.top != -widget.headerLoadingOffset) {
      _headerOffsetVM.top = -widget.headerLoadingOffset;
    }
    _isCompleted = true;
    _endProcessIfPossible();
  }

  _endProcessIfPossible() {
    if (_isUserAction == false &&
        _lastOffset >= 0 &&
        _isInProcess == true &&
        _isCompleted == true) {
      _isInProcess = false;
      _isCompleted = false;
    }
  }

  _headerUserActionRun(double fitOffset) {
    if (fitOffset >= widget.headerLoadingOffset) {
      _headerBuilderVM.state = XBRefreshState.ready;
    } else {
      _headerBuilderVM.state = XBRefreshState.before;
    }
  }

  Widget _headerBeforeDispaly() {
    Widget child;
    if (widget.headerBeforeBuilder != null) {
      child = widget.headerBeforeBuilder!(widget.headerLoadingOffset);
    } else {
      child = _buildArrow(false);
    }

    return Container(
        // color: Colors.orange,
        alignment: Alignment.center,
        height: widget.headerLoadingOffset,
        child: child);
  }

  Widget _headerReadyDispaly() {
    Widget child;
    if (widget.headerReadyBuilder != null) {
      child = widget.headerReadyBuilder!(widget.headerLoadingOffset);
    } else {
      child = _buildArrow(true);
    }
    return Container(
//        color: Colors.orange,
        alignment: Alignment.center,
        height: widget.headerLoadingOffset,
        child: child);
  }

  Widget _headerLoadingDispaly() {
    Widget child;
    if (widget.headerLoadingBuilder != null) {
      child = widget.headerLoadingBuilder!(widget.headerLoadingOffset);
    } else {
      child = _buildActivityIndicator();
    }
    return Container(
//        color: Colors.orange,
        alignment: Alignment.center,
        height: widget.headerLoadingOffset,
        child: child);
  }

  Widget _headerCompleteDispaly() {
    Widget child;
    if (widget.headerCompleteBuilder != null) {
      child = widget.headerCompleteBuilder!(widget.headerLoadingOffset);
    } else {
      child = _buildActivityIndicator();
    }
    return Container(
//        color: Colors.orange,
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

class XBHeaderPositionVM extends ChangeNotifier {
  double _top;

  double get top => _top;

  set top(double offset) {
    _top = offset;
    notifyListeners();
  }

  XBHeaderPositionVM(this._top);
}

class XBHeaderBuilderVM extends ChangeNotifier {
  XBRefreshState _state = XBRefreshState.before;

  XBRefreshState get state => _state;

  set state(XBRefreshState on) {
    _state = on;
    notifyListeners();
  }
}
