import 'package:flutter/material.dart';
import 'passenger_model.dart';

enum CarType { sedan, suv, bus }

class Car {
  final String id;
  final Color color;
  final int capacity;
  int currentPassengers;
  final CarType type;

  Car({
    required this.id,
    required this.color,
    required this.capacity,
    this.currentPassengers = 0,
    required this.type,
  });

  bool canAcceptPassenger(Passenger passenger) => passenger.color == color && !isFull();
  void boardPassenger() => currentPassengers++;
  bool isFull() => currentPassengers >= capacity;
}
