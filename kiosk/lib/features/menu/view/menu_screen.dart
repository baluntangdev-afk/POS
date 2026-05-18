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
    final responsive = context.responsive;
    return WindowsScaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: ColorSet.gradientBg)),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(50),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Assets.images.png.appBarLogo.image(
                        color: Colors.white,
                        width: responsive.scale(300),
                        height: responsive.scale(80),
                      ),
                    ),
                    UserDetailsWidget(access: access),
                  ],
                ),
              ),
            ];
          },
          body: Container(
            decoration: const BoxDecoration(color: ColorSet.background),
            padding: const EdgeInsets.all(16),
            child: MenuGrid(role: access.role),
          ),
        ),
      ),
    );
  }
}
