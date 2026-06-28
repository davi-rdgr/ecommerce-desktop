import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeStats extends StatelessWidget {
  final String title;
  final dynamic value;
  final Color color;
  const HomeStats({
    super.key,
    required this.title,
    required this.value,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 133,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: Color(0XFFFFFFFF),
        border: Border.all(width: 1, color: Color(0XFFECE4DA)),
      ),
      padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0XFF998875),
            ),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}