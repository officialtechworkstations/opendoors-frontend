class ReelProperty {
  const ReelProperty({
    this.title,
    this.address,
    this.imageUrl,
    this.price,
    this.description,
    this.ownerName,
    this.ownerId,
    this.ownerImage,
    this.beds,
    this.bathroom,
    this.latitude,
    this.longitude,
    this.status,
  });

  final String? title;
  final String? address;
  final String? imageUrl;
  final String? price;
  final String? description, ownerName, ownerId, ownerImage;
  final String? beds;
  final String? bathroom;
  final double? latitude, longitude;
  final String? status;

  bool get isUnpublished => status == '0';

  factory ReelProperty.fromJson(Map<String, dynamic> json) => ReelProperty(
        title: json['title']?.toString(),
        address: json['address']?.toString(),
        imageUrl: _imagePath(json['image_url']) ?? _imagePath(json['image']),
        price: json['price']?.toString(),
        description: (json['description'] ??
                json['property_description'] ??
                json['desc'])
            ?.toString(),
        ownerName: (json['owner_name'] ?? json['user_name'])?.toString(),
        ownerId: (json['owner_id'] ?? json['user_id'] ?? json['creator_id'])
            ?.toString(),
        ownerImage: (json['owner_image'] ?? json['user_image'])?.toString(),
        beds: json['beds']?.toString(),
        bathroom: json['bathroom']?.toString(),
        latitude: double.tryParse(json['latitude']?.toString() ?? ''),
        longitude: double.tryParse(
            (json['longitude'] ?? json['longtitude'])?.toString() ?? ''),
        status: (json['status'] ?? json['property_status'])?.toString(),
      );

  static String? _imagePath(Object? value) {
    if (value is String) {
      final path = value.trim();
      return path.isEmpty || path.startsWith('[') || path.startsWith('{')
          ? null
          : path;
    }
    if (value is List) {
      for (final item in value) {
        final path = _imagePath(item);
        if (path != null) return path;
      }
    }
    if (value is Map) {
      for (final key in ['image_url', 'image', 'img', 'path', 'url']) {
        final path = _imagePath(value[key]);
        if (path != null) return path;
      }
    }
    return null;
  }
}

class Reel {
  const Reel({
    required this.id,
    required this.propertyId,
    required this.status,
    this.videoPath,
    this.videoUrl,
    this.thumbnailPath,
    this.thumbnailUrl,
    this.processingError,
    this.property,
    this.ownerName,
    this.ownerImage,
    this.ownerId,
    this.likesCount = 0,
    this.savesCount = 0,
    this.commentsCount = 0,
    this.views = 0,
    this.hasLiked = false,
    this.hasSaved = false,
  });

  final String id;
  final String propertyId;
  final int status;
  final String? videoPath;
  final String? videoUrl;
  final String? thumbnailPath;
  final String? thumbnailUrl;
  final String? processingError;
  final ReelProperty? property;
  final String? ownerName, ownerImage, ownerId;
  final int likesCount, savesCount, commentsCount, views;
  final bool hasLiked, hasSaved;

  Reel copyWith(
          {int? likesCount,
          int? savesCount,
          int? commentsCount,
          int? views,
          bool? hasLiked,
          bool? hasSaved,
          ReelProperty? property,
          String? ownerName,
          String? ownerImage,
          String? ownerId}) =>
      Reel(
          id: id,
          propertyId: propertyId,
          status: status,
          videoPath: videoPath,
          videoUrl: videoUrl,
          thumbnailPath: thumbnailPath,
          thumbnailUrl: thumbnailUrl,
          processingError: processingError,
          property: property ?? this.property,
          ownerName: ownerName ?? this.ownerName,
          ownerImage: ownerImage ?? this.ownerImage,
          ownerId: ownerId ?? this.ownerId,
          likesCount: likesCount ?? this.likesCount,
          savesCount: savesCount ?? this.savesCount,
          commentsCount: commentsCount ?? this.commentsCount,
          views: views ?? this.views,
          hasLiked: hasLiked ?? this.hasLiked,
          hasSaved: hasSaved ?? this.hasSaved);

  bool get isProcessing => status == 0;
  bool get isReady => status == 1;
  bool get hasFailed => status == 2;
  bool get isPropertyUnpublished => property?.isUnpublished == true;

  factory Reel.fromJson(Map<String, dynamic> json) {
    final owner = _nestedMap(json, const ['owner', 'user', 'creator']);
    final property = json['property'] is Map
        ? Map<String, dynamic>.from(json['property'] as Map)
        : null;
    return Reel(
      id: json['reel_id']?.toString() ?? '',
      propertyId: json['prop_id']?.toString() ?? '',
      status: int.tryParse(json['reel_status']?.toString() ?? '') ?? 0,
      videoPath: json['video_path']?.toString(),
      videoUrl: json['video_url']?.toString(),
      thumbnailPath: json['thumbnail_path']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      processingError: json['processing_error']?.toString(),
      ownerName: _firstString(json, [
        owner,
        property
      ], const [
        'owner_name',
        'user_name',
        'username',
        'name',
      ]),
      ownerImage: _firstString(json, [
        owner,
        property
      ], const [
        'owner_image',
        'user_image',
        'profile_image',
        'avatar',
      ]),
      ownerId: _firstString(json, [
            owner,
            property
          ], const [
            'owner_id',
            'user_id',
            'creator_id',
          ]) ??
          owner?['id']?.toString(),
      likesCount: int.tryParse(json['likes_count']?.toString() ?? '') ?? 0,
      savesCount: int.tryParse(json['saves_count']?.toString() ?? '') ?? 0,
      commentsCount:
          int.tryParse(json['comments_count']?.toString() ?? '') ?? 0,
      views: int.tryParse(json['views']?.toString() ?? '') ?? 0,
      hasLiked: json['has_liked'] == true ||
          json['has_liked']?.toString() == '1' ||
          json['has_liked']?.toString() == 'true',
      hasSaved: json['has_saved'] == true ||
          json['has_saved']?.toString() == '1' ||
          json['has_saved']?.toString() == 'true',
      property: json['property'] is Map
          ? ReelProperty.fromJson({
              if (json['property_status'] != null)
                'property_status': json['property_status'],
              ...Map<String, dynamic>.from(json['property'] as Map),
            })
          : json['latitude'] != null || json['property_status'] != null
              ? ReelProperty.fromJson(json)
              : null,
    );
  }

  static Map<String, dynamic>? _nestedMap(
      Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String? _firstString(Map<String, dynamic> json,
      List<Map<String, dynamic>?> nestedMaps, List<String> keys) {
    for (final key in keys) {
      Object? value = json[key];
      for (final nested in nestedMaps) {
        value ??= nested?[key];
      }
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}

class ReelsPage {
  const ReelsPage({
    required this.reels,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<Reel> reels;
  final int nextCursor;
  final bool hasMore;
}

class ReelComment {
  const ReelComment(
      {required this.id,
      required this.userId,
      required this.text,
      required this.userName,
      this.userPic,
      this.createdAt});
  final String id, userId, text, userName;
  final String? userPic, createdAt;

  factory ReelComment.fromJson(Map<String, dynamic> json) => ReelComment(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        text: json['comment']?.toString() ?? '',
        userName: json['user_name']?.toString() ?? 'User',
        userPic: json['user_pic']?.toString(),
        createdAt: json['created_at']?.toString(),
      );
}

class ReelCommentsPage {
  const ReelCommentsPage(
      {required this.comments,
      required this.nextCursor,
      required this.hasMore});
  final List<ReelComment> comments;
  final int nextCursor;
  final bool hasMore;
}
