import 'package:flutter/material.dart';
import 'package:kapoof/core/theme.dart';

class NeobrutalistCard extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final EdgeInsets padding;
  final double borderRadius;
  final double borderWidth;
  final double shadowOffset;
  final VoidCallback? onTap;

  const NeobrutalistCard({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 40,
    this.borderWidth = 4,
    this.shadowOffset = 7,
    this.onTap,
  });

  @override
  State<NeobrutalistCard> createState() => _NeobrutalistCardState();
}

class _NeobrutalistCardState extends State<NeobrutalistCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Transform.translate(
        offset: _isPressed
            ? Offset(widget.shadowOffset / 2, widget.shadowOffset / 2)
            : Offset.zero,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: AppColors.onBackground,
              width: widget.borderWidth,
            ),
            boxShadow: _isPressed
                ? null
                : [
                    BoxShadow(
                      color: AppColors.onBackground,
                      offset:
                          Offset(widget.shadowOffset, widget.shadowOffset),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class NeobrutalistButton extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final double size;
  final VoidCallback? onTap;
  final bool isCircle;
  final double borderRadius;

  const NeobrutalistButton({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.primaryContainer,
    this.size = 56,
    this.onTap,
    this.isCircle = true,
    this.borderRadius = 14,
  });

  @override
  State<NeobrutalistButton> createState() => _NeobrutalistButtonState();
}

class _NeobrutalistButtonState extends State<NeobrutalistButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Transform.translate(
        offset: _isPressed ? const Offset(3, 3) : Offset.zero,
        child: Container(
          width: widget.isCircle ? widget.size : null,
          height: widget.isCircle ? widget.size : null,
          constraints: widget.isCircle
              ? null
              : BoxConstraints(minHeight: widget.size),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: AppColors.onBackground, width: 3),
            boxShadow: _isPressed
                ? null
                : [
                    const BoxShadow(
                      color: AppColors.onBackground,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
