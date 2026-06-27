import 'package:ecommerce/components/header/header.dart';
import 'package:ecommerce/features/home/view/home_controller.dart';
import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  final HomeController controller;

  const HomeView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: Column(
        children: [
          Header(
            title: controller.headerTitle,
            subtitle: controller.headerSubtitle
          ),
        ],
      ),
    );
  }
}