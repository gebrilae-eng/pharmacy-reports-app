import 'package:flutter/material.dart';
import '../models/report_models.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final bool showDispensed;
  final bool showStock;
  final bool showShortage;
  final bool showBalance;
  final bool showExpiry;
  final bool highlightShortage;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.showDispensed = false,
    this.showStock = false,
    this.showShortage = false,
    this.showBalance = false,
    this.showExpiry = false,
    this.highlightShortage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isShortage = highlightShortage && medicine.isShortage;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isShortage ? Colors.red.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isShortage 
            ? BorderSide(color: Colors.red.shade200)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الاسم والتركيز
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (medicine.tradeName.isNotEmpty && 
                          medicine.tradeName != medicine.tradeNameAr)
                        Text(
                          medicine.tradeName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (medicine.strength.isNotEmpty || medicine.form.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      [medicine.strength, medicine.form]
                          .where((s) => s.isNotEmpty)
                          .join(' - '),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            
            // الاسم العلمي
            if (medicine.genericName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  medicine.genericName,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            
            const SizedBox(height: 8),
            
            // المعلومات الإضافية
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                // الرصيد
                if (showStock || showBalance || showShortage)
                  _buildInfoChip(
                    icon: Icons.inventory_2,
                    label: 'الرصيد',
                    value: '${medicine.currentStock}',
                    color: medicine.isShortage ? Colors.red : Colors.blue,
                  ),
                
                // المصروف
                if (showDispensed && medicine.totalDispensed > 0)
                  _buildInfoChip(
                    icon: Icons.shopping_cart,
                    label: 'مصروف',
                    value: '${medicine.totalDispensed}',
                    color: Colors.orange,
                  ),
                
                // الحد الأدنى
                if (showShortage)
                  _buildInfoChip(
                    icon: Icons.low_priority,
                    label: 'الحد الأدنى',
                    value: '${medicine.minStock}',
                    color: Colors.grey,
                  ),
                
                // القيمة
                if (showBalance && medicine.totalValue > 0)
                  _buildInfoChip(
                    icon: Icons.attach_money,
                    label: 'القيمة',
                    value: medicine.totalValue.toStringAsFixed(2),
                    color: Colors.purple,
                  ),
                
                // الباتشات
                if (showBalance && medicine.batches > 0)
                  _buildInfoChip(
                    icon: Icons.layers,
                    label: 'باتشات',
                    value: '${medicine.batches}',
                    color: Colors.teal,
                  ),
                
                // الصلاحية
                if (showExpiry && medicine.nearestExpiry.isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.event,
                    label: 'الصلاحية',
                    value: _formatExpiry(medicine.nearestExpiry),
                    color: medicine.isNearExpiry ? Colors.orange : Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatExpiry(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
