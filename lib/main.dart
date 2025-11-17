import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const TicketSystemApp());
}

class TicketSystemApp extends StatelessWidget {
  const TicketSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Professional Ticket System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TicketHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum TicketStatus {
  open('Open', Colors.orange, Icons.inbox),
  inProgress('In Progress', Colors.blue, Icons.build),
  resolved('Resolved', Colors.green, Icons.check_circle),
  closed('Closed', Colors.grey, Icons.archive);

  final String text;
  final Color color;
  final IconData icon;
  const TicketStatus(this.text, this.color, this.icon);
}

enum TicketPriority {
  low('Low', Colors.green, Icons.low_priority),
  normal('Normal', Colors.blue, Icons.flag),
  high('High', Colors.orange, Icons.priority_high),
  urgent('Urgent', Colors.red, Icons.warning);

  final String text;
  final Color color;
  final IconData icon;
  const TicketPriority(this.text, this.color, this.icon);
}

class Ticket {
  String id;
  String title;
  String description;
  String customer;
  String assignedTo;
  TicketStatus status;
  TicketPriority priority;
  DateTime createdAt;
  DateTime updatedAt;

  Ticket({
    required this.title,
    required this.description,
    required this.customer,
    this.priority = TicketPriority.normal,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        status = TicketStatus.open,
        assignedTo = 'Not Assigned',
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  void changeStatus(TicketStatus newStatus) {
    status = newStatus;
    updatedAt = DateTime.now();
  }

  void assign(String employee) {
    assignedTo = employee;
    updatedAt = DateTime.now();
  }

  void changePriority(TicketPriority newPriority) {
    priority = newPriority;
    updatedAt = DateTime.now();
  }

  String get formattedTime {
    return DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'customer': customer,
      'assignedTo': assignedTo,
      'status': status.index,
      'priority': priority.index,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final ticket = Ticket(
      title: json['title'],
      description: json['description'],
      customer: json['customer'],
      priority: TicketPriority.values[json['priority']],
    )
      ..id = json['id']
      ..assignedTo = json['assignedTo']
      ..status = TicketStatus.values[json['status']]
      ..createdAt = DateTime.parse(json['createdAt'])
      ..updatedAt = DateTime.parse(json['updatedAt']);

    return ticket;
  }
}

class TicketManager {
  final List<Ticket> _tickets = [];
  final List<String> _employees = ['Max Mustermann', 'Anna Schmidt', 'Tom Weber', 'Lisa Fischer'];
  static const String _storageKey = 'tickets_data';

  List<Ticket> get tickets => List.unmodifiable(_tickets);
  List<String> get employees => List.unmodifiable(_employees);

  Future<void> saveTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final ticketsJson = _tickets.map((ticket) => ticket.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(ticketsJson));
  }

  Future<void> loadTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final ticketsJson = prefs.getString(_storageKey);
    
    if (ticketsJson != null) {
      final List<dynamic> decoded = json.decode(ticketsJson);
      _tickets.clear();
      _tickets.addAll(decoded.map((json) => Ticket.fromJson(json)).toList());
    } else {
      _createSampleTickets();
    }
  }

  void _createSampleTickets() {
    createTicket(
      'Login Problem',
      'Cannot login to the system',
      'max.mustermann@email.com',
      TicketPriority.high,
    );

    createTicket(
      'Slow Performance',
      'Application runs very slow',
      'firma-abc@gmx.de',
      TicketPriority.normal,
    );
  }

  void createTicket(String title, String description, String customer, TicketPriority priority) {
    final newTicket = Ticket(
      title: title,
      description: description,
      customer: customer,
      priority: priority,
    );
    _tickets.insert(0, newTicket);
    saveTickets();
  }

  void deleteTicket(String ticketId) {
    _tickets.removeWhere((ticket) => ticket.id == ticketId);
    saveTickets();
  }

  void deleteAllTickets() {
    _tickets.clear();
    saveTickets();
  }

  List<Ticket> ticketsByStatus(TicketStatus status) {
    return _tickets.where((ticket) => ticket.status == status).toList();
  }

  void autoAssign(String ticketId) {
    final ticket = _tickets.firstWhere((t) => t.id == ticketId);
    final randomEmployee = _employees[_tickets.length % _employees.length];
    ticket.assign(randomEmployee);
    ticket.changeStatus(TicketStatus.inProgress);
    saveTickets();
  }

  Map<TicketStatus, int> get statistics {
    final stats = <TicketStatus, int>{};
    for (final status in TicketStatus.values) {
      stats[status] = ticketsByStatus(status).length;
    }
    return stats;
  }
}

class TicketHomePage extends StatefulWidget {
  const TicketHomePage({super.key});

  @override
  State<TicketHomePage> createState() => _TicketHomePageState();
}

class _TicketHomePageState extends State<TicketHomePage> {
  final TicketManager _ticketManager = TicketManager();
  TicketStatus _currentFilter = TicketStatus.open;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    await _ticketManager.loadTickets();
    setState(() {
      _isLoading = false;
    });
  }

  void _createSampleTickets() {
    _ticketManager.createTicket(
      'Login Problem',
      'Cannot login to the system',
      'max.mustermann@email.com',
      TicketPriority.high,
    );

    _ticketManager.createTicket(
      'Slow Performance',
      'Application runs very slow',
      'firma-abc@gmx.de',
      TicketPriority.normal,
    );
    setState(() {});
  }

