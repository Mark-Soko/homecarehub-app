import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/resource_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/blog/shimmer/blog_shimmer.dart';
import 'package:handyman_provider_flutter/provider/resource/view/resource_detail_screen.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/empty_error_state_widget.dart';

class ResourceListScreen extends StatefulWidget {
  final String audience; // provider | handyman

  const ResourceListScreen({Key? key, required this.audience}) : super(key: key);

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
      lastPageCallback: (b) => isLastPage = b,
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'document':
        return Icons.picture_as_pdf_outlined;
      case 'link':
        return Icons.link;
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        'Resources',
        color: context.primaryColor,
        textColor: white,
        backWidget: BackWidget(),
      ),
      body: Stack(
        children: [
          SnapHelperWidget<List<ResourceData>>(
            future: future,
            loadingWidget: BlogShimmer(),
            onSuccess: (list) {
              return AnimatedListView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(12),
                itemCount: list.length,
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                emptyWidget: NoDataWidget(title: 'No resources found', imageWidget: EmptyStateWidget()),
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
                  return 2.seconds.delay;
                },
                itemBuilder: (context, index) {
                  final data = list[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(12),
                    decoration: boxDecorationWithRoundedCorners(
                      borderRadius: radius(12),
                      backgroundColor: context.cardColor,
                      border: Border.all(color: context.dividerColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: boxDecorationWithRoundedCorners(
                            borderRadius: radius(12),
                            backgroundColor: context.primaryColor.withValues(alpha: 0.12),
                          ),
                          child: Icon(_typeIcon(data.type.validate(value: 'article')), color: context.primaryColor, size: 20),
                        ),
                        12.width,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.title.validate(), style: boldTextStyle(size: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (data.summary.validate().isNotEmpty) 6.height,
                            if (data.summary.validate().isNotEmpty) Text(data.summary.validate(), style: secondaryTextStyle(size: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            8.height,
                            Row(
                              children: [
                                if (data.publishDate.validate().isNotEmpty) Text(data.publishDate.validate(), style: secondaryTextStyle(size: 10)),
                                if (data.tags.validate().isNotEmpty) 8.width,
                                if (data.tags.validate().isNotEmpty)
                                  Text(
                                    data.tags!.take(2).join(' • '),
                                    style: secondaryTextStyle(size: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ).expand(),
                              ],
                            ),
                          ],
                        ).expand(),
                        8.width,
                        Icon(Icons.chevron_right, color: context.iconColor),
                      ],
                    ),
                  ).onTap(() {
                    ResourceDetailScreen(resourceId: data.id.validate()).launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
                  });
                },
              );
            },
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: languages.reload,
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

