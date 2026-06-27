import 'package:ecommerce/components/header/header.dart';
import 'package:ecommerce/features/menu/view/menu_controller.dart';
import 'package:flutter/material.dart' hide MenuController;

class MenuView extends StatelessWidget {
  final MenuController controller;

  const MenuView({super.key, required this.controller});

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
