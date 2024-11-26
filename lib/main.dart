import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Agendamentos',
      theme: ThemeData(
        primaryColor: const Color(0xFFF8B7D5),
        scaffoldBackgroundColor: const Color(0xFFFBE4E7),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFFF8B7D5), 
            foregroundColor: Colors.white, 
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> appointments = [];
  late AnimationController _animationController;
  bool _showAnimation = false;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('appointments');
    if (storedData != null) {
      setState(() {
        appointments = List<Map<String, dynamic>>.from(jsonDecode(storedData));
      });
    }
  }

  Future<void> _saveAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appointments', jsonEncode(appointments));
  }

  void _addAppointment(String title, DateTime dateTime) {
    final formattedDate = DateFormat('dd/MM/yyyy - HH:mm').format(dateTime);
    setState(() {
      appointments.add({'title': title, 'dateTime': formattedDate});
      _saveAppointments();
      _triggerFlowerAnimation();
    });
  }

  void _triggerFlowerAnimation() {
    setState(() {
      _showAnimation = true;
    });
    _animationController.forward().then((_) {
      _animationController.reset();
      setState(() {
        _showAnimation = false;
      });
    });
  }

  void _deleteAppointment(int index) {
    setState(() {
      appointments.removeAt(index);
      _saveAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Agendamentos'),
            centerTitle: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
            elevation: 5,
          ),
          body: ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  title: Text(appointment['title']),
                  subtitle: Text(appointment['dateTime']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Color.fromRGBO(255, 144, 209, 1)),
                    onPressed: () => _deleteAppointment(index),
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAppointmentPage(onAdd: _addAppointment),
                ),
              );
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.add),
          ),
        ),
        if (_showAnimation) _buildFlowerAnimation(),
      ],
    );
  }

  Widget _buildFlowerAnimation() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: 1 - _animationController.value,
            child: Transform.translate(
              offset: Offset(0, -300 * _animationController.value),
              child: Center(
                child: Icon(
                  Icons.local_florist,
                  color: Colors.pink[200],
                  size: 100,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AddAppointmentPage extends StatefulWidget {
  final Function(String, DateTime) onAdd;

  const AddAppointmentPage({Key? key, required this.onAdd}) : super(key: key);

  @override
  _AddAppointmentPageState createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _selectedDateTime;

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedDateTime != null) {
      widget.onAdd(_titleController.text, _selectedDateTime!);
      Navigator.pop(context);
    } else if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione data e horário.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Agendamento'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título do Agendamento'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    _selectedDateTime == null
                        ? 'Nenhuma data e horário selecionados'
                        : DateFormat('dd/MM/yyyy - HH:mm').format(_selectedDateTime!),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _selectDateTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8B7D5), 
                      foregroundColor: Colors.white, 
                    ),
                    child: const Text('Data e Horário'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8B7D5), 
                  foregroundColor: Colors.white, 
                ),
                child: const Text('Salvar Agendamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
