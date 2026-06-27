import 'package:ecommerce/components/header/header.dart';
import 'package:ecommerce/features/shop/view/shop_controller.dart';
import 'package:flutter/material.dart';

class ShopView extends StatelessWidget {
  final ShopController controller;

  const ShopView({super.key, required this.controller});

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
