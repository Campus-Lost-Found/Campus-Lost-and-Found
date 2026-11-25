import 'package:material_ui/material_ui.dart';


void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SearchPage(),
    ),
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController =
      TextEditingController();

  final List<String> items = [
    'Black Wallet',
    'Student ID Card',
    'iPhone 15',
    'Blue Backpack',
    'AirPods',
    'Water Bottle',
  ];

  String searchKeyword = '';

  List<String> get filteredItems {
    return items.where((item) {
      return item.toLowerCase().contains(
            searchKeyword.toLowerCase(),
          );
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchKeyword = '';
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchKeyword = value;
                });
              },
            ),

            const SizedBox(height: 20),

            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(
                      child: Text('No items found'),
                    )
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.inventory_2),
                            title: Text(filteredItems[index]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
