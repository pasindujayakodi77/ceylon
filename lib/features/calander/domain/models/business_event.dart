import 'package:equatable/equatable.dart';

class BusinessEvent extends Equatable {
  final String id;
  final String businessId;
  final String businessName;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String description;
  final String? promoCode;
  final String? whatsappNumber;
  final String? bookingUrl;
  final List<String> categories;

  const BusinessEvent({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.description,
    this.promoCode,
    this.whatsappNumber,
    this.bookingUrl,
    this.categories = const [],
  });

  factory BusinessEvent.fromFirestore(Map<String, dynamic> data, String id) {
    return BusinessEvent(
      id: id,
      businessId: data['businessId'] as String,
      businessName: data['businessName'] as String,
      title: data['title'] as String,
      startTime: (data['startTime'] as dynamic).toDate(),
      endTime: (data['endTime'] as dynamic).toDate(),
      description: data['description'] as String,
      promoCode: data['promoCode'] as String?,
      whatsappNumber: data['whatsappNumber'] as String?,
      bookingUrl: data['bookingUrl'] as String?,
      categories: List<String>.from(data['categories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
      'promoCode': promoCode,
      'whatsappNumber': whatsappNumber,
      'bookingUrl': bookingUrl,
      'categories': categories,
    };
  }

  @override
  List<Object?> get props => [
    id,
    businessId,
    businessName,
    title,
    startTime,
    endTime,
    description,
    promoCode,
    whatsappNumber,
    bookingUrl,
    categories,
  ];
}
