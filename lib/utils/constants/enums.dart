// lib\utils\constants\enums.dart
/// LIST OF Enums

enum TextSizes { small, medium, large }

/// Roles a user can have in CampusLink
enum UserRole { student, runner, admin }

/// Possible statuses for a runner task (delivery, errand, etc.)
enum RunnerTaskStatus { pending, inProgress, completed, canceled }

/// Payment methods available in CampusLink
enum PaymentMethod { wallet, onlineBanking, creditCard, cashOnDelivery }

/// Condition of an item listed in the marketplace
enum ItemCondition { newItem, used, refurbished }

/// Status of a second-hand listing in the marketplace
enum ListingStatus { active, sold, canceled }
