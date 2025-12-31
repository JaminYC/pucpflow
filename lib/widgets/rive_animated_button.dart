import 'package:flutter/material.dart';

class RiveAnimatedButton extends StatelessWidget {
  final String assetPath;
  final String stateMachineName;
  final VoidCallback? onPressed;
  final double width;
  final double height;

  const RiveAnimatedButton({
    Key? key,
    required this.assetPath,
    required this.stateMachineName,
    this.onPressed,
    this.width = 200,
    this.height = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          color: Colors.blue,
          child: Center(child: Text('Rive Button')),
        ),
      ),
    );
  }
}
