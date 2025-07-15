import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

class AnimatedCounter extends StatefulWidget {
  final double value;
  final Duration duration;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;
  final TextStyle? textStyle;
  final Curve curve;
  final bool autoStart;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1000),
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
    this.textStyle,
    this.curve = Curves.easeOut,
    this.autoStart = true,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimation();

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _previousValue = _animation.value;
      _setupAnimation();
      _controller.forward(from: 0);
    }
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: _previousValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  void start() {
    if (!_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  void reset() {
    _controller.reset();
    _previousValue = 0;
    _setupAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _animation.value;
        final formattedValue = _formatValue(currentValue);

        return Text(
          '${widget.prefix ?? ''}$formattedValue${widget.suffix ?? ''}',
          style: widget.textStyle ?? responsive.getBodyStyle(),
        );
      },
    );
  }

  String _formatValue(double value) {
    if (widget.decimalPlaces == 0) {
      return value.round().toString();
    } else {
      return value.toStringAsFixed(widget.decimalPlaces);
    }
  }
}

/// Animated counter with multiple display formats
class FlexibleAnimatedCounter extends StatefulWidget {
  final double value;
  final Duration duration;
  final String? prefix;
  final String? suffix;
  final CounterFormat format;
  final TextStyle? textStyle;
  final Curve curve;
  final bool showPlusSign;

  const FlexibleAnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1000),
    this.prefix,
    this.suffix,
    this.format = CounterFormat.integer,
    this.textStyle,
    this.curve = Curves.easeOut,
    this.showPlusSign = false,
  });

  @override
  State<FlexibleAnimatedCounter> createState() =>
      _FlexibleAnimatedCounterState();
}

class _FlexibleAnimatedCounterState extends State<FlexibleAnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FlexibleAnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _previousValue = _animation.value;
      _setupAnimation();
      _controller.forward(from: 0);
    }
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: _previousValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _animation.value;
        final formattedValue = _formatValue(currentValue);

        return Text(
          '${widget.prefix ?? ''}$formattedValue${widget.suffix ?? ''}',
          style: widget.textStyle ?? responsive.getBodyStyle(),
        );
      },
    );
  }

  String _formatValue(double value) {
    String sign = '';
    if (widget.showPlusSign && value > 0) {
      sign = '+';
    }

    switch (widget.format) {
      case CounterFormat.integer:
        return '$sign${value.round()}';

      case CounterFormat.decimal1:
        return '$sign${value.toStringAsFixed(1)}';

      case CounterFormat.decimal2:
        return '$sign${value.toStringAsFixed(2)}';

      case CounterFormat.percentage:
        return '$sign${value.toStringAsFixed(1)}%';

      case CounterFormat.currency:
        return '$sign\$${value.toStringAsFixed(2)}';

      case CounterFormat.compact:
        return '$sign${_formatCompact(value)}';

      case CounterFormat.time:
        return _formatTime(value);
    }
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.round().toString();
    }
  }

  String _formatTime(double minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes.round()}m';
    } else {
      return '${remainingMinutes.round()}m';
    }
  }
}

/// Multi-digit counter with individual digit animations
class DigitAnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final String? prefix;
  final String? suffix;
  final TextStyle? textStyle;
  final int minDigits;

  const DigitAnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
    this.prefix,
    this.suffix,
    this.textStyle,
    this.minDigits = 1,
  });

  @override
  State<DigitAnimatedCounter> createState() => _DigitAnimatedCounterState();
}

class _DigitAnimatedCounterState extends State<DigitAnimatedCounter> {
  int _previousValue = 0;

  @override
  void didUpdateWidget(DigitAnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {
        _previousValue = oldWidget.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final valueString = widget.value.toString().padLeft(widget.minDigits, '0');
    final previousString =
        _previousValue.toString().padLeft(widget.minDigits, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.prefix != null)
          Text(
            widget.prefix!,
            style: widget.textStyle ?? responsive.getBodyStyle(),
          ),
        ...List.generate(valueString.length, (index) {
          final currentDigit = int.parse(valueString[index]);
          final previousDigit = index < previousString.length
              ? int.parse(previousString[index])
              : 0;

          return _AnimatedDigit(
            currentDigit: currentDigit,
            previousDigit: previousDigit,
            duration: widget.duration,
            textStyle: widget.textStyle ?? responsive.getBodyStyle(),
          );
        }),
        if (widget.suffix != null)
          Text(
            widget.suffix!,
            style: widget.textStyle ?? responsive.getBodyStyle(),
          ),
      ],
    );
  }
}

class _AnimatedDigit extends StatefulWidget {
  final int currentDigit;
  final int previousDigit;
  final Duration duration;
  final TextStyle? textStyle;

  const _AnimatedDigit({
    required this.currentDigit,
    required this.previousDigit,
    required this.duration,
    this.textStyle,
  });

  @override
  State<_AnimatedDigit> createState() => _AnimatedDigitState();
}

class _AnimatedDigitState extends State<_AnimatedDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();

    if (widget.currentDigit != widget.previousDigit) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_AnimatedDigit oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentDigit != widget.currentDigit) {
      _setupAnimation();
      _controller.forward(from: 0);
    }
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRect(
          child: Stack(
            children: [
              // Previous digit sliding out
              Transform.translate(
                offset: Offset(0, -30 * _animation.value),
                child: Opacity(
                  opacity: 1 - _animation.value,
                  child: Text(
                    widget.previousDigit.toString(),
                    style: widget.textStyle,
                  ),
                ),
              ),
              // Current digit sliding in
              Transform.translate(
                offset: Offset(0, 30 * (1 - _animation.value)),
                child: Opacity(
                  opacity: _animation.value,
                  child: Text(
                    widget.currentDigit.toString(),
                    style: widget.textStyle,
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

/// Circular progress counter
class CircularAnimatedCounter extends StatefulWidget {
  final double value;
  final double maxValue;
  final Duration duration;
  final String? label;
  final Color? progressColor;
  final Color? backgroundColor;
  final double strokeWidth;
  final double size;
  final TextStyle? textStyle;

  const CircularAnimatedCounter({
    super.key,
    required this.value,
    required this.maxValue,
    this.duration = const Duration(milliseconds: 1500),
    this.label,
    this.progressColor,
    this.backgroundColor,
    this.strokeWidth = 8.0,
    this.size = 100.0,
    this.textStyle,
  });

  @override
  State<CircularAnimatedCounter> createState() =>
      _CircularAnimatedCounterState();
}

class _CircularAnimatedCounterState extends State<CircularAnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value / widget.maxValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Background circle
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: widget.strokeWidth,
              backgroundColor:
                  widget.backgroundColor ?? theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.backgroundColor ?? theme.colorScheme.surfaceVariant,
              ),
            ),
          ),
          // Animated progress
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.progressColor ?? theme.colorScheme.primary,
                  ),
                ),
              );
            },
          ),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedCounter(
                  value: widget.value,
                  duration: widget.duration,
                  textStyle: widget.textStyle ??
                      responsive.getTitleStyle(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: responsive.getCaptionStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum CounterFormat {
  integer,
  decimal1,
  decimal2,
  percentage,
  currency,
  compact,
  time,
}
