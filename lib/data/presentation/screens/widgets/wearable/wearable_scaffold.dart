import 'package:flutter/material.dart';

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
    final screenSize = MediaQuery.of(context).size;
    final isWearable = screenSize.width < 250 || screenSize.height < 250;
    final isRound = screenSize.width == screenSize.height;
    
    if (isWearable) {
      return _WearableOptimizedScaffold(
        body: body,
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        isRound: isRound,
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

  const _WearableOptimizedScaffold({
    required this.body,
    this.backgroundColor,
    this.floatingActionButton,
    required this.isRound,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: isRound ? _RoundScreenLayout(body: body) : _SquareScreenLayout(body: body),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _RoundScreenLayout extends StatelessWidget {
  final Widget body;

  const _RoundScreenLayout({required this.body});

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
            padding: const EdgeInsets.all(8), // Padding for round insets
            child: body,
          ),
        ),
      ),
    );
  }
}

class _SquareScreenLayout extends StatelessWidget {
  final Widget body;

  const _SquareScreenLayout({required this.body});

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