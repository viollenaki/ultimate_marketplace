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
    required this.category,
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
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String location;
  final List<String> imageUrls;
  /// Browse bucket: "All", "New cars", "Used", "Parts", etc.
  final String category;
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
}

class CarBrowseCategory {
  const CarBrowseCategory({
    required this.id,
    required this.titleKey,
    required this.imageUrl,
    required this.listingCount,
  });

  final String id;
  final String titleKey;
  final String imageUrl;
  final int listingCount;
}

class PopularBrand {
  const PopularBrand({required this.name, this.logoUrl});

  final String name;
  final String? logoUrl;
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
