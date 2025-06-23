// lib/admin_panel/pages/admin_manage_users_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toast/toast.dart';
import '../../../database/collections/users_collections.dart';
import '../../../models/user_model.dart'; // Включая UserRoles
import 'admin_auth_service.dart'; // Для проверки статуса админа, если используем коллекцию admins
import '../routing/app_router.dart'; // Для AdminRoutes

class AdminManageUsersPage extends StatefulWidget {
  const AdminManageUsersPage({Key? key}) : super(key: key);

  @override
  State<AdminManageUsersPage> createState() => _AdminManageUsersPageState();
}

class _AdminManageUsersPageState extends State<AdminManageUsersPage> {
  final UsersCollection _usersCollection = UsersCollection();
  final AdminAuthService _adminAuthService = AdminAuthService(); // Если используете отдельную коллекцию 'admins'

  List<UserModel> _users = [];
  Map<String, bool> _adminStatusCache = {}; // Для кэширования статуса админа, если он проверяется отдельно
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";

  @override
  void initState() {
    super.initState();
    ToastContext().init(context);
    _fetchUsersAndAdminStatus(); // Используем метод, который также получает статус админа
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsersAndAdminStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _adminStatusCache = {}; // Сбрасываем кэш
    });
    try {
      final users = await _usersCollection.getAllUsers();
      if (mounted) {
        // Если статус админа определяется отдельной коллекцией 'admins'
        for (var user in users) {
          _adminStatusCache[user.uid] = await _adminAuthService.isUidAdmin(user.uid);
        }
        // Если статус админа определяется полем user.role == UserRoles.admin, то этот цикл не нужен
        // и _adminStatusCache не используется.

        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Ошибка загрузки пользователей: $e";
          _isLoading = false;
        });
      }
    }
  }

  // Метод для обновления роли пользователя.
  // Адаптирован для работы с вашей текущей логикой (поле 'role' в UserModel)
  // и опционально с коллекцией 'admins'
  Future<void> _updateUserRoleAndAdminStatus(UserModel user, String newRoleInDocument) async {
    final currentAuthUser = _adminAuthService.currentUser;
    bool isCurrentUserThisUser = currentAuthUser?.uid == user.uid;

    // --- Логика защиты для системы с коллекцией 'admins' ---
    // bool isUserCurrentlyDeFactoAdmin = _adminStatusCache[user.uid] ?? false;
    // bool newRoleImpliesAdmin = newRoleInDocument == UserRoles.admin;
    // int deFactoAdminCount = _adminStatusCache.values.where((isAdm) => isAdm).length;

    // if (!newRoleImpliesAdmin && isUserCurrentlyDeFactoAdmin && deFactoAdminCount <= 1) {
    //   Toast.show("Нельзя отозвать права единственного администратора.", duration: Toast.lengthLong);
    //   return;
    // }
    // --- Конец логики для системы с коллекцией 'admins' ---

    // --- Логика защиты для системы с полем 'role' в UserModel ---
    if (user.role == UserRoles.admin && newRoleInDocument != UserRoles.admin) {
      final adminCountInDocuments = _users.where((u) => u.role == UserRoles.admin).length;
      if (adminCountInDocuments <= 1 && isCurrentUserThisUser) {
         Toast.show("Нельзя понизить роль единственного администратора (самого себя).", duration: Toast.lengthLong, gravity: Toast.bottom);
         return;
      }
       if (adminCountInDocuments <= 1 && !isCurrentUserThisUser) {
         Toast.show("Нельзя понизить роль единственного администратора.", duration: Toast.lengthLong, gravity: Toast.bottom);
         return;
      }
    }
    // --- Конец логики для системы с полем 'role' в UserModel ---


    setState(() => _isLoading = true);
    try {
      // 1. Обновляем поле 'role' в документе пользователя
      await _usersCollection.updateUserRole(user.uid, newRoleInDocument);

      // 2. Если вы используете отдельную коллекцию 'admins', обновите ее здесь:
      // if (newRoleImpliesAdmin && !isUserCurrentlyDeFactoAdmin) {
      //   await _adminAuthService.grantAdminRole(user.uid);
      // } else if (!newRoleImpliesAdmin && isUserCurrentlyDeFactoAdmin) {
      //   await _adminAuthService.revokeAdminRole(user.uid);
      // }
      
      Toast.show("Роль пользователя ${user.email} обновлена.", duration: Toast.lengthShort);
      await _fetchUsersAndAdminStatus(); // Обновить список и статусы
    } catch (e) {
      Toast.show("Ошибка обновления роли: $e", duration: Toast.lengthLong);
      // Если произошла ошибка, возможно, стоит откатить изменения, если они были частичными
      // или просто перезагрузить данные, чтобы пользователь видел актуальное состояние.
      if (mounted) {
         await _fetchUsersAndAdminStatus(); // Перезагрузить в любом случае
         // setState(() => _isLoading = false); // _fetchUsersAndAdminStatus уже это сделает
      }
    } finally {
        if(mounted && _isLoading) setState(() => _isLoading = false); // Убедимся, что индикатор скрыт
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    // --- Логика защиты для системы с коллекцией 'admins' ---
    // bool isUserCurrentlyDeFactoAdmin = _adminStatusCache[user.uid] ?? false;
    // if (isUserCurrentlyDeFactoAdmin) {
    //   final deFactoAdminCount = _adminStatusCache.values.where((isAdm) => isAdm).length;
    //   if (deFactoAdminCount <= 1) {
    //     Toast.show("Нельзя удалить единственного администратора.", duration: Toast.lengthLong);
    //     return;
    //   }
    // }
    // --- Конец логики для системы с коллекцией 'admins' ---

    // --- Логика защиты для системы с полем 'role' в UserModel ---
    if (user.role == UserRoles.admin) {
      final adminCountInDocuments = _users.where((u) => u.role == UserRoles.admin).length;
      if (adminCountInDocuments <= 1) {
        Toast.show("Нельзя удалить единственного администратора.", duration: Toast.lengthLong, gravity: Toast.bottom);
        return;
      }
    }
    // --- Конец логики для системы с полем 'role' в UserModel ---

    bool confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Удалить пользователя?"),
        content: Text(
            "Вы уверены, что хотите удалить данные пользователя ${user.email} (UID: ${user.uid}) из базы данных Firestore?\n\nУчетная запись для входа (Firebase Auth) останется активной."),
        actions: <Widget>[
          TextButton(
            child: const Text("Отмена"),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Удалить данные из Firestore"),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    ) ?? false;

    if (confirmDelete) {
      setState(() => _isLoading = true);
      try {
        // Если используете коллекцию 'admins', удалите оттуда тоже
        // if (isUserCurrentlyDeFactoAdmin) {
        //   await _adminAuthService.revokeAdminRole(user.uid);
        // }
        await _usersCollection.deleteUserDocument(user.uid);
        Toast.show("Данные пользователя ${user.email} удалены из Firestore.", duration: Toast.lengthShort);
        await _fetchUsersAndAdminStatus();
      } catch (e) {
        Toast.show("Ошибка удаления данных пользователя: $e", duration: Toast.lengthLong);
        if (mounted) {
            await _fetchUsersAndAdminStatus(); // Перезагрузить в любом случае
            // setState(() => _isLoading = false);
        }
      } finally {
          if(mounted && _isLoading) setState(() => _isLoading = false);
      }
    }
  }

  List<UserModel> get _filteredUsers {
    if (_searchTerm.isEmpty) {
      return _users;
    }
    return _users.where((user) {
      return user.email.toLowerCase().contains(_searchTerm) ||
             (user.firstName.toLowerCase().contains(_searchTerm)) ||
             (user.lastName.toLowerCase().contains(_searchTerm)) ||
             user.uid.toLowerCase().contains(_searchTerm);
    }).toList();
  }

  Widget _buildUserActions(UserModel user, BoxConstraints constraints) {
    // Определяем, достаточно ли ширины для отображения в одну строку
    bool useRow = constraints.maxWidth > 350; // Пороговое значение ширины, подберите экспериментально

    List<Widget> actionItems = [
      SizedBox(
        width: useRow ? 170 : double.infinity, // Ширина для Dropdown
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: "Роль",
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
            isDense: true,
          ),
          value: user.role, // Управляем полем user.role
          items: UserRoles.allRoles.map((roleValue) {
            return DropdownMenuItem<String>(
              value: roleValue,
              child: Text(UserRoles.displayRole(roleValue)),
            );
          }).toList(),
          onChanged: (String? newRoleInDocument) {
            if (newRoleInDocument != null && newRoleInDocument != user.role) {
              _updateUserRoleAndAdminStatus(user, newRoleInDocument);
            }
          },
        ),
      ),
      if (useRow) const SizedBox(width: 8),
      if (!useRow) const SizedBox(height: 8), // Отступ, если элементы в столбец
      ElevatedButton.icon(
        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
        label: Text("Удалить", style: TextStyle(color: Theme.of(context).colorScheme.error)),
        style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
            // minimumSize: useRow ? Size.zero : const Size(double.infinity, 36), // Растянуть если в столбец
        ),
        onPressed: () => _deleteUser(user),
      ),
    ];

    if (useRow) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: actionItems,
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch, // Растянуть кнопки в столбец
        children: actionItems,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final usersToDisplay = _filteredUsers;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text("Управление пользователями", style: Theme.of(context).textTheme.headlineSmall, overflow: TextOverflow.ellipsis)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Обновить"),
                  onPressed: _isLoading ? null : _fetchUsersAndAdminStatus,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Поиск (email, имя, UID)",
                hintText: "Введите для поиска...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        // setState(() {}); // Необязательно, так как listener уже есть
                      },
                    )
                  : null,
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                )
              ))
            else if (usersToDisplay.isEmpty)
              Expanded(child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_searchTerm.isNotEmpty ? "Пользователи не найдены по вашему запросу." : "Пользователи отсутствуют.", textAlign: TextAlign.center),
                )
              ))
            else
              Expanded(
                child: LayoutBuilder( // Используем LayoutBuilder для получения ограничений родителя
                  builder: (context, constraints) {
                    return ListView.separated(
                      itemCount: usersToDisplay.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = usersToDisplay[index];
                        // bool isDeFactoAdmin = _adminStatusCache[user.uid] ?? false; // Если используете коллекцию 'admins'

                        String userDisplayName = ('${user.firstName} ${user.lastName}').trim();
                        if (userDisplayName.isEmpty) userDisplayName = user.email;
                        
                        String roleDisplayText = UserRoles.displayRole(user.role);
                        // if (isDeFactoAdmin) { // Если статус админа определяется отдельно
                        //   roleDisplayText = "Администратор (де-факто)";
                        // }


                        return Card(
                          elevation: 1.5,
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      // backgroundColor: isDeFactoAdmin ? Colors.amber.shade100 : Theme.of(context).primaryColorLight,
                                      backgroundColor: user.role == UserRoles.admin ? Colors.amber.shade100 : Theme.of(context).colorScheme.primaryContainer,
                                      child: Text(
                                        user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : (user.email.isNotEmpty ? user.email[0].toUpperCase() : "?"),
                                        // style: TextStyle(color: isDeFactoAdmin ? Colors.amber.shade900 : Theme.of(context).primaryColorDark),
                                         style: TextStyle(color: user.role == UserRoles.admin ? Colors.amber.shade900 : Theme.of(context).colorScheme.onPrimaryContainer),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(userDisplayName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                          Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                                          Text("UID: ${user.uid}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Используем LayoutBuilder внутри элемента списка для адаптивных действий
                                LayoutBuilder(
                                  builder: (BuildContext context, BoxConstraints itemConstraints) {
                                    return _buildUserActions(user, itemConstraints);
                                  }
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Убедитесь, что AdminRoutes.addUser существует и маршрут определен
          try {
            context.go(AdminRoutes.addUser);
          } catch (e) {
            print("Ошибка навигации на AdminRoutes.addUser: $e");
            Toast.show("Не удалось открыть страницу добавления пользователя.", duration: Toast.lengthLong);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Добавить пользователя"),
      ),
    );
  }
}