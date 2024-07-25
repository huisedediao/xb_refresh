// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:xb_scaffold/xb_scaffold.dart';
import 'xb_refresh.dart';
import 'xb_refresh_controller.dart';

class XBRefreshDemo extends StatefulWidget {
  const XBRefreshDemo({super.key});

  @override
  _XBRefreshDemoState createState() => _XBRefreshDemoState();
}

class _XBRefreshDemoState extends State<XBRefreshDemo> {
  final ScrollController _controller = ScrollController();

  final XBRefreshController xbRefreshController = XBRefreshController();

  int _itemCount = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("xb refresh demo"),
          actions: [
            XBButton(
                onTap: () {
                  xbRefreshController.refresh();
                },
                child: Container(
                  color: Colors.transparent,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("开始刷新"),
                  ),
                )),
          ],
        ),
        body: Container(
          height: screenH * 0.8,
          width: screenW * 0.8,
          color: colors.randColor,
          child: XBRefresh(
            controller: xbRefreshController,
            needLoadMore: true,
            needRefresh: true,
            initRefresh: true,
            // needShowComplete: true,
            // needShowHasMoreFooter: true,

            ///开始加载更多的回调
            onBeginLoadMore: () {
              Future.delayed(const Duration(seconds: 2), () {
                bool hasMore = false;
                if (_itemCount < 20) {
                  hasMore = true;
                  setState(() {
                    _itemCount += 2;
                  });
                }

                ///结束加载更多，传是否有新数据
                xbRefreshController.endLoadMore(hasMore);
              });
            },
            onBeginRefresh: () {
              Future.delayed(const Duration(seconds: 1), () {
                setState(() {
                  _itemCount = 10;
                });
                xbRefreshController.endRefresh();
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
            // child: ListView.builder(
            //   controller: _controller,
            //   itemCount: _itemCount,
            //   itemBuilder: (context, index) {
            //     return Cell("$index", () {});
            //   },
            // ),
            child: Container(
              height: screenH * 0.5,
              color: colors.randColor,
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _controller.dispose();
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
