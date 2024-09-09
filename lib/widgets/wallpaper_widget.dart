import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WallpaperWidget extends StatelessWidget {
  final String svgPath;

  const WallpaperWidget({Key? key, required this.svgPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SvgPicture.asset(
                svgPath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}
