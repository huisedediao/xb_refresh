// ignore_for_file: library_private_types_in_public_api

import 'package:xb_scaffold/xb_scaffold.dart';
import 'xb_refresh.dart';

class XBRefreshDemo extends XBPage<XBRefreshDemoVM> {
  const XBRefreshDemo({super.key});

  @override
  generateVM(BuildContext context) {
    return XBRefreshDemoVM(context: context);
  }

  @override
  bool needShowContentFromScreenTop(XBRefreshDemoVM vm) {
    return true;
  }

  @override
  List<Widget>? actions(XBRefreshDemoVM vm) {
    return [
      XBButton(
          onTap: () {
            vm.xbRefreshController.refresh();
          },
          child: Container(
            color: Colors.transparent,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("开始刷新"),
            ),
          )),
    ];
  }

  @override
  Widget buildPage(vm, BuildContext context) {
    return Container(
      height: screenH * 0.8,
      // width: screenW * 0.8,
      color: colors.randColor,
      child: XBRefresh(
        controller: vm.xbRefreshController,
        needLoadMore: true,
        needRefresh: true,
        initRefresh: true,

        ///开始加载更多的回调
        onLoadMore: () {
          Future.delayed(const Duration(seconds: 2), () {
            bool hasMore = false;
            if (vm.itemCount < 20) {
              hasMore = true;
              vm.itemCount += 2;
              vm.notify();
            }

            ///结束加载更多，传是否有新数据
            vm.xbRefreshController.endLoadMore(hasMore);
          });
        },
        onRefresh: () {
          Future.delayed(const Duration(seconds: 1), () {
            vm.itemCount = 10;
            vm.xbRefreshController.endRefresh();
            vm.notify();
          });
        },
        headerCompleteBuilder: (height) {
          return Container(
            height: height,
            color: Colors.red,
            child: const Center(
              child: Text("完成刷新"),
            ),
          );
        },
        footerHasMoreBuilder: (height) {
          return Container(
            height: height,
            color: Colors.green,
            child: const Center(
              child: Text("拉取新数据完成"),
            ),
          );
        },
        // child: CustomScrollView(
        //   controller: _controller,
        //   slivers: <Widget>[
        //     SliverList(
        //         delegate: SliverChildBuilderDelegate((ctx, index) {
        //       return Cell("$index", () {});
        //     }, childCount: _itemCount))
        //   ],
        // )
        child: ListView.builder(
          controller: vm.controller,
          itemCount: vm.itemCount,
          itemBuilder: (context, index) {
            return Cell("$index", () {});
          },
        ),
        // child: Container(
        //   height: screenH * 0.5,
        //   color: colors.randColor,
        // ),
      ),
    );
  }
}

class XBRefreshDemoVM extends XBPageVM<XBRefreshDemo> {
  XBRefreshDemoVM({required super.context}) {
    controller.addListener(listenFun);
  }
  final ScrollController controller = ScrollController();
  final XBRefreshController xbRefreshController = XBRefreshController();

  int itemCount = 10;

  void listenFun() {
    xbError("controller.offset:${controller.offset}");
  }

  @override
  void dispose() {
    controller.removeListener(listenFun);
    controller.dispose();
    super.dispose();
  }
}

class Cell extends StatelessWidget {
  static const height = 44.0;
  final String title;
  final VoidCallback onPressed;

  const Cell(this.title, this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        color: Colors.black38,
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            Expanded(
                child: Center(
                    child: Text(title,
                        style: const TextStyle(color: Colors.white)))),
            Container(
              height: 1,
              color: Colors.white,
            )
          ],
        ),
      ),
    );
  }
}
