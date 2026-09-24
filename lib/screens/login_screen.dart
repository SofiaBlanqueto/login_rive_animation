import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

import 'dart:async'; //3.1 importar la libreria para usar el timer

class LoginScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  //oculta los caracteres de la contraseña
  //crear el cerebro de las animaciones
  StateMachineController? _controller;
  //SMI:State machine input: es un tipo de dato que permite controlar la animación
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  //2.1 varaiable pata el recorrido de la mirada

  SMINumber? _numLook;

  //3.2 timer para detener la mrada al dejar de escribir en el email

  Timer? _typingDebounce;

  //1.1 crear variables para fucusNode
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  //4.1 controllers para manipular el texto escrito por usuario
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //4.2 Errores para mostrar en la interfaz de usuario
  String? emailError;
  String? passwordError;

  //4.3 validar el email y la contraseña
  bool isValidEmail(String email) {
    // Expresión regular para validar el formato del correo electrónico
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String password) {
    // Verifica que la contraseña tenga al menos 6 caracteres
    final re = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$');
    return re.hasMatch(password);
  }

  //4.4 accion al botom
  void _onLogin() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    //recalcular los errores cada vez que se presiona el botón de login

    final eError = isValidEmail(email) ? null : 'Invalid email format';
    final pError = isValidPassword(password) ? null : 'Invalid password format';

    //4.5 avisar si hay errores
    setState(() {
      emailError = eError;
      passwordError = pError;
    });

    //4.6 cerrar el tecaldo y bajar las manos
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50; //mirada neutral

    //4.7 activar triggers

    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  //crear los listeners para los focusNode y el timer para detener la mirada al dejar de escribir en el email
  @override
  void initState() {
    super.initState();
    //1.2 agregar listener a los focusNode
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        if (_isHandsUp != null) {
          //No se tapa los ojos
          _isHandsUp?.change(false);
          // mirada neutral
          _numLook?.value = 50;
        }
      }
    });
    _passwordFocusNode.addListener(() {
      _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    //PARA OBTENER EL TAMAÑO DE LA PANTALLA
    final Size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  width: Size.width,
                  child: RiveAnimation.asset(
                    'assets/login_bear.riv',
                    stateMachines: ['Login Machine'],
                    //al iniciar la animación, se ejecuta el callback onInit
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
                      //verificar que todo inicio correctamente
                      if (_controller == null) return;
                      //agregar el controlador al tablero de animación
                      artboard.addController(_controller!);
                      //vincular las variables de la máquina de estados con las variables de la clase
                      _isChecking = _controller?.findSMI('isChecking');
                      _isHandsUp = _controller?.findSMI('isHandsUp');
                      _trigSuccess = _controller?.findSMI('trigSuccess');
                      _trigFail = _controller?.findSMI('trigFail');
                      //vincular la variable de recorrido de la mirada
                      _numLook = _controller?.findSMI('numLook');
                    },
                  ),
                ),

                //PARA SEPARAR WIDGETS
                SizedBox(height: 20),
                //campo de texto para email
                TextField(
                  focusNode: _emailFocusNode,
                  controller: emailController,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //No se tapa los ojos
                      //_isHandsUp?.change(false);
                    }
                    //si isChecking es nulo
                    if (_isChecking == null) return;
                    //modo chismoso
                    _isChecking?.change(true);
                    //implementar el numlook para que la mirada siga el cursor del email
                    //ajuste de limites de 0 a 100
                    //80 medida de calibracion
                    final look = (value.length / 80.0 * 100.0).clamp(
                      0.0,
                      100.0,
                    );
                    _numLook?.value = look;

                    //3.3 debounce para detener la mirada al dejar de escribir en el email
                    //cancelar el timer si ya existe uno en curso
                    _typingDebounce?.cancel();
                    //crear un nuevo timer
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      //Si se cierra la pantalla (!mounted es que no esté activa) no se ejecuta el código
                      if (!mounted) return;
                      //mirada nuetral
                      _isChecking?.change(false);
                    });
                  },
                  //PARA MSTRAR UN TIPO DE TECLADO
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                SizedBox(height: 10),
                //campo de texto para contraseña
                TextField(
                  focusNode: _passwordFocusNode,
                  controller: passwordController,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //No se tapa los ojos
                      _isHandsUp?.change(true);
                    }
                    //si isChecking es nulo
                    if (_isChecking == null) return;
                    //modo chismoso
                    // _isChecking?.change(true);
                  },
                  //PARA MSTRAR UN TIPO DE TECLADO
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    errorText: passwordError,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                SizedBox(height: 10),
                //texto de "olvidaste tu contraseña"
                SizedBox(
                  width: Size.width,
                  child: const Text(
                    'Forgot your password?',
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                SizedBox(height: 10),
                MaterialButton(
                  minWidth: Size.width,
                  height: 50,
                  color: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  onPressed: _onLogin,
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                //No tienes cuenta??

                SizedBox(
                  width: Size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have a account"),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: Colors.black,
                            //Subrayado
                            decoration: TextDecoration.underline,
                            //Negritas
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //1.4 libererar los focusNode cuando se destruye el widget
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    //3.4 cancelar el timer si existe
    _typingDebounce?.cancel();

    //4.11 Liberar controllers
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
