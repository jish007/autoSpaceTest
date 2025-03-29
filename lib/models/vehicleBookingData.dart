// Update your BookingData class or create a new model class
class VehicleBookingData {
  final String vehicleNumber;
  final String phoneNum;
  final String userName;
  final int noOfVehicles;
  final String vehicleType;
  final String? bookingDate;
  final String userEmailId;
  final bool paidStatus;
  final double paidAmount;
  final String? allocatedSlotNumber;
  final String? parkedPropertyName;
  final String? durationOfAllocation;
  final String? paymentDate;
  final String adminMailId;
  final String vehicleModel;
  final double totalAmount;
  final String bookingTime;
  final double fineAmount;
  final String? bookingSource;
  final String? roleName;
  final String vehicleBrand;
  final String fuelType;
  final String vehicleClr;
  final String vehicleGene;
  final String endtime;
  final String? remainingtime;
  final bool banned;

  VehicleBookingData({
    required this.vehicleNumber,
    required this.phoneNum,
    required this.userName,
    required this.noOfVehicles,
    required this.vehicleType,
    this.bookingDate,
    required this.userEmailId,
    required this.paidStatus,
    required this.paidAmount,
    this.allocatedSlotNumber,
    this.parkedPropertyName,
    this.durationOfAllocation,
    this.paymentDate,
    required this.adminMailId,
    required this.vehicleModel,
    required this.totalAmount,
    required this.bookingTime,
    required this.fineAmount,
    this.bookingSource,
    this.roleName,
    required this.vehicleBrand,
    required this.fuelType,
    required this.vehicleClr,
    required this.vehicleGene,
    required this.endtime,
    this.remainingtime,
    required this.banned,
  });

  factory VehicleBookingData.fromJson(Map<String, dynamic> json) {
    return VehicleBookingData(
      vehicleNumber: json['vehicleNumber'] ?? '',
      phoneNum: json['phoneNum'] ?? '',
      userName: json['userName'] ?? '',
      noOfVehicles: json['noOfVehicles'] ?? 0,
      vehicleType: json['vehicleType'] ?? '',
      bookingDate: json['bookingDate'],
      userEmailId: json['userEmailId'] ?? '',
      paidStatus: json['paidStatus'] ?? false,
      paidAmount: (json['paidAmount'] ?? 0.0).toDouble(),
      allocatedSlotNumber: json['allocatedSlotNumber'],
      parkedPropertyName: json['parkedPropertyName'],
      durationOfAllocation: json['durationOfAllocation'],
      paymentDate: json['paymentDate'],
      adminMailId: json['adminMailId'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      bookingTime: json['bookingTime'] ?? '',
      fineAmount: (json['fineAmount'] ?? 0.0).toDouble(),
      bookingSource: json['bookingSource'],
      roleName: json['roleName'],
      vehicleBrand: json['vehicleBrand'] ?? '',
      fuelType: json['fuelType'] ?? '',
      vehicleClr: json['vehicleClr'] ?? '',
      vehicleGene: json['vehicleGene'] ?? '',
      endtime: json['endtime'] ?? '',
      remainingtime: json['remainingtime'],
      banned: json['banned'] ?? false,
    );
  }
}