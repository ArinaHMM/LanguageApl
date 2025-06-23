import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/models/app_data.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final Color primaryOrange = const Color(0xFFF57C00);

    // Если по какой-то причине нет пользователя, показываем заглушку
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Инвентарь'), backgroundColor: primaryOrange),
        body: const Center(child: Text("Пожалуйста, войдите, чтобы увидеть инвентарь.")),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Инвентарь'),
        backgroundColor: primaryOrange,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFFF3E0),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryOrange));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Ошибка загрузки инвентаря."));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Не удалось найти данные пользователя."));
          }

          final user = UserModel.fromFirestore(snapshot.data!);
          final inventoryItems = user.inventory;

          if (inventoryItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.backpack_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Ваш инвентарь пуст", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: inventoryItems.length,
            itemBuilder: (context, index) {
              final item = inventoryItems[index];
              return _InventoryItemCard(
                key: ValueKey(item.id), // Уникальный ключ для виджета
                item: item,
                iconData: AppData.itemIcons[item.icon] ?? AppData.itemIcons['default_icon']!,
              );
            },
          );
        },
      ),
    );
  }
}

// Виджет для карточки предмета теперь StatefulWidget
class _InventoryItemCard extends StatefulWidget {
  final InventoryItem item;
  final IconData iconData;

  const _InventoryItemCard({
    Key? key,
    required this.item,
    required this.iconData,
  }) : super(key: key);

  @override
  __InventoryItemCardState createState() => __InventoryItemCardState();
}

class __InventoryItemCardState extends State<_InventoryItemCard> {
  bool _isActivating = false;

  // Метод активации зелья двойного опыта
  Future<void> _activateDoubleXp(BuildContext dialogContext) async {
    if (widget.item.id != 'double_xp_potion_15min') return;

    // Используем `mounted` для безопасного вызова setState
    if (mounted) {
      setState(() => _isActivating = true);
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final usersCollection = UsersCollection();

    try {
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));
      
      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      batch.update(userRef, {'doubleXpBuffExpiresAt': Timestamp.fromDate(expiresAt)});
      batch.update(userRef, {'inventory.${widget.item.id}.quantity': FieldValue.increment(-1)});

      await batch.commit();
      
      final updatedUserModel = await usersCollection.getUserModel(uid);
      final itemInInventory = updatedUserModel?.inventory.firstWhere((i) => i.id == widget.item.id, orElse: () => InventoryItem(id: '', quantity: -1, name: '', description: '', icon: ''));
      
      if (itemInInventory != null && itemInInventory.quantity <= 0) {
        await usersCollection.updateUserCollection(uid, {
          'inventory.${widget.item.id}': FieldValue.delete(),
        });
      }

      // Проверяем, примонтирован ли виджет, ПЕРЕД тем как работать с контекстом
      if (!mounted) return;
      Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Зелье двойного опыта активировано на 15 минут!"), backgroundColor: Colors.green),
      );

    } catch (e) {
      print("Ошибка активации зелья: $e");
      // Проверяем, примонтирован ли виджет, ПЕРЕД тем как работать с контекстом
      if (!mounted) return;
      Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Не удалось активировать предмет."), backgroundColor: Colors.red),
      );
    } finally {
      // Финальная проверка на mounted перед последним setState
      if (mounted) {
        setState(() => _isActivating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Определяем, можно ли использовать предмет
    final bool isUsable = widget.item.id == 'double_xp_potion_15min';

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Row(
                children: [
                  Icon(widget.iconData, color: Colors.orange.shade800),
                  const SizedBox(width: 10),
                  Text(widget.item.name),
                ],
              ),
              content: Text(widget.item.description),
              actions: [
                // Показываем кнопку "Активировать" только для используемых предметов
                if (isUsable)
                  StatefulBuilder(
                    builder: (context, setDialogState) {
                      return _isActivating
                          ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () => _activateDoubleXp(dialogContext),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text("Активировать"),
                            );
                    }
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Закрыть", style: TextStyle(color: Colors.orange)),
                )
              ],
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade200, Colors.amber.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(widget.iconData, size: 60, color: Colors.orange.shade800),
                    const SizedBox(height: 12),
                    Text(
                      widget.item.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3A3A3A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(1, 1))
                      ]),
                  child: Text(
                    "x${widget.item.quantity}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}