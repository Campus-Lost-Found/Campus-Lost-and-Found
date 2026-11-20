import 'package:flutter/material.dart';

class FoundReport {
  final String title;
  final String category;
  final String location;
  final String description;
  final DateTime foundDate;
  final String type;

  const FoundReport({
    required this.title,
    required this.category,
    required this.location,
    required this.description,
    required this.foundDate,
    this.type = 'found',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'location': location,
        'description': description,
        'foundDate': foundDate.toIso8601String(),
        'type': type,
      };
}

class CreateFoundReportScreen extends StatefulWidget {
  final Future<void> Function(FoundReport report)? onSubmitReport;

  const CreateFoundReportScreen({super.key, this.onSubmitReport});

  @override
  State<CreateFoundReportScreen> createState() => _CreateFoundReportScreenState();
}

class _CreateFoundReportScreenState extends State<CreateFoundReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _categories = const [
    'Electronics',
    'ID & Cards',
    'Bags & Clothing',
    'Keys & Accessories',
    'Other',
  ];

  String _selectedCategory = 'Electronics';
  DateTime _foundDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _foundDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _foundDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final report = FoundReport(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      foundDate: _foundDate,
      type: 'found',
    );

    try {
      if (widget.onSubmitReport != null) {
        await widget.onSubmitReport!(report);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Found report submitted!')),
      );
      Navigator.pop(context, report);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Found Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Item Title *',
                  hintText: 'e.g., Black water bottle',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter an item title'
                        : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location Found *',
                  hintText: 'e.g., Library 2nd floor',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter where the item was found'
                        : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date Found'),
                subtitle: Text(_formatDate(_foundDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Color, brand, distinguishing marks...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Submitting...' : 'Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}