import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/resource_model.dart';
import 'package:booking_system_flutter/screens/blog/blog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../component/empty_error_state_widget.dart';

class ResourceDetailScreen extends StatefulWidget {
  final int resourceId;

  const ResourceDetailScreen({super.key, required this.resourceId});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  Future<ResourceData>? future;

  @override
  void initState() {
    super.initState();
    setStatusBarColor(transparentColor, delayInMilliSeconds: 600);
    init();
  }

  void init() async {
    future = getResourceDetailAPI(resourceId: widget.resourceId.validate(), viewerId: appStore.isLoggedIn ? appStore.userId : null);
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: 'Resource',
      child: SnapHelperWidget<ResourceData>(
        future: future,
        loadingWidget: Loader(),
        onSuccess: (data) {
          return AnimatedScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            listAnimationType: ListAnimationType.FadeIn,
            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
            padding: EdgeInsets.only(bottom: 120),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              8.height,
              Text(data.title.validate(), style: boldTextStyle(size: 20)).paddingSymmetric(horizontal: 16),
              8.height,
              Row(
                children: [
                  if (data.publishDate.validate().isNotEmpty) Text(data.publishDate.validate(), style: secondaryTextStyle()),
                  if (data.type.validate().isNotEmpty) 8.width,
                  if (data.type.validate().isNotEmpty) Text(data.type.validate().capitalizeFirstLetter(), style: secondaryTextStyle(size: 12)),
                ],
              ).paddingSymmetric(horizontal: 16),
              if (data.tags.validate().isNotEmpty) 12.height,
              if (data.tags.validate().isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.tags!.map((t) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: context.primaryColor.withValues(alpha: 0.10),
                        borderRadius: radius(20),
                      ),
                      child: Text(t, style: secondaryTextStyle(size: 12, color: context.primaryColor)),
                    );
                  }).toList(),
                ).paddingSymmetric(horizontal: 16),
              if (data.externalUrl.validate().isNotEmpty) 16.height,
              if (data.externalUrl.validate().isNotEmpty)
                AppButton(
                  text: 'Open Link',
                  color: context.primaryColor,
                  textColor: white,
                  onTap: () => _openExternal(data.externalUrl.validate()),
                ).paddingSymmetric(horizontal: 16),
              16.height,
              if (data.summary.validate().isNotEmpty) Text(data.summary.validate(), style: secondaryTextStyle()).paddingSymmetric(horizontal: 16),
              if (data.summary.validate().isNotEmpty) 16.height,
              Html(
                data: data.body.validate(),
                style: {
                  "span": Style(color: appStore.isDarkMode ? Colors.white : Colors.black),
                  "body": Style(color: appStore.isDarkMode ? Colors.white : Colors.black),
                },
              ).paddingSymmetric(horizontal: 16),
            ],
          );
        },
        errorBuilder: (error) {
          return NoDataWidget(
            title: error,
            imageWidget: ErrorStateWidget(),
            retryText: language.reload,
            onRetry: () {
              init();
              setState(() {});
            },
          );
        },
      ),
    );
  }
}

