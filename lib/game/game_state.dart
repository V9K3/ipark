import 'dart:collection';
import 'package:flutter/material.dart';
import 'car_model.dart';
import 'passenger_model.dart';
import 'parking_spot.dart';
import '../utils/constants.dart';
import 'dart:math';

class GameState extends ChangeNotifier {
  // 1x5 grid for parking
  static const int numRows = 1;
  static const int numCols = 5;
  List<List<ParkingSpot>> parkingGrid;
  List<Car> carPool;
  Queue<Passenger> waitingPassengers;
  int remainingChances;
  int score;
  int level;
  final Random _random = Random();
  int numColors;
  List<Color> levelColors = [];
  int winCount = 0;
  bool boardingInProgress = false;

  GameState({
    List<List<ParkingSpot>>? parkingGrid,
    List<Car>? carPool,
    Queue<Passenger>? waitingPassengers,
    this.remainingChances = 3,
    this.score = 0,
    this.level = 1,
    this.numColors = 3,
  })  : parkingGrid = parkingGrid ?? [],
        carPool = carPool ?? [],
        waitingPassengers = waitingPassengers ?? Queue<Passenger>() {
    if (this.parkingGrid.isEmpty) {
      _initGame();
    }
  }

  void _initGame() {
    parkingGrid = List.generate(numRows, (row) =>
      List.generate(numCols, (col) => ParkingSpot(car: null)));
    // Pick a random subset of colors for this level
    numColors = min(3 + level ~/ 2, carColors.length - 1);
    levelColors = List<Color>.from(carColors)..shuffle(_random);
    levelColors = levelColors.take(numColors).toList();

    // 1. Generate number of passengers for each color
    Map<Color, int> passengerCount = {};
    int totalPassengers = 0;
    for (final color in levelColors) {
      int count = 4 + _random.nextInt(7); // 4-10 passengers per color
      passengerCount[color] = count;
      totalPassengers += count;
    }
    // 2. Generate passenger queue
    List<Passenger> passengers = [];
    int id = 0;
    for (final color in levelColors) {
      for (int i = 0; i < passengerCount[color]!; i++) {
        passengers.add(Passenger(id: 'p${id++}', color: color));
      }
    }
    passengers.shuffle(_random);
    waitingPassengers = Queue.of(passengers);

    // 3. For each color, generate cars until seat requirement is met
    carPool = [];
    for (final color in levelColors) {
      int seats = 0;
      while (seats < passengerCount[color]!) {
        final type = CarType.values[_random.nextInt(CarType.values.length)];
        final capacity = min(10, 4 + _random.nextInt(7)); // 4-10
        carPool.add(Car(
          id: UniqueKey().toString(),
          color: color,
          capacity: capacity,
          type: type,
        ));
        seats += capacity;
      }
    }
    carPool.shuffle(_random);

    remainingChances = 3;
    score = 0;
    notifyListeners();
  }

  Car _randomCarFromColors(List<Color> allowedColors) {
    final color = allowedColors[_random.nextInt(allowedColors.length)];
    final type = CarType.values[_random.nextInt(CarType.values.length)];
    final capacity = 4 + _random.nextInt(7); // 4-10
    return Car(
      id: UniqueKey().toString(),
      color: color,
      capacity: capacity,
      type: type,
    );
  }

