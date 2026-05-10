import 'package:flutter/material.dart';

import 'package:finance_buddy_app/models/category_budget_model.dart';

class AppCategory {
  final String name;
  final IconData icon;
  final Color iconColor;

  const AppCategory({
    required this.name,
    required this.icon,
    required this.iconColor,
  });
}

const Map<CategoryGroup, List<AppCategory>> kAllCategories = {
  CategoryGroup.foodAndDrink: [
    AppCategory(
        name: 'Groceries',
        icon: Icons.shopping_cart_outlined,
        iconColor: Color(0xFFEA580C)),
    AppCategory(
        name: 'Restaurants',
        icon: Icons.coffee_outlined,
        iconColor: Color(0xFFEA580C)),
    AppCategory(
        name: 'Coffee & Cafes',
        icon: Icons.local_cafe_outlined,
        iconColor: Color(0xFFEA580C)),
    AppCategory(
        name: 'Takeaway & Delivery',
        icon: Icons.delivery_dining_outlined,
        iconColor: Color(0xFFEA580C)),
    AppCategory(
        name: 'Alcohol & Bars',
        icon: Icons.local_bar_outlined,
        iconColor: Color(0xFFEA580C)),
  ],
  CategoryGroup.transport: [
    AppCategory(
        name: 'Fuel',
        icon: Icons.bolt_outlined,
        iconColor: Color(0xFF3B82F6)),
    AppCategory(
        name: 'Public Transport',
        icon: Icons.near_me_outlined,
        iconColor: Color(0xFF3B82F6)),
    AppCategory(
        name: 'Taxi & Ride Share',
        icon: Icons.location_on_outlined,
        iconColor: Color(0xFF3B82F6)),
    AppCategory(
        name: 'Parking',
        icon: Icons.map_outlined,
        iconColor: Color(0xFF3B82F6)),
    AppCategory(
        name: 'Car Maintenance',
        icon: Icons.build_outlined,
        iconColor: Color(0xFF3B82F6)),
  ],
  CategoryGroup.shopping: [
    AppCategory(
        name: 'Clothing & Fashion',
        icon: Icons.local_offer_outlined,
        iconColor: Color(0xFF8B5CF6)),
    AppCategory(
        name: 'Electronics',
        icon: Icons.desktop_mac_outlined,
        iconColor: Color(0xFF8B5CF6)),
    AppCategory(
        name: 'Home & Furniture',
        icon: Icons.layers_outlined,
        iconColor: Color(0xFF8B5CF6)),
    AppCategory(
        name: 'Books & Stationery',
        icon: Icons.menu_book_outlined,
        iconColor: Color(0xFF8B5CF6)),
    AppCategory(
        name: 'Gifts & Donations',
        icon: Icons.card_giftcard_outlined,
        iconColor: Color(0xFF8B5CF6)),
  ],
  CategoryGroup.billsAndUtilities: [
    AppCategory(
        name: 'Rent & Mortgage',
        icon: Icons.home_outlined,
        iconColor: Color(0xFFF59E0B)),
    AppCategory(
        name: 'Electricity & Gas',
        icon: Icons.bolt,
        iconColor: Color(0xFFF59E0B)),
    AppCategory(
        name: 'Internet & Phone',
        icon: Icons.wifi_outlined,
        iconColor: Color(0xFFF59E0B)),
    AppCategory(
        name: 'Water',
        icon: Icons.water_drop_outlined,
        iconColor: Color(0xFFF59E0B)),
    AppCategory(
        name: 'Insurance',
        icon: Icons.shield_outlined,
        iconColor: Color(0xFFF59E0B)),
  ],
  CategoryGroup.healthAndWellness: [
    AppCategory(
        name: 'Gym & Fitness',
        icon: Icons.monitor_heart_outlined,
        iconColor: Color(0xFF22C55E)),
    AppCategory(
        name: 'Doctor & Medical',
        icon: Icons.favorite_border,
        iconColor: Color(0xFF22C55E)),
    AppCategory(
        name: 'Pharmacy',
        icon: Icons.add_circle_outline,
        iconColor: Color(0xFF22C55E)),
    AppCategory(
        name: 'Mental Health',
        icon: Icons.wb_sunny_outlined,
        iconColor: Color(0xFF22C55E)),
  ],
  CategoryGroup.entertainment: [
    AppCategory(
        name: 'Movies & Cinema',
        icon: Icons.grid_view_outlined,
        iconColor: Color(0xFFEC4899)),
    AppCategory(
        name: 'Streaming Services',
        icon: Icons.play_circle_outline,
        iconColor: Color(0xFFEC4899)),
    AppCategory(
        name: 'Games & Apps',
        icon: Icons.apps_outlined,
        iconColor: Color(0xFFEC4899)),
    AppCategory(
        name: 'Hobbies & Sports',
        icon: Icons.sports_outlined,
        iconColor: Color(0xFFEC4899)),
  ],
  CategoryGroup.personalCare: [
    AppCategory(
        name: 'Haircut & Salon',
        icon: Icons.content_cut_outlined,
        iconColor: Color(0xFFEC4899)),
    AppCategory(
        name: 'Skincare & Beauty',
        icon: Icons.star_border,
        iconColor: Color(0xFFEC4899)),
    AppCategory(
        name: 'Spa & Wellness',
        icon: Icons.spa_outlined,
        iconColor: Color(0xFFEC4899)),
  ],
  CategoryGroup.education: [
    AppCategory(
        name: 'Courses & Training',
        icon: Icons.menu_book_outlined,
        iconColor: Color(0xFF6366F1)),
    AppCategory(
        name: 'Tuition & School',
        icon: Icons.school_outlined,
        iconColor: Color(0xFF6366F1)),
    AppCategory(
        name: 'Kids & Childcare',
        icon: Icons.people_outline,
        iconColor: Color(0xFF6366F1)),
    AppCategory(
        name: 'Productivity Tools',
        icon: Icons.settings_outlined,
        iconColor: Color(0xFF6366F1)),
  ],
  CategoryGroup.travel: [
    AppCategory(
        name: 'Flights',
        icon: Icons.flight_outlined,
        iconColor: Color(0xFF14B8A6)),
    AppCategory(
        name: 'Hotels & Stays',
        icon: Icons.map_outlined,
        iconColor: Color(0xFF14B8A6)),
    AppCategory(
        name: 'Activities & Tours',
        icon: Icons.camera_alt_outlined,
        iconColor: Color(0xFF14B8A6)),
    AppCategory(
        name: 'Travel Essentials',
        icon: Icons.work_outline,
        iconColor: Color(0xFF14B8A6)),
  ],
  CategoryGroup.other: [
    AppCategory(
        name: 'Pets',
        icon: Icons.sentiment_satisfied_outlined,
        iconColor: Color(0xFF9CA3AF)),
    AppCategory(
        name: 'Miscellaneous',
        icon: Icons.more_horiz,
        iconColor: Color(0xFF9CA3AF)),
  ],
};
