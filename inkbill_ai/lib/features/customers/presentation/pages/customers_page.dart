import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/customers/domain/entities/customer.dart';
import 'package:inkbill_ai/features/customers/presentation/providers/customer_provider.dart';

class CustomersPage extends ConsumerWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(allCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCustomerDialog(context),
          ),
        ],
      ),
      body: customersAsync.when(
        data: (customers) => customers.isEmpty
            ? const Center(child: Text('No customers yet'))
            : ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) =>
                    _CustomerCard(customer: customers[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Something went wrong. Please try again.')),
      ),
    );
  }

  void _showCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _CustomerFormDialog(),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: TextStyle(color: Colors.blue.shade700),
          ),
        ),
        title: Text(customer.name),
        subtitle: Text(customer.phone ?? customer.email ?? ''),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${customer.totalPurchases.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (customer.balance > 0)
              Text('Due: ₹${customer.balance.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _CustomerFormDialog extends ConsumerStatefulWidget {
  const _CustomerFormDialog();

  @override
  ConsumerState<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends ConsumerState<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Customer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
                maxLength: 100,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                maxLength: 20,
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                maxLength: 254,
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _gstinCtrl,
                decoration: const InputDecoration(labelText: 'GSTIN'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveCustomer,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveCustomer() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(customerRepositoryProvider);
    repo.createCustomer(Customer(
      id: 'cust_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text,
      phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
      email: _emailCtrl.text.isEmpty ? null : _emailCtrl.text,
      address: _addressCtrl.text.isEmpty ? null : _addressCtrl.text,
      gstin: _gstinCtrl.text.isEmpty ? null : _gstinCtrl.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    Navigator.pop(context);
    ref.invalidate(allCustomersProvider);
  }
}
