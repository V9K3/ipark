import 'car_model.dart';

class ParkingSpot {
  Car? car;
  ParkingSpot({this.car});
  bool get isOccupied => car != null;
}
