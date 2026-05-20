import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../validation/rules/is_required.dart';
import '../../../validation/validate.dart';
import '../../../widgets/button.dart';
import '../../../widgets/text_box_form_field.dart';
import '../entities/franchisee_info.dart';
import '../state/franchisee_info_notifier.dart';

Future<void> showFranchiseeInfoDialog(BuildContext context) {
  return showDialog<void>(context: context, builder: (context) => const FranchiseeInfoDialog());
}

class FranchiseeInfoDialog extends HookConsumerWidget {
  const FranchiseeInfoDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final franchiseeInfo = ref.watch(franchiseeInfoProvider);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final legalNameController = useTextEditingController();
    final tinController = useTextEditingController();
    final addressLine1Controller = useTextEditingController();
    final addressLine2Controller = useTextEditingController();
    useEffect(() {
      if (franchiseeInfo case AsyncData(value: final data)) {
        if (legalNameController.text.isEmpty) {
          legalNameController.text = data.legalName;
        }
        if (tinController.text.isEmpty) {
          tinController.text = data.tin;
        }
        if (addressLine1Controller.text.isEmpty) {
          addressLine1Controller.text = data.addressLine1;
        }
        if (addressLine2Controller.text.isEmpty) {
          addressLine2Controller.text = data.addressLine2;
        }
      }
      return null;
    }, [franchiseeInfo]);
    return Dialog(
      backgroundColor: ColorSet.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        vertical: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Container(
            width: context.responsive.value(kiosk: 600, tablet: 600, phone: double.infinity),
            padding: EdgeInsetsGeometry.symmetric(
              horizontal: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
              children: [
                Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
                Center(
                  child: Container(
                    width: context.responsive.value<double>(kiosk: 80, tablet: 64, phone: 56),
                    height: context.responsive.value<double>(kiosk: 80, tablet: 64, phone: 56),
                    decoration: BoxDecoration(
                      color: ColorSet.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.store_outlined,
                      color: ColorSet.primary,
                      size: context.responsive.value<double>(kiosk: 40, tablet: 32, phone: 28),
                    ),
                  ),
                ),
                Text(
                  'Franchisee Information',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 32, tablet: 24, phone: 18),
                    fontWeight: FontWeight.w700,
                    color: ColorSet.text,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(0),
                TextBoxFormField(
                  controller: legalNameController,
                  label: 'Legal Name',
                  hint: 'Enter legal business name',
                  maxLines: 1,
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  validator: Validate(rules: [isRequired()]).call,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                  ),
                ),
                TextBoxFormField(
                  controller: tinController,
                  label: 'Tax Identification Number',
                  hint: 'Enter TIN',
                  maxLines: 1,
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  validator: Validate(rules: [isRequired()]).call,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                  ),
                ),
                TextBoxFormField(
                  controller: addressLine1Controller,
                  label: 'Address Line 1',
                  hint: 'Enter street address',
                  maxLines: 1,
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  validator: Validate(rules: [isRequired()]).call,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                  ),
                ),
                TextBoxFormField(
                  controller: addressLine2Controller,
                  label: 'Address Line 2',
                  hint: 'Enter city, province, ZIP code',
                  maxLines: 1,
                  maxLength: 80,
                  textInputAction: TextInputAction.done,
                  validator: Validate(rules: [isRequired()]).call,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                  ),
                ),
                const Gap(0),
                Row(
                  children: [
                    Button.outlined(
                      foregroundColor: ColorSet.text,
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      label: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                          vertical: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                          ),
                        ),
                      ),
                    ),
                    Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                    const Spacer(),
                    Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                    Button(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final franchiseeInfo = FranchiseeInfo(
                          legalName: legalNameController.text.trim(),
                          tin: tinController.text.trim(),
                          addressLine1: addressLine1Controller.text.trim(),
                          addressLine2: addressLine2Controller.text.trim(),
                        );
                        await ref
                            .read(franchiseeInfoProvider.notifier)
                            .updateFranchiseeInfo(franchiseeInfo);
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      foregroundColor: ColorSet.background,
                      backgroundColor: ColorSet.secondary,
                      label: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                          vertical: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
                        ),
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
