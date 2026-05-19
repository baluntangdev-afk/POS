import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/access.dart';
import '../state/access_notifier.dart';
import '../view/menu_grid.dart';
import '../view/user_details_widget.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessProvider.select((it) => it.value ?? Access.unknown()));
    final r = context.responsive;

    return WindowsScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Gradient header ──────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: ColorSet.gradientBg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(r.spacingXl),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.hPagePadding),
                    child: Assets.images.png.appBarLogo.image(
                      color: Colors.white,
                      width: r.scale(300),
                      height: r.scale(80),
                    ),
                  ),
                  UserDetailsWidget(access: access),
                ],
              ),
            ),
            // ── Menu grid ────────────────────────────────────────────────
            Container(
              color: ColorSet.background,
              padding: EdgeInsets.all(r.spacingMd),
              child: MenuGrid(role: access.role),
            ),
          ],
        ),
      ),
    );
  }
}
