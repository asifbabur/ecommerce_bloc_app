import 'package:myezzecommerce_app/firebase_options.dart';
import 'package:myezzecommerce_app/presentation/common_blocs/common_bloc.dart';
import 'package:myezzecommerce_app/configs/config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myezzecommerce_app/app_view.dart';
import 'presentation/common_blocs/simple_bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUiOverlayStyle(statusBarColor: Colors.transparent);
  Bloc.observer = SimpleBlocObserver();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

// This widget is the root of your application.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: CommonBloc.blocProviders,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return OrientationBuilder(
            builder: (context, orientation) {
              SizeConfig().init(constraints, orientation);
              return AppView();
            },
          );
        },
      ),
    );
  }
}
