import 'package:flutter/material.dart';

/// A scaffold optimized for round WearOS displays
class WearScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const WearScaffold({
    super.key,
    required this.body,
    this.title,
    this.floatingActionButton,
    this.backgroundColor,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isRound = size.width == size.height || 
                    (size.width - size.height).abs() < 50;
    
    // Calculate padding for round screens
    final roundPadding = isRound ? size.width * 0.1 : 0.0;

    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content with padding for round screens
            Padding(
              padding: EdgeInsets.all(roundPadding),
              child: Column(
                children: [
                  // Title bar if provided
                  if (title != null || showBackButton)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          if (showBackButton)
                            IconButton(
                              icon: const Icon(Icons.arrow_back, size: 20),
                              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          if (title != null)
                            Expanded(
                              child: Text(
                                title!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: showBackButton ? TextAlign.left : TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  // Body content
                  Expanded(child: body),
                ],
              ),
            ),
            // Floating action button positioned for round screens
            if (floatingActionButton != null)
              Positioned(
                bottom: roundPadding + 8,
                right: size.width / 2 - 28,
                child: floatingActionButton!,
              ),
          ],
        ),
      ),
    );
  }
}

/// A circular button optimized for WearOS
class WearButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final double size;

  const WearButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
        ),
        child: child,
      ),
    );
  }
}

/// A list tile optimized for WearOS (more compact)
class WearListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  const WearListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// A card optimized for WearOS round screens
class WearCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? color;

  const WearCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}

