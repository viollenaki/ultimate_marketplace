import 'mock_models.dart';

const mockCategories = [
  'Cars',
  'Apartments',
  'Electronics',
  'Services',
  'Jobs',
  'Home',
  'Fashion',
  'Kids',
];

const currentUserId = 'u_me';

final currentUser = MarketplaceUser(
  id: currentUserId,
  name: 'Ainura Bekova',
  avatarUrl: 'https://i.pravatar.cc/180?img=23',
  city: 'Bishkek',
);

final mockUsers = [
  currentUser,
  const MarketplaceUser(
    id: 'u_1',
    name: 'Bakyt Sadykov',
    avatarUrl: 'https://i.pravatar.cc/180?img=12',
    city: 'Bishkek',
  ),
  const MarketplaceUser(
    id: 'u_2',
    name: 'Elina Askarova',
    avatarUrl: 'https://i.pravatar.cc/180?img=47',
    city: 'Osh',
  ),
  const MarketplaceUser(
    id: 'u_3',
    name: 'Maksat Karimov',
    avatarUrl: 'https://i.pravatar.cc/180?img=7',
    city: 'Karakol',
  ),
];

final mockListings = List.generate(20, (index) {
  final owner = mockUsers[(index % (mockUsers.length - 1)) + 1];
  final category = mockCategories[index % mockCategories.length];

  return Listing(
    id: 'l_$index',
    title: index.isEven ? 'Toyota Camry 70, 2019' : 'iPhone 14 Pro 256GB',
    description:
        'Excellent condition. Full service history and clean documents. Negotiable for serious buyers.',
    price: index.isEven ? 19800 + (index * 120) : 760 + (index * 15),
    currency: index.isEven ? r'$' : r'$',
    location: owner.city,
    imageUrls: [
      'https://picsum.photos/seed/market_$index/800/520',
      'https://picsum.photos/seed/market_${index + 100}/800/520',
      'https://picsum.photos/seed/market_${index + 200}/800/520',
    ],
    category: category,
    isFavorite: index % 3 == 0,
    owner: owner,
    createdAt: DateTime.now().subtract(Duration(hours: 4 * (index + 1))),
  );
});

final mockConversations = [
  ConversationPreview(
    id: 'c_1',
    peer: mockUsers[1],
    lastMessage: 'Can you lower the price to 19,200?',
    time: DateTime.now().subtract(const Duration(minutes: 18)),
    unreadCount: 2,
  ),
  ConversationPreview(
    id: 'c_2',
    peer: mockUsers[2],
    lastMessage: 'I can meet today after 18:00.',
    time: DateTime.now().subtract(const Duration(hours: 2, minutes: 14)),
    unreadCount: 0,
  ),
  ConversationPreview(
    id: 'c_3',
    peer: mockUsers[3],
    lastMessage: 'Please send more photos of the interior.',
    time: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
    unreadCount: 1,
  ),
];

final mockChatMessages = {
  'c_1': [
    ChatMessage(
      id: 'm1',
      senderId: 'u_1',
      text: 'Hi! Is the car still available?',
      sentAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
    ),
    ChatMessage(
      id: 'm2',
      senderId: currentUserId,
      text: 'Yes, available. You can inspect today.',
      sentAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 6)),
    ),
    ChatMessage(
      id: 'm3',
      senderId: 'u_1',
      text: 'Can you lower the price to 19,200?',
      sentAt: DateTime.now().subtract(const Duration(minutes: 19)),
    ),
  ],
  'c_2': [
    ChatMessage(
      id: 'm4',
      senderId: 'u_2',
      text: 'I can meet today after 18:00.',
      sentAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 14)),
    ),
  ],
  'c_3': [
    ChatMessage(
      id: 'm5',
      senderId: 'u_3',
      text: 'Please send more photos of the interior.',
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
    ),
  ],
};

final mockPayments = [
  PromotionPaymentEntry(
    id: 'p_1',
    title: 'Top Listing Boost - Toyota Camry',
    amount: 9.99,
    date: DateTime.now().subtract(const Duration(days: 1)),
    status: 'Completed',
  ),
  PromotionPaymentEntry(
    id: 'p_2',
    title: 'Home Banner Promotion',
    amount: 14.99,
    date: DateTime.now().subtract(const Duration(days: 5)),
    status: 'Completed',
  ),
  PromotionPaymentEntry(
    id: 'p_3',
    title: 'Urgent Badge Upgrade',
    amount: 4.49,
    date: DateTime.now().subtract(const Duration(days: 9)),
    status: 'Pending',
  ),
];
