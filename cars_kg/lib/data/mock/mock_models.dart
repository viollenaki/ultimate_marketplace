class MarketplaceUser {
  const MarketplaceUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.city,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String city;
}

/// Vehicle listing (aligned with backend `listings` car fields).
class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.location,
    required this.imageUrls,
    required this.isFavorite,
    required this.owner,
    required this.createdAt,
    required this.brand,
    required this.model,
    required this.year,
    required this.mileage,
    this.fuelType,
    this.transmission,
    this.bodyType,
    this.exteriorColor,
    this.interiorColor,
    this.isVip = false,
    this.priceUsdApprox,
    this.isCrashed = false,
    this.openToTrade = false,
    this.sellerIsDealer = false,
    this.latitude,
    this.longitude,
    this.locationDisplayName,
    this.viewCount = 0,
    this.favoriteCount = 0,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String location;
  final List<String> imageUrls;
  final bool isFavorite;
  final MarketplaceUser owner;
  final DateTime createdAt;
  final String brand;
  final String model;
  final int year;
  final int mileage;
  final String? fuelType;
  final String? transmission;
  final String? bodyType;
  final String? exteriorColor;
  final String? interiorColor;
  final bool isVip;
  final double? priceUsdApprox;
  final bool isCrashed;
  final bool openToTrade;
  final bool sellerIsDealer;
  final double? latitude;
  final double? longitude;
  final String? locationDisplayName;
  /// From API `view_count` (detail increments for non-owners).
  final int viewCount;
  /// From API `favorite_count` (how many users saved this listing).
  final int favoriteCount;

  Listing copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? currency,
    String? location,
    List<String>? imageUrls,
    bool? isFavorite,
    MarketplaceUser? owner,
    DateTime? createdAt,
    String? brand,
    String? model,
    int? year,
    int? mileage,
    String? fuelType,
    String? transmission,
    String? bodyType,
    String? exteriorColor,
    String? interiorColor,
    bool? isVip,
    double? priceUsdApprox,
    bool? isCrashed,
    bool? openToTrade,
    bool? sellerIsDealer,
    double? latitude,
    double? longitude,
    String? locationDisplayName,
    int? viewCount,
    int? favoriteCount,
  }) {
    return Listing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      isFavorite: isFavorite ?? this.isFavorite,
      owner: owner ?? this.owner,
      createdAt: createdAt ?? this.createdAt,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      bodyType: bodyType ?? this.bodyType,
      exteriorColor: exteriorColor ?? this.exteriorColor,
      interiorColor: interiorColor ?? this.interiorColor,
      isVip: isVip ?? this.isVip,
      priceUsdApprox: priceUsdApprox ?? this.priceUsdApprox,
      isCrashed: isCrashed ?? this.isCrashed,
      openToTrade: openToTrade ?? this.openToTrade,
      sellerIsDealer: sellerIsDealer ?? this.sellerIsDealer,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationDisplayName: locationDisplayName ?? this.locationDisplayName,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
    );
  }
}

class PopularBrand {
  const PopularBrand({required this.name, this.logoAsset});

  final String name;
  /// Flutter asset path (e.g. `assets/car_logos/bmw.png`).
  final String? logoAsset;
}

class ConversationPreview {
  const ConversationPreview({
    required this.id,
    required this.peer,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
  });

  final String id;
  final MarketplaceUser peer;
  final String lastMessage;
  final DateTime time;
  final int unreadCount;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.attachmentLabel,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final String? attachmentLabel;
}

class PromotionPaymentEntry {
  const PromotionPaymentEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String status;
}
