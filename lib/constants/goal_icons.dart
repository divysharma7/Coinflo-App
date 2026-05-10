import 'package:flutter/material.dart';

class GoalIcon {
  final IconData icon;
  final String label;

  const GoalIcon({required this.icon, required this.label});
}

const List<GoalIcon> kGoalIcons = [
  GoalIcon(icon: Icons.two_wheeler_outlined, label: 'Vehicle'),
  GoalIcon(icon: Icons.home_outlined, label: 'Home'),
  GoalIcon(icon: Icons.phone_iphone_outlined, label: 'Phone'),
  GoalIcon(icon: Icons.flight_outlined, label: 'Travel'),
  GoalIcon(icon: Icons.school_outlined, label: 'Education'),
  GoalIcon(icon: Icons.sports_esports_outlined, label: 'Gaming'),
  GoalIcon(icon: Icons.diamond_outlined, label: 'Wedding'),
  GoalIcon(icon: Icons.card_giftcard_outlined, label: 'Other'),
];
