import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';

class OnboardingContents extends StatelessWidget {
  const OnboardingContents({super.key, required this.isSmallHeight});

  final bool isSmallHeight;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveValue.of(context);

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        child: IntrinsicHeight(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                Gap(
                  responsive.value<double>(
                    phone: isSmallHeight ? 50 : 100,
                    tablet: isSmallHeight ? 80 : 130,
                    kiosk: isSmallHeight ? 100 : 150,
                  ),
                ),
                Text(
                  'Welcome to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorSet.welcomeText,
                    fontSize: responsive.value<double>(phone: 30, tablet: 50, kiosk: 80),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                Gap(
                  responsive.value<double>(
                    phone: isSmallHeight ? 20 : 30,
                    tablet: isSmallHeight ? 30 : 45,
                    kiosk: isSmallHeight ? 40 : 60,
                  ),
                ),
                Padding(
                  padding: responsive.value<EdgeInsets>(
                    phone: const EdgeInsets.symmetric(horizontal: 30.0),
                    tablet: const EdgeInsets.symmetric(horizontal: 60.0),
                    kiosk: const EdgeInsets.symmetric(horizontal: 100.0),
                  ),
                  child: Assets.images.png.onboardingLogo.image(
                    width: responsive.value<double>(phone: 300, tablet: 500, kiosk: 800),
                    height: responsive.value<double>(phone: 100, tablet: 150, kiosk: 200),
                  ),
                ),
                if (!isSmallHeight)
                  const Spacer()
                else
                  Gap(responsive.value<double>(phone: 50, tablet: 75, kiosk: 100)),
                Center(
                  child: Padding(
                    padding: responsive.value<EdgeInsets>(
                      phone: const EdgeInsets.symmetric(vertical: 30.0),
                      tablet: const EdgeInsets.symmetric(vertical: 60.0),
                      kiosk: const EdgeInsets.symmetric(vertical: 100.0),
                    ),
                    child: Text(
                      'Touch To Start',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: responsive.value<double>(phone: 20, tablet: 40, kiosk: 50),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