  // Place a car from the pool into the first available empty slot and trigger auto-boarding for all cars
  Future<void> placeCarInFirstAvailableAnimated(Car car) async {
    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numCols; col++) {
        if (parkingGrid[row][col].car == null) {
          parkingGrid[row][col].car = car;
          carPool.remove(car);
          await _autoBoardAllCarsAnimated();
          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> _autoBoardAllCarsAnimated() async {
    boardingInProgress = true;
    notifyListeners();
    bool changed;
    do {
      changed = false;
      for (int row = 0; row < numRows; row++) {
        for (int col = 0; col < numCols; col++) {
          final car = parkingGrid[row][col].car;
          if (car == null) continue;
          // Board as many matching passengers as possible, with delay
          while (!car.isFull() && waitingPassengers.isNotEmpty) {
            final nextPassenger = waitingPassengers.first;
            if (car.canAcceptPassenger(nextPassenger)) {
              car.boardPassenger();
              waitingPassengers.removeFirst();
              score += 10;
              changed = true;
              notifyListeners();
              await Future.delayed(const Duration(milliseconds: 250));
            } else {
              break;
            }
          }
          // If car is full, remove it immediately
          if (car.isFull()) {
            parkingGrid[row][col].car = null;
            changed = true;
            notifyListeners();
            await Future.delayed(const Duration(milliseconds: 250));
          }
        }
      }
      print('DEBUG: waitingPassengers: ${waitingPassengers.length}, carPool: ${carPool.length}, parkingGrid: ${_parkingGridCarCount()}');
    } while (changed);
    if (waitingPassengers.isEmpty) {
      for (int row = 0; row < numRows; row++) {
        for (int col = 0; col < numCols; col++) {
          parkingGrid[row][col].car = null;
        }
      }
      notifyListeners();
    }
    boardingInProgress = false;
    notifyListeners();
  }

  int _parkingGridCarCount() {
    int count = 0;
    for (var row in parkingGrid) {
      for (var spot in row) {
        if (spot.car != null) count++;
      }
    }
    return count;
  }

  // Check if a car at (row, col) can move out (edge and clear path)
  bool canCarMoveOut(int row, int col) {
    final car = parkingGrid[row][col].car;
    if (car == null) return false;
    // Check all 4 edges
    // Top edge
    if (row == 0 && _isClearPath(row, col, -1, 0)) return true;
    // Bottom edge
    if (row == numRows - 1 && _isClearPath(row, col, 1, 0)) return true;
    // Left edge
    if (col == 0 && _isClearPath(row, col, 0, -1)) return true;
    // Right edge
    if (col == numCols - 1 && _isClearPath(row, col, 0, 1)) return true;
    return false;
  }

  // Check if there are no cars between (row, col) and the edge in the given direction
  bool _isClearPath(int row, int col, int dRow, int dCol) {
    int r = row + dRow;
    int c = col + dCol;
    while (r >= 0 && r < numRows && c >= 0 && c < numCols) {
      if (parkingGrid[r][c].car != null) return false;
      r += dRow;
      c += dCol;
    }
    return true;
  }

  // No longer needed: moveOutCar (auto-removal is now handled)

  bool isWin() {
    final win = waitingPassengers.isEmpty && parkingGrid.every((row) => row.every((s) => s.car == null)) && carPool.isEmpty;
    print('DEBUG isWin: waitingPassengers: ${waitingPassengers.length}, carPool: ${carPool.length}, parkingGrid: ${_parkingGridCarCount()}, isWin: $win');
    return win;
  }
  bool isLose() => !canMakeMove() && waitingPassengers.isNotEmpty;

  bool canMakeMove() {
    // Can place a car if there are empty spots and cars in the pool
    for (var row in parkingGrid) {
      for (var spot in row) {
        if (spot.car == null && carPool.isNotEmpty) return true;
      }
    }
    return false;
  }

  void nextLevel() {
    level++;
    winCount++;
    _initGame();
  }

  void resetGame() {
    level = 1;
    _initGame();
  }

  // Remove a car from the parking grid and return it to the car pool (if chances remain)
  void manuallyRemoveCar(int row, int col) {
    if (remainingChances > 0 && parkingGrid[row][col].car != null) {
      carPool.add(parkingGrid[row][col].car!);
      parkingGrid[row][col].car = null;
      remainingChances--;
      // _autoBoardAllCars(); // REMOVE this line, use animated version if needed
      notifyListeners();
    }
  }
}

