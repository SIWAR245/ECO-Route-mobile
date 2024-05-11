import 'package:flutter/material.dart';
import 'package:eco_route_se/Common_widgets/custom_scaffold.dart';
import '../../Common_widgets/tealButton.dart';
import '../../Firebase_auth/firebase_auth_services.dart';
import '../../theme/theme.dart';


class Forgot_pwd_Screen extends StatefulWidget {
  const Forgot_pwd_Screen({super.key});

  @override
  State<Forgot_pwd_Screen> createState() => _Forgot_pwd_Screen();
}

class _Forgot_pwd_Screen extends State<Forgot_pwd_Screen> {
  final _formSignInKey = GlobalKey<FormState>();
  bool rememberPassword = true;
  final FirebaseAuthServices _auth = FirebaseAuthServices();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    _emailController.text = '';
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

//rest password method
  void _sendResetEmail() async {
    String email = _emailController.text;
    await _auth.sendPasswordResetEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignInKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: lightColorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      const Text(
                        'Enter your email, and check your inbox for a reset link. Follow the link to set a new password. If you need help, contact our support team.',
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter Email',
                          hintStyle: const TextStyle(
                            color: Colors.black54,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black54,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black54,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black54,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(
                          height: 25.0
                      ),
                      const SizedBox(height: 25.0),
                      CustomButton(
                        text: 'Submit',
                        onPressed: () {
                          if (_formSignInKey.currentState!.validate() &&
                              rememberPassword) {
                            _sendResetEmail();
                          } else if (!rememberPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please agree to the processing of personal data',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:  [
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: Colors.green.withOpacity(0.5),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
