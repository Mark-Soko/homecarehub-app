import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/resource_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/empty_error_state_widget.dart';

class ResourceDetailScreen extends StatefulWidget {
  final int resourceId;

  const ResourceDetailScreen({Key? key, required this.resourceId}) : super(key: key);

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  Future<ResourceData>? future;

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      appBar: appBarWidget(
        'Resource',
        color: context.primaryColor,
        textColor: white,
        backWidget: BackWidget(),
      ),
      body: SnapHelperWidget<ResourceData>(
        future: future,
        loadingWidget: Loader(),
        onSuccess: (data) {
          return AnimatedScrollView(
            padding: EdgeInsets.only(bottom: 120),
            listAnimationType: ListAnimationType.FadeIn,
            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
            children: [
              12.height,
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
            retryText: languages.reload,
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

