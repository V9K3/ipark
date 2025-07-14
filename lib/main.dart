import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:collection';
import 'game/game_state.dart';
import 'ui/screens/menu_screen.dart';

void main() {
  runApp(const IParkApp());
}

class IParkApp extends StatelessWidget {
  const IParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MaterialApp(
        title: 'iPark',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MenuScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
