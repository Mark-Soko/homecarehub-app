import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/resource_model.dart';
import 'package:booking_system_flutter/screens/blog/shimmer/blog_shimmer.dart';
import 'package:booking_system_flutter/screens/resource/component/resource_item_component.dart';
import 'package:booking_system_flutter/screens/blog/blog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/base_scaffold_widget.dart';
import '../../../component/empty_error_state_widget.dart';
import '../../../component/loader_widget.dart';

class ResourceListScreen extends StatefulWidget {
  final String audience; // provider | handyman

  const ResourceListScreen({super.key, required this.audience});

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  Future<List<ResourceData>>? future;
  List<ResourceData> resourceList = [];

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    future = getResourceListAPI(
      audience: widget.audience,
      resourceData: resourceList,
      page: page,
      lastPageCallback: (b) {
        isLastPage = b;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: 'Resources',
      showLoader: false,
      child: Stack(
        children: [
          SnapHelperWidget<List<ResourceData>>(
            future: future,
            loadingWidget: BlogShimmer(),
            onSuccess: (snap) {
              return AnimatedListView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(8),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                itemCount: snap.length,
                emptyWidget: NoDataWidget(title: 'No resources found', imageWidget: EmptyStateWidget()),
                shrinkWrap: true,
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    appStore.setLoading(true);
                    init();
                    setState(() {});
                  }
                },
                onSwipeRefresh: () async {
                  page = 1;
                  init();
                  setState(() {});
                  return await 2.seconds.delay;
                },
                disposeScrollController: true,
                itemBuilder: (BuildContext context, index) {
                  return ResourceItemComponent(data: snap[index]);
                },
              );
            },
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: language.reload,
                onRetry: () {
                  page = 1;
                  appStore.setLoading(true);
                  init();
                  setState(() {});
                },
              );
            },
          ),
          Observer(builder: (_) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}

