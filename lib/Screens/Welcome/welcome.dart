import 'package:flutter/material.dart';
import 'package:eco_route_se/screens/login/login_screen.dart';
import 'package:eco_route_se/Common_widgets/custom_scaffold.dart';
import '../../theme/theme.dart';
import '../../Common_widgets/button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          Flexible(
              flex: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                ),
                child: Center(
                  child: Image.asset('assets/images/logo2.png'),
                ),
              )),
          Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  const Expanded(
                    child: Button(
                      buttonText: '',
                      color: Colors.transparent,
                      textColor: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Button(
                      buttonText: 'Sign In',
                      onTap: const LoginScreen(),
                      color: Colors.white,
                      textColor: lightColorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

