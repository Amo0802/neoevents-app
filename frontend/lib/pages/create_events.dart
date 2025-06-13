import 'dart:io';
import 'package:events_amo/models/event.dart';
import 'package:events_amo/providers/user_provider.dart';
import 'package:events_amo/utils/single_decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';

class CreateEventPage extends StatefulWidget {

  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  // Form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _selectedCategories = [];
  List<XFile>? _images = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Available categories
  final List<String> _availableCategories = [
    'Music', 'Sports', 'Art', 'Food', 'Technology'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _images = selectedImages;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return MultiSelectDialog(
          items: _availableCategories
              .map((category) => MultiSelectItem<String>(category, category))
              .toList(),
          initialValue: _selectedCategories,
          onConfirm: (values) {
            setState(() {
              _selectedCategories = values;
            });
          },
          title: const Text("Select Categories"),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedColor: Theme.of(context).colorScheme.secondary,
          selectedItemsTextStyle: TextStyle(color: Colors.white),
          itemsTextStyle: TextStyle(color: Colors.white),
          checkColor: Colors.white,
        );
      },
    );
  }

  Future<void> _submitEventProposal() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      setState(() {
        _errorMessage = "Please select both date and time";
      });
      _showSnackBar(_errorMessage!);
      return;
    }

    if (_selectedCategories.isEmpty) {
      setState(() {
        _errorMessage = "Please select at least one category";
      });
      _showSnackBar(_errorMessage!);
      return;
    }

    // if (_images == null || _images!.isEmpty) {
    //   setState(() {
    //     _errorMessage = "Please upload at least one image";
    //   });
    //   _showSnackBar(_errorMessage!);
    //   return;
    // }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

      // Create multipart request
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Combine date and time into a single DateTime
      final DateTime eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Add text fields
      final event = Event.forSubmission(
        name: _titleController.text,
        description: _descriptionController.text,
        address: _locationController.text,
        startDateTime: eventDateTime,
        price: double.tryParse(_priceController.text) ?? 0.0,
        categories: _selectedCategories,
      );

      // Add image files
      bool success = await userProvider.submitEventProposal(event, _images!);

      if (success) {
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = userProvider.error;
          _isLoading = false;
        });
        _showSnackBar(_errorMessage!);
      }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: const Text("Your event proposal has been submitted successfully. We will review it shortly."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to previous screen
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Create Event Request",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePicker(context),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _titleController,
                      label: "Event Title",
                      hint: "Enter event title",
                      inputFormatters: [LengthLimitingTextInputFormatter(50)],
                      maxLength: 50,  
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an event title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _locationController,
                      label: "Location",
                      hint: "Enter event location",
                      inputFormatters: [LengthLimitingTextInputFormatter(50)],
                      maxLength: 50, 
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an event location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _priceController,
                      label: "Price",
                      hint: "Enter event price",
                      maxLength: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an event price';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        SingleDecimalInputFormatter(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDateTimePicker(context),
                    const SizedBox(height: 20),
                    _buildCategoryPicker(context),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _descriptionController,
                      label: "Description",
                      hint: "Enter event description",
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an event description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    _buildSubmitButton(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: _images != null && _images!.isNotEmpty
            ? GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemCount: _images!.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_images![index].path),
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _images!.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Upload Event Images",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,   
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            fillColor: Colors.white.withValues(alpha: 0.07),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorStyle: const TextStyle(color: Colors.red),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    final String dateText = _selectedDate == null
        ? "Select Date"
        : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
        
    final String timeText = _selectedTime == null
        ? "Select Time"
        : _selectedTime!.format(context);
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Date & Time",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: _selectedDate == null && _errorMessage != null
                        ? Border.all(color: Colors.red)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dateText,
                        style: TextStyle(
                          color: _selectedDate == null ? Colors.grey[400] : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: _selectedTime == null && _errorMessage != null
                        ? Border.all(color: Colors.red)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        timeText,
                        style: TextStyle(
                          color: _selectedTime == null ? Colors.grey[400] : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Category",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showCategoriesDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: _selectedCategories.isEmpty && _errorMessage != null
                  ? Border.all(color: Colors.red)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _selectedCategories.isEmpty
                      ? Text(
                          "Select Categories",
                          style: TextStyle(color: Colors.grey[400]),
                        )
                      : Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: _selectedCategories
                              .map(
                                (category) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _submitEventProposal,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Send Request",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}