import 'package:flutter/material.dart';
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                width: Size.width,
                child: RiveAnimation.asset(
                  'login_bear.riv',
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
                  final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
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
            ],
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
    super.dispose();
  }
}
