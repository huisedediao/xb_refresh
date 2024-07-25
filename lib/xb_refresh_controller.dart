import 'package:flutter/material.dart';
import 'xb_refresh_footer.dart';
import 'xb_refresh_header.dart';

class XBRefreshController {
  final GlobalKey<XBRefreshFooterState> loadMoreKey = GlobalKey();
  final GlobalKey<XBRefreshHeaderState> refreshKey = GlobalKey();

  refresh() {
    refreshKey.currentState?.refresh();
  }

  endRefresh() {
    if (refreshKey.currentState != null) {
      refreshKey.currentState?.endRefresh();
    }
  }

  endLoadMore(bool hasMore) {
    if (loadMoreKey.currentState != null) {
      loadMoreKey.currentState?.endLoadMore(hasMore);
    }
  }
}
