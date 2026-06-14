import 'package:flutter/material.dart';
import 'package:shop_manager/theme/app_themes.dart';

class MarketerContractDraft {
  const MarketerContractDraft({
    required this.name,
    required this.specialization,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.budgetTotal,
    required this.initialProgress,
    required this.conversionTarget,
    required this.channel,
    required this.goals,
  });

  final String name;
  final String specialization;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double budgetTotal;
  final double initialProgress;
  final double conversionTarget;
  final String channel;
  final List<String> goals;
}

class AddMarketerContractPage extends StatefulWidget {
  const AddMarketerContractPage({
    super.key,
    this.initialName,
    this.initialSpecialization,
    this.initialChannel,
  });

  final String? initialName;
  final String? initialSpecialization;
  final String? initialChannel;

  @override
  State<AddMarketerContractPage> createState() => _AddMarketerContractPageState();
}

class _AddMarketerContractPageState extends State<AddMarketerContractPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  final List<String> _channels = <String>[
    'Facebook Ads',
    'TikTok',
    'Google Ads',
    'Email',
    'Marketplace',
  ];

  final List<String> _goalOptions = <String>[
    'Increase orders',
    'Improve conversion',
    'Lower CPA',
    'Build audience',
    'Recover carts',
  ];

  String _selectedChannel = 'Facebook Ads';
  String _status = 'Pending';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  double _initialProgress = 15;
  double _conversionTarget = 3.2;
  final Set<String> _goals = <String>{'Increase orders'};

  TextStyle _fieldTextStyle(BuildContext context) {
    return AppThemes.poppins(
      context,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );
  }

  InputDecoration _quickFieldDecoration(
    BuildContext context, {
    required String label,
    Widget? prefixIcon,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(14);
    final BorderSide side = BorderSide(color: scheme.onSurface.withOpacity(0.10), width: 1);
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: AppThemes.poppins(
        context,
        fontSize: 11,
        color: scheme.onSurface.withOpacity(0.68),
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(borderRadius: radius, borderSide: side),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: side),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.20), width: 1.1),
      ),
    );
  }

  ButtonStyle _quickStrokeButtonStyle(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      backgroundColor: scheme.surface,
      side: BorderSide(color: scheme.onSurface.withOpacity(0.10), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      minimumSize: const Size.fromHeight(48),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _specializationController.text = widget.initialSpecialization ?? '';
    if (widget.initialChannel != null && _channels.contains(widget.initialChannel)) {
      _selectedChannel = widget.initialChannel!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  String _dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime initial = isStart ? _startDate : _endDate;
    final DateTime first = isStart ? now.subtract(const Duration(days: 365)) : _startDate;
    final DateTime last = now.add(const Duration(days: 365 * 2));

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = selected;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 14));
        }
      } else {
        _endDate = selected;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double budget = double.tryParse(_budgetController.text.trim()) ?? 0;
    if (budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Set a valid budget amount',
            style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'End date must be after start date',
            style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    final MarketerContractDraft draft = MarketerContractDraft(
      name: _nameController.text.trim(),
      specialization: _specializationController.text.trim(),
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
      budgetTotal: budget,
      initialProgress: _initialProgress / 100,
      conversionTarget: _conversionTarget,
      channel: _selectedChannel,
      goals: _goals.toList(),
    );

    Navigator.of(context).pop<MarketerContractDraft>(draft);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;

    return Scaffold(
      backgroundColor: bgBottom,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bgTop, bgBottom, bgBottom],
            stops: const <double>[0.0, 0.22, 1.0],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _nameController.text.trim().isEmpty ? 'Add Marketer Contract' : 'Hire ${_nameController.text.trim()}',
                        style: AppThemes.poppins(context, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _nameController.text.trim().isEmpty
                      ? 'Define contract structure, timeline, and measurable targets before launch.'
                      : 'Set contract terms with clear goals, then begin collaboration in chat.',
                  style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.66), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Quick Snapshot', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        _nameController.text.trim().isEmpty ? 'Marketer name' : _nameController.text.trim(),
                        style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _selectedChannel,
                        style: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.62), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_dateLabel(_startDate)} to ${_dateLabel(_endDate)}',
                        style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  style: _fieldTextStyle(context),
                  decoration: _quickFieldDecoration(
                    context,
                    label: 'Marketer Name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (String? value) => (value == null || value.trim().length < 3) ? 'Enter full marketer name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _specializationController,
                  style: _fieldTextStyle(context),
                  decoration: _quickFieldDecoration(
                    context,
                    label: 'Specialization',
                    
                    prefixIcon: const Icon(Icons.work_outline_rounded),
                  ),
                  validator: (String? value) => (value == null || value.trim().isEmpty) ? 'Specialization is required' : null,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool stackFields = constraints.maxWidth < 360;
                    final Widget channelField = DropdownButtonFormField<String>(
                      initialValue: _selectedChannel,
                      isExpanded: true,
                      style: _fieldTextStyle(context),
                      decoration: _quickFieldDecoration(context, label: 'Channel'),
                      items: _channels.map((String channel) => DropdownMenuItem<String>(value: channel, child: Text(channel))).toList(),
                      onChanged: (String? value) {
                        if (value == null) return;
                        setState(() => _selectedChannel = value);
                      },
                    );
                    final Widget statusField = DropdownButtonFormField<String>(
                      initialValue: _status,
                      isExpanded: true,
                      style: _fieldTextStyle(context),
                      decoration: _quickFieldDecoration(context, label: 'Status'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem<String>(value: 'Active', child: Text('Active')),
                        DropdownMenuItem<String>(value: 'Expiring Soon', child: Text('Expiring Soon')),
                      ],
                      onChanged: (String? value) {
                        if (value == null) return;
                        setState(() => _status = value);
                      },
                    );

                    if (stackFields) {
                      return Column(
                        children: <Widget>[
                          channelField,
                          const SizedBox(height: 14),
                          statusField,
                        ],
                      );
                    }

                    return Row(
                      children: <Widget>[
                        Expanded(child: channelField),
                        const SizedBox(width: 8),
                        Expanded(child: statusField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _budgetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: _fieldTextStyle(context),
                  decoration: _quickFieldDecoration(
                    context,
                    label: 'Budget Total (ETB)',
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  validator: (String? value) => (double.tryParse((value ?? '').trim()) ?? 0) <= 0 ? 'Enter valid budget' : null,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool stackButtons = constraints.maxWidth < 380;
                    final Widget startButton = OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: true),
                      style: _quickStrokeButtonStyle(context),
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(
                        'Start ${_dateLabel(_startDate)}',
                        overflow: TextOverflow.ellipsis,
                        style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    );
                    final Widget endButton = OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: false),
                      style: _quickStrokeButtonStyle(context),
                      icon: const Icon(Icons.event_rounded),
                      label: Text(
                        'End ${_dateLabel(_endDate)}',
                        overflow: TextOverflow.ellipsis,
                        style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    );

                    if (stackButtons) {
                      return Column(
                        children: <Widget>[
                          SizedBox(width: double.infinity, child: startButton),
                          const SizedBox(height: 14),
                          SizedBox(width: double.infinity, child: endButton),
                        ],
                      );
                    }

                    return Row(
                      children: <Widget>[
                        Expanded(child: startButton),
                        const SizedBox(width: 8),
                        Expanded(child: endButton),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.onSurface.withOpacity(0.09)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Initial Campaign Progress ${_initialProgress.toStringAsFixed(0)}%',
                        style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      Slider(
                        value: _initialProgress,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '${_initialProgress.toStringAsFixed(0)}%',
                        onChanged: (double value) => setState(() => _initialProgress = value),
                      ),
                      Text(
                        'Conversion Target ${_conversionTarget.toStringAsFixed(1)}%',
                        style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      Slider(
                        value: _conversionTarget,
                        min: 1.0,
                        max: 8.0,
                        divisions: 28,
                        label: '${_conversionTarget.toStringAsFixed(1)}%',
                        onChanged: (double value) => setState(() => _conversionTarget = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Contract Goals', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _goalOptions.map((String goal) {
                    final bool selected = _goals.contains(goal);
                    return FilterChip(
                      label: Text(goal),
                      selected: selected,
                      onSelected: (bool value) {
                        setState(() {
                          if (value) {
                            _goals.add(goal);
                          } else {
                            _goals.remove(goal);
                          }
                          if (_goals.isEmpty) {
                            _goals.add(_goalOptions.first);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text('Create Contract', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
