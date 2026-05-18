# pos_app

POS Kiosk App by Cody Web Development Inc.

## FVM (Flutter Version Manager)

**Installation**

See [installation](https://fvm.app/documentation/getting-started/installation).

After installation, activate FVM globally.

```
dart pub global activate fvm
```

**Configuration**

Configure project to use specific version.

```
fvm use stable
```

**Android Studio**

Go to `Preferences` > `Languages & Frameworks` > `Flutter`
and update the Flutter SDK Path to use FVM path.

```
USER/PATH_TO_FVM/.fvm/flutter_sdk
```

**Reminder**

While using FVM, add `fvm` before any Flutter command.

For example, instead of `flutter pub get`

```
fvm flutter pub get
```

Refer to these link for more information.

- [Official Documentation](https://fvm.app/docs/getting_started/overview)

- [Medium Article by by Sanjib Maharjan](https://cshanjib.medium.com/setting-up-fvm-flutter-version-management-properly-ab45ade0dd55)

## Environment Variables

**Define variables**

Create a `.env` file at the root of the project.

```
cp .env.sample .env
```

Add a variable to `.env`. For example,

```
apiKey=LATEST_API_KEY
```

Add the variable's key as `@EnviedField()`-annotated property of the [Env](/lib/environment/env.dart) class.

```
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied()
abstract final class Env {
  Env._();

  @EnviedField()
  static const String apiKey = _Env.apiKey;
}
```

**Using other .env files**

To use another `.env.*` file, run the following command.

```
fvm dart run build_runner build --define=envied_generator:envied=path=PATH_TO_ANOTHER_ENV
```

**Applying changes in .env.development**

When modifying the `.env`, the generator might not pick up the change due to [dart-lang/build#967](https://github.com/dart-lang/build/issues/967).

If that happens simply clean the build cache and run the generator again.

```
fvm dart run build_runner clean
fvm dart run build_runner build --delete-conflicting-outputs
```

**Refer to these link for more information**

- [Official Documentation](https://pub.dev/packages/envied)

## Getting Started

**Install packages**

```
fvm flutter pub get
```

**Run the generator**

```
fvm dart run build_runner build
```
