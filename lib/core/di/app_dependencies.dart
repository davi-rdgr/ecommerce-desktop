import 'package:ecommerce/core/di/scaffold_full_dependencies.dart';

late final AppDependencies deps;

class AppDependencies {
  late final ScaffoldFullDependencies scaffoldFullDependencies;

  AppDependencies() {
    scaffoldFullDependencies = ScaffoldFullDependencies();
  }
}
