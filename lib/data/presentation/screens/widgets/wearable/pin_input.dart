import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

class PinInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onCompleted;
  final int length;
  final bool obscureText;

  const PinInputField({
    super.key,
    required this.controller,
    this.onCompleted,
    this.length = 4,
    this.obscureText = true,
  });

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers =
        List.generate(widget.length, (index) => TextEditingController());

    widget.controller.addListener(_onMainControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    widget.controller.removeListener(_onMainControllerChanged);
    super.dispose();
  }

  void _onMainControllerChanged() {
    final text = widget.controller.text;
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].text = i < text.length ? text[i] : '';
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && value.length == 1) {
      HapticFeedback.lightImpact();

      final currentText = widget.controller.text.padRight(widget.length, ' ');
      final chars = currentText.split('');
      chars[index] = value;
      widget.controller.text = chars.join('').replaceAll(' ', '');

      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (widget.controller.text.length == widget.length) {
          HapticFeedback.mediumImpact();
          widget.onCompleted?.call(widget.controller.text);
        }
      }
    } else if (value.isEmpty) {
      final currentText = widget.controller.text;
      if (index < currentText.length) {
        final chars = currentText.split('');
        chars.removeAt(index);
        widget.controller.text = chars.join('');
      }

      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PIN',
          style: responsive.getBodyStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        responsive.smallSpacer,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.length, (index) {
            return SizedBox(
              width: responsive.pinBoxSize,
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                obscureText: widget.obscureText,
                style: responsive.getHeadlineStyle(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(responsive.borderRadius),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(responsive.borderRadius),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: responsive.getResponsiveValue(
                      wearable: 8.0,
                      smallMobile: 12.0,
                      mobile: 14.0,
                      tablet: 20.0,
                    ),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) => _onDigitChanged(index, value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '';
                  }
                  return null;
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}
