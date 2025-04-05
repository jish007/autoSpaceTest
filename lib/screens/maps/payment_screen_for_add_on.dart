import 'package:autospaxe/screens/maps/booking_page_wigets.dart';
import 'package:autospaxe/screens/maps/success_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import 'invoice_page.dart';

class PaymentMethodsScreenForAddOn extends StatefulWidget {
  final int fare;
  final String duration;
  final String vehicleNum;

  const PaymentMethodsScreenForAddOn(
      {Key? key,
      required this.fare,
      required this.duration,
      required this.vehicleNum})
      : super(key: key);

  @override
  State<PaymentMethodsScreenForAddOn> createState() =>
      _PaymentMethodsScreenForAddOnState();
}

class _PaymentMethodsScreenForAddOnState
    extends State<PaymentMethodsScreenForAddOn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  PaymentMethodItem(
                    logo: 'lib/assets/images/Visa.png',
                    name: 'Visa',
                    onTap: () => _navigateToAddCard(context),
                    fare: widget.fare,
                  ),
                  PaymentMethodItem(
                    logo: 'lib/assets/images/Mastercard.png',
                    name: 'MasterCard',
                    onTap: () => _navigateToAddCard(context),
                    fare: widget.fare,
                  ),
                  PaymentMethodItem(
                    logo: 'lib/assets/images/Amex.png',
                    name: 'American Express',
                    onTap: () => _navigateToAddCard(context),
                    fare: widget.fare,
                  ),
                  PaymentMethodItem(
                    logo: 'lib/assets/images/PayPal.png',
                    name: 'PayPal',
                    onTap: () => _navigateToAddCard(context),
                    fare: widget.fare,
                  ),
                  PaymentMethodItem(
                    logo: 'lib/assets/images/DC.png',
                    name: 'Diners',
                    onTap: () => _navigateToAddCard(context),
                    fare: widget.fare,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AddPaymentButton(
                  onTap: () => _navigateToAddCard(context),
                  fare: widget.fare,
                ),
              ),
              const SizedBox(height: 6), // Extra space at the bottom
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddCard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddCardScreen(
                fare: widget.fare,
                duration: widget.duration,
                vehicleNum: widget.vehicleNum,
              )),
    );
  }
}

// 3. PaymentMethodItem - Individual payment method list item
class PaymentMethodItem extends StatelessWidget {
  final String logo;
  final String name;
  final VoidCallback onTap;
  final int fare;

  const PaymentMethodItem(
      {Key? key,
      required this.logo,
      required this.name,
      required this.onTap,
      required this.fare})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF2A2A2A),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Image.asset(logo, width: 30, height: 30),
            ),
            const SizedBox(width: 16),
            Text(name, style: AppTheme.bodyStyle),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFF2F50FD)),
          ],
        ),
      ),
    );
  }
}

// 4. AddPaymentButton - Button to add a new payment method
class AddPaymentButton extends StatelessWidget {
  final VoidCallback onTap;
  final int fare;

