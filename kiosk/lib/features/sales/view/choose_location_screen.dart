import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/windows_scaffold.dart';
import '../enums/sale_type.dart';
import '../state/ordering_notifier.dart';

class ChooseLocationScreen extends StatelessWidget {
  const ChooseLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowsScaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: ColorSet.gradientBg,
          ),
        ),
        child: const _OrderLocationContents(),
      ),
    );
  }
}

class _OrderLocationContents extends StatelessWidget {
  const _OrderLocationContents();

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;

    return Stack(
      children: [
        // Main centered content
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.value<double>(phone: 24, tablet: 40, kiosk: 64),
              vertical: responsive.value<double>(phone: 60, tablet: 80, kiosk: 100),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Headline
                Text(
                  'Select Eating Location',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.value<double>(phone: 22, tablet: 28, kiosk: 40),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Gap(responsive.value<double>(phone: 32, tablet: 48, kiosk: 64)),
                // Location buttons
                HookConsumer(
                  builder: (context, ref, child) {
                    useEffect(() {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.invalidate(orderingProvider);
                      });
                      return null;
                    }, const []);
                    final isLoading =
                        ref.watch(orderingProvider.select((it) => it.isLoading));
                    if (isLoading) {
                      return const CircularProgressIndicator(color: Colors.white);
                    }
                    if (isPortrait) {
                      return Column(
                        children: [
                          _OrderLocationCard(
                            icon: Assets.images.svg.icDineIn.svg(
                              height: responsive.value<double>(phone: 48, tablet: 60, kiosk: 80),
                              width: responsive.value<double>(phone: 48, tablet: 60, kiosk: 80),
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                            label: 'Dine In',
                            color: ColorSet.primary,
                            onTap: () async {
                              ref
                                  .read(orderingProvider.notifier)
                                  .selectSaleType(SaleType.dineIn);
                              await const OrderingRoute().push<void>(context);
                            },
                          ),
                          Gap(responsive.value<double>(phone: 20, tablet: 28, kiosk: 40)),
                          _OrderLocationCard(
                            icon: Assets.images.svg.icTakeOut.svg(
                              height: responsive.value<double>(phone: 48, tablet: 60, kiosk: 80),
                              width: responsive.value<double>(phone: 48, tablet: 60, kiosk: 80),
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                            label: 'Take Out',
                            color: ColorSet.secondary,
                            onTap: () async {
                              ref
                                  .read(orderingProvider.notifier)
                                  .selectSaleType(SaleType.takeOut);
                              await const OrderingRoute().push<void>(context);
                            },
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _OrderLocationCard(
                          icon: Assets.images.svg.icDineIn.svg(
                            height: responsive.value<double>(phone: 48, tablet: 60, kiosk: 80),
                            width: responsive.value<double>(phone: 48, tablet: 60, kiosk: 80),
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          label: 'Dine In',
                          color: ColorSet.primary,
                          onTap: () async {
                            ref
                                .read(orderingProvider.notifier)
                                .selectSaleType(SaleType.dineIn);
                            await const OrderingRoute().push<void>(context);
                          },
                        ),
                        Gap(responsive.value<double>(phone: 24, tablet: 36, kiosk: 60)),
                        _OrderLocationCard(
                          icon: Assets.images.svg.icTakeOut.svg(
                            height: responsive.value<double>(phone: 48, tablet: 60, kiosk: 80),
                            width: responsive.value<double>(phone: 48, tablet: 60, kiosk: 80),
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          label: 'Take Out',
                          color: ColorSet.secondary,
                          onTap: () async {
                            ref
                                .read(orderingProvider.notifier)
                                .selectSaleType(SaleType.takeOut);
                            await const OrderingRoute().push<void>(context);
                          },
                        ),
                      ],
                    );
                  },
                ),
                Gap(responsive.value<double>(phone: 40, tablet: 56, kiosk: 80)),
                // Back button — bottom-center
                OutlinedButton.icon(
                  onPressed: () => const MenuRoute().go(context),
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: responsive.value<double>(phone: 14, tablet: 16, kiosk: 18),
                  ),
                  label: const Text('Back to Menu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    minimumSize: Size(
                      responsive.value<double>(phone: 140, tablet: 160, kiosk: 200),
                      responsive.value<double>(phone: 44, tablet: 48, kiosk: 56),
                    ),
                    textStyle: TextStyle(
                      fontSize: responsive.value<double>(phone: 14, tablet: 16, kiosk: 18),
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(POSRadius.full),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderLocationCard extends StatelessWidget {
  const _OrderLocationCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final isKiosk = responsive.value<bool>(kiosk: true, tablet: false, phone: false);

    final cardWidth = isKiosk
        ? 300.0
        : isPortrait
        ? 260.0
        : 240.0;
    final cardHeight = isKiosk
        ? 280.0
        : isPortrait
        ? 200.0
        : 220.0;
    final labelSize = responsive.value<double>(phone: 22, tablet: 28, kiosk: 36);

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(POSRadius.xxl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(POSRadius.xxl),
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              Gap(responsive.value<double>(phone: 12, tablet: 16, kiosk: 20)),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: labelSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
