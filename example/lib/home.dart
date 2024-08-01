import 'package:xb_refresh/xb_refresh.dart';
import 'package:xb_scaffold/xb_scaffold.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topBarH),
      child: Container(
        height: screenH * 0.8,
        width: screenW * 0.8,
        color: colors.randColor,
        child: XBRefresh(
          controller: xbRefreshController,
          needLoadMore: true,
          needRefresh: true,
          initRefresh: true,

          ///开始加载更多的回调
          onLoadMore: () {
            Future.delayed(const Duration(seconds: 2), () {
              bool hasMore = false;
              if (itemCount < 20) {
                hasMore = true;
                itemCount += 2;
                setState(() {});
              }

              ///结束加载更多，传是否有新数据
              xbRefreshController.endLoadMore(hasMore);
            });
          },
          onRefresh: () {
            Future.delayed(const Duration(seconds: 1), () {
              itemCount = 10;
              xbRefreshController.endRefresh();
              setState(() {});
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
            // controller: controller,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return Container(
                  height: 50, color: colors.randColor, child: Text("$index"));
            },
          ),
          // child: Container(
          //   height: screenH * 0.5,
          //   color: colors.randColor,
          // ),
        ),
      ),
    );
  }
}
