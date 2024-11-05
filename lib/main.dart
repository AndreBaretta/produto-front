import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:core';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Lista de Produtos'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List produtos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProdutos();
  }

  Future<void> fetchProdutos() async {
    final url = Uri.parse('http://localhost:3000/produto');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          produtos = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Erro ao carregar produtos');
      }
    } catch (error) {
      print('Erro: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToProductForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductFormPage()),
    ).then((_) => fetchProdutos()); // Atualiza a lista ao retornar
  }

  void _navigateToProductDetail(BuildContext context, Map produto) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductDetailPage(produto: produto)),
    ).then((_) => fetchProdutos()); // Atualiza a lista ao retornar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : produtos.isEmpty
              ? const Center(child: Text('Nenhum produto encontrado'))
              : ListView.builder(
                  itemCount: produtos.length,
                  itemBuilder: (context, index) {
                    final produto = produtos[index];
                    return ListTile(
                      title: Text(produto['descricao'] ?? 'Descrição indisponível'),
                      subtitle: Text('Preço: ${produto['preco'] ?? 'N/A'}'),
                      trailing: Text('Estoque: ${produto['estoque'] ?? 'N/A'}'),
                      onTap: () => _navigateToProductDetail(context, produto),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToProductForm(context),
        tooltip: 'Criar Produto',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  final Map produto;

  const ProductDetailPage({super.key, required this.produto});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late TextEditingController descricaoController;
  late TextEditingController precoController;
  late TextEditingController estoqueController;

  @override
  void initState() {
    super.initState();
    descricaoController = TextEditingController(text: widget.produto['descricao']);
    precoController = TextEditingController(text: widget.produto['preco'].toString());
    precoController.text = precoController.text.replaceAll('\$', '');
    estoqueController = TextEditingController(text: widget.produto['estoque'].toString());
  }

  Future<void> _updateProduct() async {
    final url = Uri.parse('http://localhost:3000/produto/${widget.produto['id']}');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'descricao': descricaoController.text,
        'preco': double.parse(precoController.text),
        'estoque': int.parse(estoqueController.text),
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto atualizado com sucesso!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar produto!')),
      );
    }
  }

  Future<void> _deleteProduct() async {
    final url = Uri.parse('http://localhost:3000/produto/${widget.produto['id']}');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto excluído com sucesso!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir produto!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: precoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Preço'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: estoqueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Estoque'),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _updateProduct,
                  child: const Text('Salvar Alterações'),
                ),
                ElevatedButton(
                  onPressed: _deleteProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Excluir Produto'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController precoController = TextEditingController();
  final TextEditingController estoqueController = TextEditingController();
  final TextEditingController dataController = TextEditingController();

  Future<void> _createProduct(String descricao, String preco, String estoque, String data) async {
    final url = Uri.parse('http://localhost:3000/produto');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'descricao': descricao,
        'preco': double.parse(preco),
        'estoque': int.parse(estoque),
        'data': data,
      }),
    );

    if (response.statusCode == 201) {
      print('Produto criado com sucesso!');
    } else {
      print('Erro ao criar produto: ${response.statusCode}');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    
    if (selectedDate != null) {
      final formattedDate = DateFormat('MM/dd/yyyy').format(selectedDate);
      dataController.text = formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: precoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Preço'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: estoqueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Estoque'),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dataController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Data'),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _createProduct(
                    descricaoController.text,
                    precoController.text,
                    estoqueController.text,
                    dataController.text,
                  ).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Produto criado com sucesso!')),
                    );
                    Navigator.pop(context);
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro ao criar produto!')),
                    );
                  });
                },
                child: const Text('Salvar Produto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
