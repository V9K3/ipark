import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../game/game_state.dart';
import '../../game/car_model.dart';
import '../../game/passenger_model.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('iPark - Game')),
      body: Consumer<GameState>(
        builder: (context, game, _) {
          final grid = game.parkingGrid;
          final carPool = game.carPool;
          final n = carPool.isEmpty ? 1 : (sqrt(carPool.length)).ceil();
          final waitingCount = game.waitingPassengers.length;
          const double carTileSize = 44;
          final double gridSize = n * carTileSize + (n - 1) * 4;

          // Curved, contiguous passenger queue
          Widget buildCurvedPassengerQueue(List<Passenger> passengers) {
            const double passengerDiameter = 30; // 30px diameter
            const double mmToPx = 3.78; // 1mm ≈ 3.78px
            const double gap = 0.1 * mmToPx; // 0.1mm gap ≈ 0.4px, use 1px for visibility
            const int rowLength = 13;
            List<Widget> children = [];
            for (int i = 0; i < passengers.length; i++) {
              final isOddRow = ((i ~/ rowLength) % 2 == 1);
              if (i % rowLength == 0 && isOddRow) {
                children.add(SizedBox(width: passengerDiameter / 2));
              }
              children.add(Container(
                width: passengerDiameter,
                height: passengerDiameter,
                margin: EdgeInsets.only(
                  right: ((i + 1) % rowLength == 0) ? 0 : gap,
                  bottom: gap,
                ),
                decoration: BoxDecoration(
                  color: (passengers[i] as Passenger).color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26),
                ),
              ));
            }
            return Wrap(
              direction: Axis.horizontal,
              spacing: gap,
              runSpacing: gap,
              children: children,
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Section 1: Passengers
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 8.0, top: 8.0),
                      child: Text('Passengers:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildCurvedPassengerQueue(game.waitingPassengers.take(25).toList().cast<Passenger>()),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0, left: 8.0, top: 8.0),
                      child: Text('x $waitingCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
              // HUD for remaining chances and win count
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Removals left: ${game.remainingChances}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepOrange)),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Text('Wins: ${game.winCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                    ),
                  ],
                ),
              ),
              if (game.isWin())
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('You Win!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                ),
              // Section 2: Parking grid
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  children: [
                    const Text('Parking Spots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(GameState.numCols, (col) {
                          final spot = grid[0][col];
                          final car = spot.car;
                          final canRemove = car != null && game.remainingChances > 0;
                          return GestureDetector(
                            onTap: null,
                            onLongPress: game.boardingInProgress ? null : canRemove
                                ? () {
                                    game.manuallyRemoveCar(0, col);
                                  }
                                : null,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 60,
                              height: 70,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: canRemove ? Colors.deepOrange : Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: car?.color.withOpacity(0.7) ?? Colors.grey[200],
                              ),
                              child: car != null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(car.type.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                                        Text('${car.currentPassengers}/${car.capacity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        if (canRemove)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 4.0),
                                            child: Text('Long press to remove', style: TextStyle(fontSize: 9, color: Colors.deepOrange)),
                                          ),
                                      ],
                                    )
                                  : const Center(child: Text('Empty', style: TextStyle(fontSize: 12))),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              // Section 3: Vehicle grid
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Column(
                  children: [
                    const Text('Available Vehicles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Center(
                      child: SizedBox(
                        width: gridSize,
                        height: gridSize,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: n,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 1,
                          ),
                          itemCount: carPool.length,
                          itemBuilder: (context, i) {
                            final car = carPool[i];
                            return GestureDetector(
                              onTap: game.boardingInProgress || car == null ? null : () async {
                                await game.placeCarInFirstAvailableAnimated(car);
                              },
                              child: Container(
                                width: carTileSize,
                                height: carTileSize,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: car.color,
                                  border: Border.all(color: Colors.grey, width: 1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(car.type.name.toUpperCase(), style: const TextStyle(fontSize: 8)),
                                    Text('${car.currentPassengers}/${car.capacity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons (only Next Level/Restart)
              if (game.isWin() || game.isLose())
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: game.isWin()
                              ? () => game.nextLevel()
                              : () => game.resetGame(),
                          child: Text(game.isWin() ? 'Next Level' : 'Restart'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
