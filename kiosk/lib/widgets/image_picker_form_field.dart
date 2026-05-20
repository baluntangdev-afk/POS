import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import '../styles/color_set.dart';
import '../theme/pos_design.dart';
import '../widgets/button.dart';

ImagePickerController useImagePickerController([Uint8List? initialValue]) {
  final controller = useMemoized(() => ImagePickerController(initialValue));
  useEffect(() {
    return controller.dispose;
  }, [controller]);
  return controller;
}

class ImagePickerController extends ChangeNotifier {
  ImagePickerController([Uint8List? initialValue]) : _value = initialValue;

  Uint8List? _value;

  void pick(Uint8List? image) {
    _value = image;
    notifyListeners();
  }

  Uint8List? get value => _value;
}

class ImagePickerFormField extends HookWidget {
  const ImagePickerFormField({
    required this.controller,
    this.initialImage,
    this.label = 'Image',
    this.height,
    this.style,
    this.onChanged,
    this.showError = true,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    super.key,
  }) : assert(
         controller == null || initialImage == null,
         'Provide only one of either initialImage or controller.',
       );

  final ImagePickerController? controller;
  final Uint8List? initialImage;
  final String label;
  final double? height;
  final TextStyle? style;
  final ValueChanged<Uint8List?>? onChanged;
  final bool showError;
  final FormFieldValidator<Uint8List?>? validator;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? useImagePickerController(initialImage);

    return FormField<Uint8List?>(
      initialValue: effectiveController.value,
      validator: validator?.call,
      autovalidateMode: autovalidateMode,
      builder: (state) {
        return HookBuilder(
          builder: (context) {
            final imagePicker = useMemoized(() => ImagePicker());

            useEffect(() {
              void handleChanges() {
                if (state.value == effectiveController.value) return;
                state.didChange(effectiveController.value);
                onChanged?.call(effectiveController.value);
              }

              effectiveController.addListener(handleChanges);

              return () {
                effectiveController.removeListener(handleChanges);
              };
            }, [effectiveController]);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty) ...[
                  Text(label, style: const TextStyle().merge(style)),
                  const Gap(8),
                ],
                Container(
                  height: height,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: POSColors.surfaceSubtle,
                    border: Border.all(
                      color: state.hasError
                          ? ColorSet.danger
                          : POSColors.borderDefault,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Gap(16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          child: Image.memory(
                            effectiveController.value ?? Uint8List(0),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: POSColors.iconSubtle,
                                  ),
                                  const Gap(8),
                                  Text(
                                    'No image selected',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: POSColors.textTertiary,
                                      fontWeight: FontWeight.w400,
                                    ).merge(style),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Button.outlined(
                            foregroundColor:
                                state.hasError ? ColorSet.danger : POSColors.textSecondary,
                            onPressed: () async {
                              final image = await imagePicker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 800,
                                maxHeight: 600,
                                imageQuality: 85,
                              );

                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                effectiveController.pick(bytes);
                                state.didChange(bytes);
                                state.validate();
                              }
                            },
                            label: Text(
                              effectiveController.value != null ? 'Change Image' : 'Choose Image',
                              style: const TextStyle().merge(style),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
