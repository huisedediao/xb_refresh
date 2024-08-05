import 'package:flutter/material.dart';
import 'xb_refresh_footer.dart';
import 'xb_refresh_header.dart';

class XBRefreshController {
  final GlobalKey<XBRefreshFooterState> loadMoreKey = GlobalKey();
  final GlobalKey<XBRefreshHeaderState> refreshKey = GlobalKey();

  int _refreshSemaphore = 0;

  refresh() {
    if (refreshKey.currentState?.isInProcess ?? false) {
      _refreshSemaphore++;
    } else {
      refreshKey.currentState?.refresh();
    }
  }

  endRefresh() {
    if (_refreshSemaphore > 0) {
      refreshKey.currentState?.callRefresh();
      _refreshSemaphore--;
    } else {
      refreshKey.currentState?.endRefresh();
    }
  }

  endLoadMore(bool hasMore) => loadMoreKey.currentState?.endLoadMore(hasMore);
}
