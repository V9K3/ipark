import 'package:flutter/material.dart';
import 'car_model.dart';

class Passenger {
  final String id;
  final Color color;

  Passenger({required this.id, required this.color});

  bool matchesCar(Car car) => car.color == color;
}
