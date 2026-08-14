import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../entities/customer_display_catalog.dart';
import 'menu_slide.dart';

/// Rotates through fixed-capacity [MenuSlide]s built from [categories] — one
/// category at a time, and (for a category with more products than fit on
/// one screen) one page at a time within it. Every slide shows exactly
/// `columns * _rowsPerSlide` cells, so card size depends only on [compact]
/// (6 columns full-width, 3 columns once the order panel takes half the
/// screen), never on how many products a given category happens to have.
class MenuShowcase extends StatefulWidget {
  const MenuShowcase({super.key, required this.categories, required this.compact});

  final List<CustomerDisplayCategory> categories;
  final bool compact;

  @override
  State<MenuShowcase> createState() => _MenuShowcaseState();
}

class _MenuShowcaseState extends State<MenuShowcase> {
  static const _rotateEvery = Duration(seconds: 5);
  static const _rowsPerSlide = 2;

  Timer? _timer;
  int _index = 0;
  late List<MenuSlide> _slides;

  @override
  void initState() {
    super.initState();
    _slides = _buildSlides();
    _scheduleAdvance();
  }

  @override
  void didUpdateWidget(covariant MenuShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categories != oldWidget.categories || widget.compact != oldWidget.compact) {
      _slides = _buildSlides();
      if (_index >= _slides.length) _index = 0;
      _scheduleAdvance();
    }
  }

  List<MenuSlide> _buildSlides() {
    return buildMenuSlides(categories: widget.categories, columns: _columns, rows: _rowsPerSlide);
  }

  int get _columns => widget.compact ? 3 : 6;

  void _scheduleAdvance() {
    _timer?.cancel();
    if (_slides.length <= 1) return;
    _timer = Timer.periodic(_rotateEvery, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _slides.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) {
      return const _EmptyShowcase();
    }

    final safeIndex = _index.clamp(0, _slides.length - 1);
    final slide = _slides[safeIndex];
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Padding(
      padding: EdgeInsets.all(widget.compact ? POSSpacing.md : POSSpacing.lg),
      child: Column(
        children: [
          _CategoryHeading(slide: slide, compact: widget.compact),
          SizedBox(height: widget.compact ? POSSpacing.sm : POSSpacing.md),
          Expanded(
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
              child: _MenuGrid(
                key: ValueKey('${slide.category.id}-${slide.pageIndex}'),
                slide: slide,
                columns: _columns,
                rows: _rowsPerSlide,
              ),
            ),
          ),
          if (_slides.length > 1) ...[
            SizedBox(height: widget.compact ? POSSpacing.sm : POSSpacing.md),
            _DotsRow(key: ValueKey('dots-$safeIndex'), count: _slides.length, index: safeIndex, duration: _rotateEvery),
          ],
        ],
      ),
    );
  }
}

/// The accent colors a category (and its no-photo product cards) cycle
/// through, matching the badge color already used for the category heading.
const _accents = [ColorSet.primary, ColorSet.secondary, ColorSet.tertiary, ColorSet.welcomeText];

class _CategoryHeading extends StatelessWidget {
  const _CategoryHeading({required this.slide, required this.compact});

  final MenuSlide slide;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = _accents[slide.categoryIndex % _accents.length];
    final badgeSize = compact ? 26.0 : 36.0;
    final category = slide.category;

    final meta = StringBuffer(
      'Category ${slide.categoryIndex + 1} of ${slide.categoryCount} · ${category.products.length} items',
    );
    if (slide.pageCount > 1) {
      meta.write(' · Page ${slide.pageIndex + 1} of ${slide.pageCount}');
    }

    return Row(
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(POSRadius.sm)),
          clipBehavior: Clip.antiAlias,
          child: category.image != null
              ? Image.memory(category.image!, fit: BoxFit.cover)
              : Center(
                  child: Text(
                    category.name.isEmpty ? '?' : category.name[0].toUpperCase(),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: badgeSize * 0.42),
                  ),
                ),
        ),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meta.toString(),
                style: TextStyle(
                  fontSize: compact ? 9 : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: ColorSet.primary,
                ),
              ),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 16 : 24,
                  fontWeight: FontWeight.w800,
                  color: ColorSet.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lays out [slide]'s `columns * rows` cells at one fixed card size, derived
