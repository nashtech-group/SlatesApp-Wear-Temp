import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

class WearableScaffold extends StatelessWidget {
  final Widget body;
  final AppBar? appBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final Widget? bottomNavigationBar;

  const WearableScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    if (responsive.isWearable) {
      return _WearableOptimizedScaffold(
        body: body,
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        isRound: responsive.isRoundScreen,
        responsive: responsive,
      );
    }
    
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         (appBar?.preferredSize.height ?? 0) - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom,
            ),
            child: body,
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _WearableOptimizedScaffold extends StatelessWidget {
  final Widget body;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final bool isRound;
  final ResponsiveUtils responsive;

  const _WearableOptimizedScaffold({
    required this.body,
    this.backgroundColor,
    this.floatingActionButton,
    required this.isRound,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: isRound 
          ? _RoundScreenLayout(body: body, responsive: responsive) 
          : _SquareScreenLayout(body: body, responsive: responsive),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _RoundScreenLayout extends StatelessWidget {
  final Widget body;
  final ResponsiveUtils responsive;

  const _RoundScreenLayout({
    required this.body,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(responsive.smallSpacing), // Responsive padding for round insets
            child: body,
          ),
        ),
      ),
    );
  }
}

class _SquareScreenLayout extends StatelessWidget {
  final Widget body;
  final ResponsiveUtils responsive;

  const _SquareScreenLayout({
    required this.body,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: body,
      ),
    );
  }
}