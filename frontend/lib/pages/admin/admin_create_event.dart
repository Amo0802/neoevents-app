import 'package:events_amo/models/event.dart';
import 'package:events_amo/providers/event_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:events_amo/utils/single_decimal.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';

class AdminCreateEventPage extends StatefulWidget {
  const AdminCreateEventPage({super.key});

  @override
  State<AdminCreateEventPage> createState() => _AdminCreateEventPageState();
}

class _AdminCreateEventPageState extends State<AdminCreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _mainImageUrlController = TextEditingController();
  final TextEditingController _otherImagesUrlController = TextEditingController();
  final TextEditingController _priorityController = TextEditingController(text: "0");
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _selectedCategories = [];
  String _selectedCity = 'PODGORICA';
  bool _isMainEvent = false;
  bool _isPromoted = false;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Available categories and cities
  final List<String> _availableCategories = [
    'MUSIC', 'SPORTS', 'ART', 'FOOD', 'TECHNOLOGY'
  ];
  
  final List<String> _availableCities = [
    'PODGORICA', 'BERANE', 'NIKSIC'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _mainImageUrlController.dispose();
    _otherImagesUrlController.dispose();
    _priorityController.dispose();
    super.dispose();
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

  Future<void> _createEvent() async {
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Combine date and time into a single DateTime
      final DateTime eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Create event object
      final event = Event(
        id: -1, // Placeholder ID to be replaced by backend
        name: _titleController.text,
        description: _descriptionController.text,
        imageUrl: _mainImageUrlController.text,
        city: _selectedCity,
        address: _locationController.text, // Make sure address is properly passed
        startDateTime: eventDateTime,
        price: double.tryParse(_priceController.text) ?? 0.0,
        categories: _selectedCategories,
        priority: int.tryParse(_priorityController.text) ?? 0,
        mainEvent: _isMainEvent,
        promoted: _isPromoted,
      );

      // Create the event
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final success = await eventProvider.createEvent(event);

      if (success) {
        _showSuccessDialog("Event created successfully");
      } else {
        setState(() {
          _errorMessage = eventProvider.error ?? "Failed to create event";
        });
        _showSnackBar(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackBar(_errorMessage!);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
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
          "Create Event (Admin)",
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
                    _buildCityDropdown(context),
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
                    _buildTextField(
                      controller: _priorityController,
                      label: "Priority",
                      hint: "Enter event priority (number)",
                      maxLength: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a priority';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Priority must be a number';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDateTimePicker(context),
                    const SizedBox(height: 20),
                    _buildCategoryPicker(context),
                    const SizedBox(height: 20),
                    _buildCheckboxes(context),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _mainImageUrlController,
                      label: "Main Image URL",
                      hint: "Enter URL for main event image",
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a URL for the main image';
                        }
                        if (!Uri.tryParse(value)!.isAbsolute) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _otherImagesUrlController,
                      label: "Other Image URLs (optional)",
                      hint: "Enter URLs separated by commas",
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final urls = value.split(',');
                          for (final url in urls) {
                            final trimmedUrl = url.trim();
                            if (trimmedUrl.isNotEmpty && !Uri.tryParse(trimmedUrl)!.isAbsolute) {
                              return 'Please enter valid URLs separated by commas';
                            }
                          }
                        }
                        return null;
                      },
                    ),
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

  Widget _buildCheckboxes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Event Status",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                title: Text(
                  "Main Event",
                  style: TextStyle(color: Colors.white),
                ),
                value: _isMainEvent,
                onChanged: (value) {
                  setState(() {
                    _isMainEvent = value ?? false;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
                checkColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: Text(
                  "Promoted Event",
                  style: TextStyle(color: Colors.white),
                ),
                value: _isPromoted,
                onChanged: (value) {
                  setState(() {
                    _isPromoted = value ?? false;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
                checkColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "City",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            dropdownColor: Theme.of(context).scaffoldBackgroundColor,
            style: TextStyle(color: Colors.white),
            items: _availableCities.map((city) {
              return DropdownMenuItem<String>(
                value: city,
                child: Text(
                  city,
                  style: TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCity = value;
                });
              }
            },
          ),
        ),
      ],
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
          "Categories",
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
        onPressed: _isLoading ? null : _createEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Create Event",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}