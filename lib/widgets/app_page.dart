import 'package:flutter/material.dart';

import 'app_sizes.dart';
import 'custom_text.dart';
import 'layout_helper.dart';

/// The standard screen frame: an app bar, a safe area, and a body.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: CustomText(title), actions: actions),
      body: SafeArea(child: body),
    );
  }
}

/// A centered, scrollable page body with the same padding everywhere.
class AppScrollBody extends StatelessWidget {
  const AppScrollBody({
    super.key,
    required this.child,
    this.controller,
    this.maxWidth = 760,
    this.topPadding = AppSpacing.sm,
    this.bottomPadding = AppSpacing.xxxl,
    this.horizontalPadding,
  });

  final Widget child;
  final ScrollController? controller;
  final double maxWidth;
  final double topPadding;
  final double bottomPadding;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side =
            horizontalPadding ??
            (isWideScreen(constraints.maxWidth)
                ? AppSpacing.xxl
                : AppSpacing.xl);
        return SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(side, topPadding, side, bottomPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
