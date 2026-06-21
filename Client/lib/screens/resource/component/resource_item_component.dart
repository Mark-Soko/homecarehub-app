import 'package:booking_system_flutter/model/resource_model.dart';
import 'package:booking_system_flutter/screens/resource/view/resource_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ResourceItemComponent extends StatelessWidget {
  final ResourceData data;

  const ResourceItemComponent({super.key, required this.data});

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
  }
}

