import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/l10n/app_localizations.dart';

class MyHomeInventoryScreen extends StatefulWidget {
  const MyHomeInventoryScreen({super.key});

  @override
  State<MyHomeInventoryScreen> createState() => _MyHomeInventoryScreenState();
}

class _MyHomeInventoryScreenState extends State<MyHomeInventoryScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();
  String _selectedRoom = 'All';
  
  // Mock Data for Inventory (In real app, this would be a subcollection 'inventory' in user doc)
  // Or filtered estimates by room
  final List<String> _rooms = ['All', 'Kitchen', 'Living Room', 'Bathroom', 'Bedroom', 'Garage', 'Exterior'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Home Inventory', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Room Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _rooms.length,
              itemBuilder: (context, index) {
                final room = _rooms[index];
                final isSelected = room == _selectedRoom;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(room),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedRoom = room),
                    backgroundColor: Theme.of(context).cardColor,
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? AppTheme.primary : Theme.of(context).hintColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), 
                      side: BorderSide(color: isSelected ? AppTheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.1))
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Reusing estimate history for now, but in future would be dedicated inventory collection
              stream: _db.getEstimateHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allItems = snapshot.data ?? [];
                
                final filteredItems = allItems.where((item) {
                  if (_selectedRoom == 'All') return true;
                  final location = (item['location'] as String?) ?? '';
                  // Case-insensitive check if location contains room name
                  return location.toLowerCase().contains(_selectedRoom.toLowerCase());
                }).toList();

                if (filteredItems.isEmpty) {
                   return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200, 
                    childAspectRatio: 0.85, // Taller but smaller width generally due to count
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildInventoryCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           // Navigate to Scan/Add Item (Could reuse main scan flow)
           Navigator.pop(context); // Go back to home to scan
        },
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add Item'),
        backgroundColor: AppTheme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: (item['imageUrl'] != null) ? DecorationImage(
                      image: NetworkImage(item['imageUrl']),
                      fit: BoxFit.cover,
                    ) : null,
                  ),
                  child: (item['imageUrl'] == null) 
                      ? Center(child: Icon(Icons.inventory_2_outlined, size: 32, color: Theme.of(context).hintColor.withValues(alpha: 0.2))) 
                      : null,
                ),
                // Gradient Overlay
                if (item['imageUrl'] != null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Info
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['item_summary'] ?? '',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (item['location'] != null && (item['location'] as String).isNotEmpty)
                        Text(
                          item['location'],
                          style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).hintColor, fontWeight: FontWeight.w500),
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                    ],
                  ),
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (item['repair_or_build'] == 'Build' ? AppTheme.success : AppTheme.accent).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                       item['repair_or_build'] == 'Build' ? 'INSTALLED' : 'REPAIRED',
                       style: GoogleFonts.inter(
                         fontSize: 9, 
                         color: item['repair_or_build'] == 'Build' ? AppTheme.success : AppTheme.accent, 
                         fontWeight: FontWeight.w800,
                         letterSpacing: 0.5
                       )
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_work_outlined, size: 64, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text('Your inventory is empty', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
          const SizedBox(height: 8),
          Text('Scan items to build your digital home profile.', style: GoogleFonts.inter(color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}
