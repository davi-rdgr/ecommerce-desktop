import 'package:romeu_lanches_admin/features/home/components/home_card.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeColumn extends StatelessWidget {
  final String label;
  final Color color;
  final List<Order> orders;

  const HomeColumn({
    super.key,
    required this.label,
    required this.color,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // constraints.maxHeight = altura disponível vinda do pai (Expanded na HomeView)
        // Subtraímos: padding do Container (10+10) + header row (~24px) + SizedBox(15)
        final cardMaxHeight = (constraints.maxHeight - 59).clamp(120.0, double.infinity);

        return Container(
          padding: const EdgeInsets.all(10),
          width: 300,
          decoration: BoxDecoration(
            color: const Color(0XFFEFEAE3),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0XFF2A1F17),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0XFFFFFFFF),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: Text(
                        '${orders.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0XFF998875),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 120,
                  maxHeight: cardMaxHeight,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (int i = 0; i < orders.length; i++) ...[
                        HomeCard(order: orders[i]),
                        if (i < orders.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
