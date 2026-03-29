import 'mock_models.dart';

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

/// Home carousel buckets (not 1:1 with DB category_id; UI grouping).
final mockCarBrowseCategories = [
  CarBrowseCategory(
    id: 'sales',
    titleKey: 'catCarSales',
    imageUrl: 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=400&q=80',
    listingCount: 59131,
  ),
  CarBrowseCategory(
    id: 'parts',
    titleKey: 'catAutoParts',
    imageUrl: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400&q=80',
    listingCount: 197068,
  ),
  CarBrowseCategory(
    id: 'tuning',
    titleKey: 'catAccessories',
    imageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=400&q=80',
    listingCount: 31544,
  ),
  CarBrowseCategory(
    id: 'used',
    titleKey: 'catUsedCars',
    imageUrl: 'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=400&q=80',
    listingCount: 42102,
  ),
];

final mockPopularBrands = [
  const PopularBrand(name: 'Hyundai'),
  const PopularBrand(name: 'Lexus'),
  const PopularBrand(name: 'Kia'),
  const PopularBrand(name: 'Toyota'),
  const PopularBrand(name: 'BMW'),
  const PopularBrand(name: 'Mercedes-Benz'),
];

/// Distinct brands in mock inventory (filters screen).
final kAllBrands = [
  'Toyota',
  'Honda',
  'BMW',
  'Mercedes-Benz',
  'Hyundai',
  'Kia',
  'Lexus',
  'Volkswagen',
  'Mazda',
  'Subaru',
];

const _pairs = <(String, String)>[
  ('Toyota', 'Camry'),
  ('Honda', 'Inspire'),
  ('BMW', '320i'),
  ('Mercedes-Benz', 'E-Class'),
  ('Hyundai', 'Sonata'),
  ('Kia', 'K5'),
  ('Lexus', 'ES 250'),
  ('Volkswagen', 'Passat'),
  ('Mazda', '6'),
  ('Subaru', 'Outback'),
];

const _fuels = ['Gasoline', 'Diesel', 'Hybrid', 'Electric'];
const _transmissions = ['Automatic', 'Manual', 'Tiptronic'];
const _bodies = ['Sedan', 'SUV', 'Hatchback', 'Coupe', 'Wagon'];
const _extColors = ['White', 'Black', 'Silver', 'Gray', 'Blue', 'Red'];
const _intColors = ['Black', 'Beige', 'Gray', 'Brown'];
const _browseCats = ['All', 'New cars', 'Used', 'Parts', 'Rent'];

final mockListings = List.generate(24, (index) {
  final owner = mockUsers[(index % (mockUsers.length - 1)) + 1];
  final pair = _pairs[index % _pairs.length];
  final brand = pair.$1;
  final model = pair.$2;
  final year = 2015 + (index % 10);
  final mileage = 20000 + index * 3500;
  final fuel = _fuels[index % _fuels.length];
  final trans = _transmissions[index % _transmissions.length];
  final body = _bodies[index % _bodies.length];
  final priceKgs = 485000.0 + index * 12500;
  final usd = priceKgs / 25.5;

  return Listing(
    id: 'l_$index',
    title: 'Selling car — $brand $model, $year',
    description:
        'Well maintained, full service history. Clean documents. Inspection welcome.',
    price: priceKgs,
    currency: 'KGS',
    location: owner.city,
    imageUrls: [
      'https://picsum.photos/seed/car_$index/800/600',
      'https://picsum.photos/seed/car_${index + 50}/800/600',
    ],
    category: _browseCats[index % _browseCats.length],
    isFavorite: index % 3 == 0,
    owner: owner,
    createdAt: DateTime.now().subtract(Duration(hours: 3 * (index + 1))),
    brand: brand,
    model: model,
    year: year,
    mileage: mileage,
    fuelType: fuel,
    transmission: trans,
    bodyType: body,
    exteriorColor: _extColors[index % _extColors.length],
    interiorColor: _intColors[index % _intColors.length],
    isVip: index % 5 == 0,
    priceUsdApprox: usd,
    isCrashed: index % 11 == 0,
    openToTrade: index % 7 == 0,
    sellerIsDealer: index % 9 == 0,
  );
});

final mockConversations = [
  ConversationPreview(
    id: 'c_1',
    peer: mockUsers[1],
    lastMessage: 'Can you lower the price to 480,000 KGS?',
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
      text: 'Can you lower the price to 480,000 KGS?',
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
    title: 'VIP listing — Toyota Camry',
    amount: 9.99,
    date: DateTime.now().subtract(const Duration(days: 1)),
    status: 'Completed',
  ),
  PromotionPaymentEntry(
    id: 'p_2',
    title: 'Home spotlight — sedan',
    amount: 14.99,
    date: DateTime.now().subtract(const Duration(days: 5)),
    status: 'Completed',
  ),
  PromotionPaymentEntry(
    id: 'p_3',
    title: 'Urgent badge',
    amount: 4.49,
    date: DateTime.now().subtract(const Duration(days: 9)),
    status: 'Pending',
  ),
];
