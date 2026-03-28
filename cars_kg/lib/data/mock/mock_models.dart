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
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String location;
  final List<String> imageUrls;
  final String category;
  final bool isFavorite;
  final MarketplaceUser owner;
  final DateTime createdAt;
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