  void _createNewTicket() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateTicketDialog(
        onTicketCreated: (title, description, customer, priority) {
          _ticketManager.createTicket(title, description, customer, priority);
          setState(() {});
        },
      ),
    );
  }

  void _showTicketDetails(Ticket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TicketDetailsDialog(
        ticket: ticket,
        ticketManager: _ticketManager,
        onUpdated: () => setState(() {}),
        onDelete: () {
          _ticketManager.deleteTicket(ticket.id);
          setState(() {});
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _deleteAllTickets() async {
    final shouldDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Tickets?'),
        content: const Text('This will permanently delete all tickets. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _ticketManager.deleteAllTickets();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTickets = _ticketManager.ticketsByStatus(_currentFilter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Ticket System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(),
            tooltip: 'Statistics',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Create Sample Tickets'),
                onTap: _createSampleTickets,
              ),
              PopupMenuItem(
                child: const Text('Delete All Tickets'),
                onTap: _deleteAllTickets,
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: TicketStatus.values.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status.text),
                          selected: _currentFilter == status,
                          onSelected: (_) => setState(() => _currentFilter = status),
                          backgroundColor: status.color.withOpacity(0.1),
                          selectedColor: status.color.withOpacity(0.3),
                          labelStyle: TextStyle(
                            color: _currentFilter == status ? status.color : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: filteredTickets.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No tickets found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = filteredTickets[index];
                            return TicketCard(
                              ticket: ticket,
                              onTap: () => _showTicketDetails(ticket),
                              onAutoAssign: () {
                                _ticketManager.autoAssign(ticket.id);
                                setState(() {});
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTicket,
        tooltip: 'Create New Ticket',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showStatistics() {
    final stats = _ticketManager.statistics;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ticket Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: TicketStatus.values.map((status) {
            final count = stats[status] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(status.icon, color: status.color, size: 20),
                  const SizedBox(width: 8),
                  Text('${status.text}: $count'),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  final VoidCallback onAutoAssign;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
    required this.onAutoAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 8,
          decoration: BoxDecoration(
            color: ticket.priority.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          ticket.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.customer,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ticket.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket.status.text,
                    style: TextStyle(
                      color: ticket.status.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ticket.formattedTime,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ticket.status == TicketStatus.open)
              IconButton(
                icon: const Icon(Icons.auto_awesome, size: 20),
                onPressed: onAutoAssign,
                tooltip: 'Auto Assign',
              ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: onTap,
              tooltip: 'Ticket Details',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class CreateTicketDialog extends StatefulWidget {
  final Function(String, String, String, TicketPriority) onTicketCreated;

  const CreateTicketDialog({super.key, required this.onTicketCreated});

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerController = TextEditingController();
  TicketPriority _priority = TicketPriority.normal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Ticket',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TicketPriority>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: TicketPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(priority.icon, color: priority.color, size: 16),
                        const SizedBox(width: 8),
                        Text(priority.text),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _priority = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onTicketCreated(
                            _titleController.text,
                            _descriptionController.text,
                            _customerController.text,
                            _priority,
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TicketDetailsDialog extends StatefulWidget {
  final Ticket ticket;
  final TicketManager ticketManager;
  final VoidCallback onUpdated;
  final VoidCallback onDelete;

  const TicketDetailsDialog({
    super.key,
    required this.ticket,
    required this.ticketManager,
    required this.onUpdated,
    required this.onDelete,
  });

  @override
  State<TicketDetailsDialog> createState() => _TicketDetailsDialogState();
}

class _TicketDetailsDialogState extends State<TicketDetailsDialog> {
  late Ticket ticket;

  @override
  void initState() {
    super.initState();
    ticket = widget.ticket;
  }

  void _changeStatus(TicketStatus newStatus) {
    setState(() {
      ticket.changeStatus(newStatus);
    });
    widget.onUpdated();
  }

  void _assignEmployee(String employee) {
    setState(() {
      ticket.assign(employee);
    });
    widget.onUpdated();
  }

  void _changePriority(TicketPriority newPriority) {
    setState(() {
      ticket.changePriority(newPriority);
    });
    widget.onUpdated();
  }

  void _deleteTicket() async {
    final shouldDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ticket?'),
        content: Text('Are you sure you want to delete "${ticket.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ticket #${ticket.id}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              ticket.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Text(ticket.description),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TicketStatus.values.map((status) {
                    return FilterChip(
                      label: Text(status.text),
                      selected: ticket.status == status,
                      onSelected: (_) => _changeStatus(status),
                      backgroundColor: status.color.withOpacity(0.1),
                      selectedColor: status.color.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: ticket.status == status ? status.color : Colors.grey,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned to:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.ticketManager.employees.map((employee) {
                    return FilterChip(
                      label: Text(employee),
                      selected: ticket.assignedTo == employee,
                      onSelected: (_) => _assignEmployee(employee),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Priority:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TicketPriority.values.map((priority) {
                    return FilterChip(
                      label: Text(priority.text),
                      selected: ticket.priority == priority,
                      onSelected: (_) => _changePriority(priority),
                      backgroundColor: priority.color.withOpacity(0.1),
                      selectedColor: priority.color.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: ticket.priority == priority ? priority.color : Colors.grey,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Customer: ${ticket.customer}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Created: ${ticket.formattedTime}'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _deleteTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete Ticket'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}