  AddPaymentButton({
    Key? key,
    required this.onTap,
    required this.fare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Payment Method',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. AddCardScreen - Screen to add a new card
class AddCardScreen extends StatefulWidget {
  final int fare;
  final String duration;
  final String vehicleNum;

  const AddCardScreen(
      {Key? key,
      required this.fare,
      required this.duration,
      required this.vehicleNum})
      : super(key: key);

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  String _cardholderName = ''; // To store the name

  final ApiService apiService = ApiService();

  Future<void> bookSlot(BuildContext context) async {
    try {
      final response = await apiService.addOnSlot(widget.vehicleNum.toString(),
          widget.duration.toString(), widget.fare.toString());

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PaymentSuccessScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Successfully Booked")),
        );
      } else {
        String errorMessage = "Failed";
        if (response.statusCode == 400) {
          errorMessage = "Bad request. Please check your input.";
        } else {
          errorMessage = "An error occurred. Please try again.";
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      print("Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment Methods'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardPreview(),
                const SizedBox(height: 30),
                const Text('Enter your payment details',
                    style: AppTheme.bodyStyle),
                const SizedBox(height: 8),
                const Text('By continuing you agree to our Terms',
                    style: AppTheme.captionStyle),
                const SizedBox(height: 16),
                CardForm(
                  onNameChanged: (value) {
                    setState(() {
                      _cardholderName =
                          value; // Update the name when it changes
                    });
                  },
                  onSubmit: () {
                    bookSlot(context);
                  },
                  fare: widget.fare,
                ),
                const SizedBox(height: 20), // Extra space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 6. CardForm - Form to enter card details
class CardForm extends StatefulWidget {
  final VoidCallback onSubmit;
  final Function(String) onNameChanged;
  final int fare;

  const CardForm({
    Key? key,
    required this.onSubmit,
    required this.onNameChanged,
    required this.fare,
  }) : super(key: key);

  @override
  State<CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<CardForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  String? _selectedMonth;
  String? _selectedYear;
  bool _isDefault = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      widget.onNameChanged(_nameController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate bottom padding to avoid navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;

    return Stack(
      children: [
        // Main form content
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Name ',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  hintText: 'Card Number',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        hintText: 'Month',
                      ),
                      value: _selectedMonth,
                      items: List.generate(
                        12,
                        (index) => DropdownMenuItem(
                          value: (index + 1).toString().padLeft(2, '0'),
                          child: Text((index + 1).toString().padLeft(2, '0')),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        hintText: 'Year',
                      ),
                      value: _selectedYear,
                      items: List.generate(
                        10,
                        (index) => DropdownMenuItem(
                          value: (DateTime.now().year + index).toString(),
                          child: Text((DateTime.now().year + index).toString()),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(
                  hintText: 'CVV',
                ),
                keyboardType: TextInputType.number,
                maxLength: 4, // Allow for Amex cards which have 4-digit CVV
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Container(
                    child: Row(
                      children: [
                        Switch(
                          value: _isDefault,
                          onChanged: (value) {
                            setState(() {
                              _isDefault = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const Text('Set as default', style: AppTheme.bodyStyle),
                      ],
                    ),
                  ),
                ],
              ),
              // Added an additional SizedBox to create more space after the switch
              const SizedBox(height: 80),
              // Add extra space at the bottom to avoid navigation bar overlap
              SizedBox(height: 60 + bottomPadding),
            ],
          ),
        ),

        // Button positioned at the bottom, adjusted to avoid navigation bar
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomPadding,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: widget.onSubmit,
              child: const Text('Review Payment'),
            ),
          ),
        ),
      ],
    );
  }
}

// Extra class for card preview (shown in the AddCardScreen)
class CardPreview extends StatelessWidget {
  const CardPreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.fromARGB(255, 19, 22, 74), Color(0xFF0A0C2B)],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Icon(Icons.remove_red_eye, color: Color(0xFF2F50FD)),
            ],
          ),
          const Spacer(),
          const Text(
            '**** **** **** 3947',
            style: TextStyle(
              color: Color(0xFF2F50FD),
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Holder Name',
                    style: TextStyle(
                      color: Color(0xFFA3FD30),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '',
                    style: TextStyle(
                      color: Color(0xFFA3FD30),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expiry Date',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '05/23',
                    style: TextStyle(
                      color: Color(0xFFFDF9F9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFFFFFCFC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.credit_card,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// NEW SCREEN: PaymentConfirmationScreen - Shows entered card details and confirms payment
class PaymentConfirmationScreen extends StatefulWidget {
  final String cardholderName;
  final String cardNumber;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final bool isDefault;
  final int fare;
  final BookingData bookingData;
  final VehicleOption vehicleOption;

  const PaymentConfirmationScreen({
    Key? key,
    required this.cardholderName,
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    this.isDefault = false,
    required this.vehicleOption,
    required this.bookingData,
    required this.fare,
  }) : super(key: key);

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Payment'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Review your payment details',
                    style: AppTheme.bodyStyle),
                const Text('Please confirm all information is correct',
                    style: AppTheme.captionStyle),
                const SizedBox(height: 24),

                // Card preview in confirmation screen
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1F71), Color(0xFF0A0C2B)],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 50,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Icon(Icons.credit_card,
                              color: Color(0xFF2F50FD)),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        widget.cardNumber,
                        style: const TextStyle(
                          color: Color(0xFF2F50FD),
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Card Holder Name',
                                style: TextStyle(
                                  color: Color(0xFFA3FD30),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.cardholderName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Expiry Date',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.expiryMonth}/${widget.expiryYear}',
                                style: const TextStyle(
                                  color: Color(0xFFFDF9F9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFCFC),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.credit_card,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _buildDetailItem('Cardholder Name', widget.cardholderName),
                _buildDetailItem('Card Number', widget.cardNumber),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem('Exp Month', widget.expiryMonth),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailItem('Exp Year', widget.expiryYear),
                    ),
                  ],
                ),

                _buildDetailItem('CVV', widget.cvv),

                // Payment amount section
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sub total', style: AppTheme.bodyStyle),
                          Text('Rs: ${widget.fare}', style: AppTheme.bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tax', style: AppTheme.bodyStyle),
                          Text('Rs: 0.0', style: AppTheme.bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(color: AppTheme.primaryColor.withOpacity(0.2)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          Text(
                            'Rs: ${widget.fare}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Switch(
                      value: widget.isDefault,
                      onChanged: (value) {},
                      activeColor: AppTheme.primaryColor,
                    ),
                    const Text('Set as default payment method',
                        style: AppTheme.bodyStyle),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: AppTheme.backgroundColor,
                            title: const Text('Confirm Payment',
                                style: AppTheme.headingStyle),
                            content: Text(
                              'Are you sure you want to process payment of Rs: ${widget.fare}?',
                              style: AppTheme.bodyStyle,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.7)),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                  // Navigate to success screen with the correct name
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CardAddedScreen(
                                        cardholderName: widget.cardholderName,
                                        vehicleOption: widget.vehicleOption,
                                        bookingData: widget.bookingData,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Confirm'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Confirm Payment'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Edit Payment Details',
                      style: TextStyle(
                          color: AppTheme.primaryColor.withOpacity(0.8)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build detail items
  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(label, style: AppTheme.captionStyle),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: AppTheme.captionStyle),
        ),
      ],
    );
  }
}

// 7. CardAddedScreen - Screen shown after a card is added
class CardAddedScreen extends StatefulWidget {
  final String cardholderName; // Add this parameter
  final VehicleOption vehicleOption;
  final BookingData bookingData;

  const CardAddedScreen(
      {Key? key,
      this.cardholderName = '',
      required this.vehicleOption,
      required this.bookingData})
      : super(key: key);

  @override
  State<CardAddedScreen> createState() => _CardAddedScreenState();
}

class _CardAddedScreenState extends State<CardAddedScreen> {
  final ApiService apiService = ApiService();

  Future<void> bookSlot(
      BuildContext context,
      String vehicleNumber,
      String bookingDate,
      String endtime,
      String slotId,
      String paidAmount,
      String bookingTime,
      String bookingSource,
      int durationOfAllocation) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePage(
          // You can customize these values if needed
          fromLocation: "Your Current Location",
          toLocation: widget.bookingData.toLocation,
          parkingSlot: widget.bookingData.parkingSlot,
          parkingSlotId: widget.bookingData.parkingSlotId,
          bookingTime: widget.bookingData.bookingTime,
          vehicleBrand: widget.vehicleOption.brand,
          vehicleModel: widget.vehicleOption.model,
          vehicleType: widget.vehicleOption.type,
          vehicleNum: widget.vehicleOption.vehicleNum,
          parkingName: widget.bookingData.parkingName,
          parkingAddress: widget.bookingData.parkingAddress,
          parkingRating: 4.7,
          invoiceNumber: "INV-20250302-7842",
          bookingDate: widget.bookingData.bookingDate.toString(),
          amount: widget.bookingData.parkingFare as double,
          paymentMethod: "Credit Card",
          transactionId: "TXN-78943213",
        ),
      ),
    );
    /*try {
      final response = await apiService.bookSlot(
          vehicleNumber,
          bookingDate,
          endtime,
          slotId,
          paidAmount,
          bookingTime,
          bookingSource,
          durationOfAllocation,
      );


      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  InvoicePage(
              // You can customize these values if needed
              fromLocation: "Your Current Location",
              toLocation: widget.bookingData.toLocation,
              parkingSlot: widget.bookingData.parkingSlot,
              parkingSlotId: widget.bookingData.parkingSlotId,
              bookingTime: widget.bookingData.bookingTime,
              vehicleBrand: widget.vehicleOption.brand,
              vehicleModel: widget.vehicleOption.model,
              vehicleType: widget.vehicleOption.type,
              vehicleNum: widget.vehicleOption.vehicleNum,
              parkingName: widget.bookingData.parkingName,
              parkingAddress: widget.bookingData.parkingAddress,
              parkingRating: 4.7,
              invoiceNumber: "INV-20250302-7842",
              bookingDate: widget.bookingData.bookingDate.toString(),
              amount: widget.bookingData.parkingFare as double,
              paymentMethod: "Credit Card",
              transactionId: "TXN-78943213",
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Successfully Booked")),
        );
      } else {
        String errorMessage = "Failed";
        if (response.statusCode == 400) {
          errorMessage = "Bad request. Please check your input.";
        } else {
          errorMessage = "An error occurred. Please try again.";
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      print("Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("An error occurred. Please try again.")),
        );
      }
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Methods'),
        leading: BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter your payment details', style: AppTheme.bodyStyle),
                Text('By continuing you agree to our Terms',
                    style: AppTheme.captionStyle),
                SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'lib/assets/images/PayPal.png',
                          width: 30,
                          height: 30,
                        ),
                        Image.asset(
                          'lib/assets/images/Visa.png',
                          width: 30,
                          height: 30,
                        ),
                        Image.asset(
                          'lib/assets/images/Mastercard.png',
                          width: 30,
                          height: 30,
                        ),
                        Image.asset(
                          'lib/assets/images/DC.png',
                          width: 30,
                          height: 30,
                        ),
                        Image.asset(
                          'lib/assets/images/Amex.png',
                          width: 30,
                          height: 30,
                        ),
                      ],
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),
                Text('Cardholder name', style: AppTheme.captionStyle),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.cardholderName,
                      style: AppTheme
                          .bodyStyle), // Use the name passed to this screen
                ),

                SizedBox(height: 16),
                Text('Card Number', style: AppTheme.captionStyle),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('**** **** **** 3947', style: AppTheme.bodyStyle),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Exp Month', style: AppTheme.captionStyle),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('12', style: AppTheme.bodyStyle),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Exp Year', style: AppTheme.captionStyle),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('2024', style: AppTheme.bodyStyle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),
                Text('CVV', style: AppTheme.captionStyle),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('123', style: AppTheme.bodyStyle),
                ),

                SizedBox(height: 16),
                Row(
                  children: [
                    Switch(
                      value: false,
                      onChanged: (value) {},
                      activeColor: AppTheme.primaryColor,
                    ),
                    Text('Set as default', style: AppTheme.bodyStyle),
                  ],
                ),

                SizedBox(height: 30), // Add spacing
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      String bookingDate;
                      String endtime;
                      String bookingTime = widget.bookingData.bookingTime;

                      DateTime now = DateTime.now();
                      DateFormat formatter = DateFormat("yyyy-MM-dd HH:mm:ss");
                      bookingDate = formatter.format(now);

                      List<String> timeParts = bookingTime.split(" - ");
                      String startTimeStr = timeParts[0];
                      String endTimeStr = timeParts[1];

                      DateTime startDateTime =
                          DateFormat("hh:mm a").parse(startTimeStr);

                      DateTime endDateTime =
                          DateFormat("hh:mm a").parse(endTimeStr);

                      DateTime bookingDateTime = now;

                      if (endDateTime.hour < startDateTime.hour) {
                        bookingDateTime =
                            bookingDateTime.add(Duration(days: 1));
                      }

                      DateTime finalEndTime = DateTime(
                        bookingDateTime.year,
                        bookingDateTime.month,
                        bookingDateTime.day,
                        endDateTime.hour,
                        endDateTime.minute,
                        0,
                      );

                      endtime = DateFormat("yyyy-MM-dd HH:mm:ss")
                          .format(finalEndTime);

                      int durationOfAllocation =
                          finalEndTime.difference(now).inMinutes;

                      bookSlot(
                          context,
                          widget.vehicleOption.vehicleNum,
                          bookingDate,
                          endtime,
                          widget.bookingData.parkingSlotId,
                          widget.bookingData.parkingFare.toString(),
                          widget.bookingData.bookingTime,
                          "Credit Card",
                          durationOfAllocation);
                    },
                    child: const Text('Add now'),
                  ),
                ),
                const SizedBox(height: 6), // Extra space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Colors
  static const Color backgroundColor = Color(0xFF171617);
  static const Color cardColor = Color(0xFF171617);
  static const Color primaryColor = Color(0xFF5B78F6);
  static const Color textColor = Color(0xFFA3FD30);
  static const Color secondaryTextColor = Color(0xFFA3FD30);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: textColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: secondaryTextColor,
  );

  // Theme Data
  static final ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      surface: cardColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      titleTextStyle: headingStyle,
      iconTheme: IconThemeData(color: textColor),
    ),
    textTheme: const TextTheme(
      bodyLarge: bodyStyle,
      bodyMedium: bodyStyle,
      titleMedium: headingStyle,
      titleSmall: captionStyle,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        textStyle: bodyStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: captionStyle,
      contentPadding: const EdgeInsets.all(16),
    ),
  );
}