/// from the available space — never from how many of those cells are
/// actually filled. The block is centered in whatever room is left over
/// rather than stretched to fill it, which is what let a sparsely-filled
/// category balloon into near-empty giant cards before.
class _MenuGrid extends StatelessWidget {
  const _MenuGrid({super.key, required this.slide, required this.columns, required this.rows});

  final MenuSlide slide;
  final int columns;
  final int rows;

  static const _gap = 10.0;
  // width / height — cards read taller than wide, like a menu photo card.
  static const _cardAspectRatio = 3 / 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthBudget = constraints.maxWidth - (columns - 1) * _gap;
        final heightBudget = constraints.maxHeight - (rows - 1) * _gap;
        final cellWidthByWidth = widthBudget / columns;
        final cellHeightByWidth = cellWidthByWidth / _cardAspectRatio;
        final cellHeightByHeight = heightBudget / rows;
        final cellHeight = math.min(cellHeightByWidth, cellHeightByHeight);
        final cellWidth = cellHeight * _cardAspectRatio;

        final accent = _accents[slide.categoryIndex % _accents.length];

        return Center(
          child: SizedBox(
            width: columns * cellWidth + (columns - 1) * _gap,
            height: rows * cellHeight + (rows - 1) * _gap,
            child: Column(
              children: [
                for (var r = 0; r < rows; r++) ...[
                  if (r > 0) const SizedBox(height: _gap),
                  SizedBox(
                    height: cellHeight,
                    child: Row(
                      children: [
                        for (var c = 0; c < columns; c++) ...[
                          if (c > 0) const SizedBox(width: _gap),
                          SizedBox(
                            width: cellWidth,
                            child: _cellAt(r * columns + c, accent),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cellAt(int index, Color accent) {
    if (index >= slide.products.length) return const SizedBox.shrink();
    final product = slide.products[index];
    if (product == null) return const SizedBox.shrink();
    return _MenuItemCard(product: product, accent: accent);
  }
}

/// A full-bleed photo tile: the product photo fills the whole card, with
/// name/price legible over a bottom gradient scrim. Products without a
/// photo (or whose photo fails to load) fall back to the same accent tint
/// and initial letter used for the category badge above them, instead of a
/// generic icon that doesn't relate to the product.
class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.product, required this.accent});

  final CustomerDisplayProduct product;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.md),
        boxShadow: POSShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(POSRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                fadeInDuration: POSAnimation.fast,
                placeholderFadeInDuration: Duration.zero,
                errorWidget: (_, _, _) => _ProductFallback(name: product.name, accent: accent),
                placeholder: (_, _) => _ProductFallback(name: product.name, accent: accent),
              )
            else
              _ProductFallback(name: product.name, accent: accent),
            if (imageUrl != null)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.42, 1],
                    colors: [Colors.transparent, Color(0xB8000000)],
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: _CardInfo(product: product, onPhoto: imageUrl != null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.product, required this.onPhoto});

  final CustomerDisplayProduct product;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final textColor = onPhoto ? Colors.white : ColorSet.text;
    final priceColor = onPhoto ? Colors.white : ColorSet.welcomeText;
    final priceBg = onPhoto ? Colors.white.withValues(alpha: 0.22) : ColorSet.welcomeText.withValues(alpha: 0.12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor, height: 1.2),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: priceBg, borderRadius: BorderRadius.circular(POSRadius.full)),
          child: Text(
            product.price.pesoFormatted,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: priceColor),
          ),
        ),
      ],
    );
  }
}

class _ProductFallback extends StatelessWidget {
  const _ProductFallback({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Colors.black, 0.28)!],
        ),
      ),
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 34, height: 1),
        ),
      ),
    );
  }
}

class _DotsRow extends StatelessWidget {
  const _DotsRow({super.key, required this.count, required this.index, required this.duration});

  final int count;
  final int index;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          _Dot(filled: i < index, animating: i == index, duration: duration),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.animating, required this.duration});

  final bool filled;
  final bool animating;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: ColorSet.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(POSRadius.full),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(POSRadius.full),
        child: Align(
          alignment: Alignment.centerLeft,
          child: animating
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: duration,
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: Container(height: 4, color: ColorSet.primary),
                  ),
                )
              : FractionallySizedBox(
                  widthFactor: filled ? 1 : 0,
                  child: Container(height: 4, color: ColorSet.primary),
                ),
        ),
      ),
    );
  }
}

class _EmptyShowcase extends StatelessWidget {
  const _EmptyShowcase();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Menu loading…',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ColorSet.welcomeText),
      ),
    );
  }
}
