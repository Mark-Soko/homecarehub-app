import 'package:booking_system_flutter/model/pagination_model.dart';

class ResourceListResponse {
  Pagination? pagination;
  List<ResourceData>? data;

  ResourceListResponse({this.pagination, this.data});

  factory ResourceListResponse.fromJson(Map<String, dynamic> json) {
    List<ResourceData>? dataList;
    if (json['data'] != null && json['data'] is List) {
      dataList = (json['data'] as List)
          .map((i) => ResourceData.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList();
    }
    return ResourceListResponse(
      data: dataList,
      pagination: json['pagination'] != null && json['pagination'] is Map
          ? Pagination.fromJson(Map<String, dynamic>.from(json['pagination'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      data['pagination'] = pagination!.toJson();
    }
    return data;
  }
}

class ResourceData {
  int? id;
  String? title;
  String? slug;
  String? summary;
  String? body;
  String? type;
  String? format;
  int? audience;
  bool? isFeatured;
  int? status;
  List<String>? tags;
  int? totalViews;
  String? externalUrl;
  Map<String, dynamic>? meta;
  int? createdBy;
  String? creatorName;
  String? creatorImage;
  String? publishDate;
  String? publishedAt;
  String? deletedAt;
  String? createdAt;

  ResourceData({
    this.id,
    this.title,
    this.slug,
    this.summary,
    this.body,
    this.type,
    this.format,
    this.audience,
    this.isFeatured,
    this.status,
    this.tags,
    this.totalViews,
    this.externalUrl,
    this.meta,
    this.createdBy,
    this.creatorName,
    this.creatorImage,
    this.publishDate,
    this.publishedAt,
    this.deletedAt,
    this.createdAt,
  });

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  factory ResourceData.fromJson(Map<String, dynamic> json) {
    return ResourceData(
      id: _toInt(json['id']),
      title: json['title']?.toString(),
      slug: json['slug']?.toString(),
      summary: json['summary']?.toString(),
      body: json['body']?.toString(),
      type: json['type']?.toString(),
      format: json['format']?.toString(),
      audience: _toInt(json['audience']),
      isFeatured: json['is_featured'] == true,
      status: _toInt(json['status']),
      tags: json['tags'] != null ? List<String>.from((json['tags'] is List ? json['tags'] : []).map((x) => x.toString())) : null,
      totalViews: _toInt(json['total_views']),
      externalUrl: json['external_url']?.toString(),
      meta: json['meta'] is Map ? Map<String, dynamic>.from(json['meta'] as Map) : null,
      createdBy: _toInt(json['created_by']),
      creatorName: json['creator_name']?.toString(),
      creatorImage: json['creator_image']?.toString(),
      publishDate: json['publish_date']?.toString(),
      publishedAt: json['published_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['summary'] = summary;
    data['body'] = body;
    data['type'] = type;
    data['format'] = format;
    data['audience'] = audience;
    data['is_featured'] = isFeatured;
    data['status'] = status;
    data['tags'] = tags;
    data['total_views'] = totalViews;
    data['external_url'] = externalUrl;
    data['meta'] = meta;
    data['created_by'] = createdBy;
    data['creator_name'] = creatorName;
    data['creator_image'] = creatorImage;
    data['publish_date'] = publishDate;
    data['published_at'] = publishedAt;
    data['deleted_at'] = deletedAt;
    data['created_at'] = createdAt;
    return data;
  }
}

