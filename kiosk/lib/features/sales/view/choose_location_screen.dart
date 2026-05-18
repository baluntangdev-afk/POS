import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../widgets/windows_scaffold.dart';
import '../enums/sale_type.dart';
import '../state/ordering_notifier.dart';

class ChooseLocationScreen extends StatelessWidget {
  const ChooseLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowsScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallHeight = constraints.maxHeight <= 500;
          final scroll = constraints.maxWidth < 500;
          return SizedBox.expand(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: ColorSet.gradientBg,
                ),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: !scroll ? Axis.vertical : Axis.horizontal,
                    child: Container(
                      constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width),
                      child: _OrderLocationContents(isSmallHeight: isSmallHeight),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => const MenuRoute().go(context),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: context.responsive.value<EdgeInsets>(
                            phone: const EdgeInsets.all(12),
                            tablet: const EdgeInsets.all(16),
                            kiosk: const EdgeInsets.all(20),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: ColorSet.light,
                            size: context.responsive.value<double>(
                              phone: 20,
                              tablet: 30,
                              kiosk: 40,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          const LoginRoute().go(context);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: context.responsive.value<EdgeInsets>(
                            phone: const EdgeInsets.all(12),
                            tablet: const EdgeInsets.all(16),
                            kiosk: const EdgeInsets.all(20),
                          ),
                          child: Icon(
                            Icons.logout,
                            color: ColorSet.primary,
                            size: context.responsive.value<double>(
                              phone: 30,
                              tablet: 40,
                              kiosk: 45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderLocationContents extends StatelessWidget {
  const _OrderLocationContents({required this.isSmallHeight});

  final bool isSmallHeight;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    final iconSize = Size(
      responsive.value<double>(phone: 50, tablet: 60, kiosk: 80),
      responsive.value<double>(phone: 50, tablet: 60, kiosk: 80),
    );
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height,
          // minWidth: MediaQuery.sizeOf(context).width,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: responsive.value<EdgeInsets>(
                phone: const EdgeInsets.symmetric(horizontal: 30.0),
                tablet: const EdgeInsets.symmetric(horizontal: 60.0),
                kiosk: const EdgeInsets.symmetric(horizontal: 100.0),
              ),
              child: Assets.images.png.onboardingLogo.image(
                color: Colors.white,
                width: responsive.value<double>(phone: 200, tablet: 600, kiosk: 700),
                height: responsive.value<double>(phone: 100, tablet: 110, kiosk: 110),
              ),
            ),
            Gap(
              responsive.value<double>(
                phone: isSmallHeight ? 20 : 30,
                tablet: isSmallHeight ? 30 : 50,
                kiosk: isSmallHeight ? 40 : 60,
              ),
            ),
            HookConsumer(
              builder: (context, ref, child) {
                useEffect(() {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.invalidate(orderingProvider);
                  });
                  return null;
                }, const []);
                final isLoading = ref.watch(orderingProvider.select((it) => it.isLoading));
                if (isLoading) {
                  return const CircularProgressIndicator();
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _OrderLocationButton(
                      icon: Assets.images.svg.icDineIn.svg(
                        height: iconSize.height,
                        width: iconSize.width,
                      ),
                      label: 'Dine In',
                      onTap: () async {
                        ref.read(orderingProvider.notifier).selectSaleType(SaleType.dineIn);
                        await const OrderingRoute().push<void>(context);
                      },
                    ),
                    Gap(
                      responsive.value<double>(
                        phone: isSmallHeight ? 20 : 30,
                        tablet: isSmallHeight ? 30 : 60,
                        kiosk: isSmallHeight ? 40 : 80,
                      ),
                    ),
                    _OrderLocationButton(
                      icon: Assets.images.svg.icTakeOut.svg(
                        height: iconSize.height,
                        width: iconSize.width,
                      ),
                      label: 'Take Out',
                      onTap: () async {
                        ref.read(orderingProvider.notifier).selectSaleType(SaleType.takeOut);
                        await const OrderingRoute().push<void>(context);
                      },
                    ),
                  ],
                );
              },
            ),

            Gap(
              responsive.value<double>(
                phone: isSmallHeight ? 20 : 30,
                tablet: isSmallHeight ? 30 : 50,
                kiosk: isSmallHeight ? 40 : 60,
              ),
            ),
            Text(
              'Select Eating Location',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorSet.background,
                fontSize: responsive.value<double>(phone: 16, tablet: 25, kiosk: 55),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderLocationButton extends StatelessWidget {
  const _OrderLocationButton({required this.icon, required this.label, required this.onTap});

  final Widget icon;
  final String label;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      height: responsive.value<double>(phone: 120, tablet: 160, kiosk: 200),
      width: responsive.value<double>(phone: 120, tablet: 160, kiosk: 200),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          // splashColor: ColorSet.button.withAlpha(100),
          // highlightColor: ColorSet.button.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  SizedBox(height: responsive.value<double>(phone: 8, tablet: 12, kiosk: 16)),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: responsive.value<double>(phone: 20, tablet: 24, kiosk: 28),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
