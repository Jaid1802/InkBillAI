import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/products/domain/entities/product.dart';
import 'package:inkbill_ai/features/products/presentation/providers/product_provider.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductDialog(context),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) => products.isEmpty
            ? const Center(child: Text('No products yet'))
            : ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) =>
                    _ProductCard(product: products[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Something went wrong. Please try again.')),
      ),
    );
  }

  void _showProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _ProductFormDialog(),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
            style: TextStyle(color: Colors.green.shade700),
          ),
        ),
        title: Text(product.name),
        subtitle: Text(product.description ?? product.hsnCode ?? ''),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Stock: ${product.stock}',
                style: TextStyle(
                  fontSize: 12,
                  color: product.stock < 5 ? Colors.red : Colors.grey,
                )),
          ],
        ),
      ),
    );
  }
}

class _ProductFormDialog extends ConsumerStatefulWidget {
  const _ProductFormDialog();

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _gstCtrl.dispose();
    _hsnCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Product'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Price *'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _gstCtrl,
                decoration: const InputDecoration(labelText: 'GST Rate (%)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _hsnCtrl,
                decoration: const InputDecoration(labelText: 'HSN Code'),
              ),
              TextFormField(
                controller: _stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
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
          onPressed: _saveProduct,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(productRepositoryProvider);
    repo.createProduct(Product(
      id: 'prod_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text,
      description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      gstRate: double.tryParse(_gstCtrl.text),
      hsnCode: _hsnCtrl.text.isEmpty ? null : _hsnCtrl.text,
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    Navigator.pop(context);
    ref.invalidate(allProductsProvider);
  }
}
