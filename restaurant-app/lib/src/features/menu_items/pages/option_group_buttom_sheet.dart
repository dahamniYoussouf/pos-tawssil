// import 'package:flutter/material.dart';

// class _OptionGroupsSection extends StatefulWidget {
//   @override
//   State<_OptionGroupsSection> createState() => _OptionGroupsSectionState();
// }

// class _OptionGroupsSectionState extends State<_OptionGroupsSection> {
//   final List<MenuItemOptionGroup> groups = [];

//   void _openAddGroupModal() async {
//     final result = await showModalBottomSheet<OptionGroupModel>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => const _AddOptionGroupSheet(),
//     );

//     if (result != null) {
//       setState(() => groups.add(result));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Groupes d'options",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         const SizedBox(height: 16),
//         ...groups.map((group) => _OptionGroupCard(group)),
//         const SizedBox(height: 12),
//         OutlinedButton.icon(
//           onPressed: _openAddGroupModal,
//           icon: const Icon(Icons.add),
//           label: Text(l10n.create),
//           style: OutlinedButton.styleFrom(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         )
//       ],
//     );
//   }
// }


// class _AddOptionGroupSheet extends StatefulWidget {
//   const _AddOptionGroupSheet();

//   @override
//   State<_AddOptionGroupSheet> createState() =>
//       _AddOptionGroupSheetState();
// }

// class _AddOptionGroupSheetState
//     extends State<_AddOptionGroupSheet> {
//   final TextEditingController nameController =
//       TextEditingController();

//   bool obligatoire = false;
//   bool choixMultiple = false;

//   final List<OptionModel> options = [];

//   void _addOption() {
//     setState(() {
//       options.add(OptionModel(name: "", price: 0));
//     });
//   }

//   void _submit() {
//     if (nameController.text.isEmpty) return;

//     Navigator.pop(
//       context,
//       OptionGroupModel(
//         name: nameController.text,
//         obligatoire: obligatoire,
//         choixMultiple: choixMultiple,
//         options: options,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);

//     return Container(
//       padding: EdgeInsets.only(
//         left: 20,
//         right: 20,
//         bottom: mediaQuery.viewInsets.bottom + 20,
//         top: 20,
//       ),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Center(
//               child: Text(
//                 "Ajouter Groupe",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 24),

//             _MenuItemTextField(
//               controller: nameController,
//               label: "Nom du groupe *",
//               hint: "Entrer nom du groupe",
//             ),

//             const SizedBox(height: 16),

//             SwitchListTile(
//               value: obligatoire,
//               onChanged: (v) =>
//                   setState(() => obligatoire = v),
//               title: const Text("Obligatoire"),
//             ),

//             SwitchListTile(
//               value: choixMultiple,
//               onChanged: (v) =>
//                   setState(() => choixMultiple = v),
//               title: const Text("Choix Multiple"),
//             ),

//             const SizedBox(height: 16),

//             const Text(
//               "Options",
//               style:
//                   TextStyle(fontWeight: FontWeight.bold),
//             ),

//             const SizedBox(height: 8),

//             ...options.asMap().entries.map((entry) {
//               int index = entry.key;
//               OptionModel option = entry.value;

//               return Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       onChanged: (v) =>
//                           option.name = v,
//                       decoration:
//                           const InputDecoration(
//                         hintText: "Nom de l'option",
//                         filled: true,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   SizedBox(
//                     width: 90,
//                     child: TextFormField(
//                       keyboardType:
//                           TextInputType.number,
//                       onChanged: (v) =>
//                           option.price =
//                               double.tryParse(v) ?? 0,
//                       decoration:
//                           const InputDecoration(
//                         hintText: "0.00",
//                         suffixText: "DA",
//                         filled: true,
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             }),

//             const SizedBox(height: 12),

//             TextButton.icon(
//               onPressed: _addOption,
//               icon: const Icon(Icons.add),
//               label: const Text("Ajouter option"),
//             ),

//             const SizedBox(height: 24),

//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _submit,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       shape: RoundedRectangleBorder(
//                         borderRadius:
//                             BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text("Ajouter"),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () =>
//                         Navigator.pop(context),
//                     child: const Text("Annuler"),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
