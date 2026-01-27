// import 'package:flutter/material.dart';
// import 'package:client_app/src/core/res/color_app.dart';
// import 'package:client_app/src/features/order/models/order_model.dart';

// class RestaurantInfoCard extends StatelessWidget {
//   final OrderModel order;

//   const RestaurantInfoCard({super.key, required this.order});

//   @override
//   Widget build(BuildContext context) {
//     final String title = (order.restaurantName != null && order.restaurantName!.trim().isNotEmpty) ? order.restaurantName!.trim() : 'Restaurant';
//     final String subtitle = (order.restaurantAddress != null && order.restaurantAddress!.trim().isNotEmpty) ? order.restaurantAddress!.trim() : '---';

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: ColorApp.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: ColorApp.black.withValues(alpha: 0.4),
//             blurRadius: 14,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           _RestaurantThumbnail(imageUrl: order.restaurantImageUrl, nameFallback: title),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     const Icon(
//                       Icons.location_on_outlined,
//                       color: ColorApp.grey,
//                       size: 18,
//                     ),
//                     const SizedBox(width: 4),
//                     Expanded(
//                       child: Text(
//                         subtitle,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           color: ColorApp.grey,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _RestaurantThumbnail extends StatelessWidget {
//   final String? imageUrl;
//   final String nameFallback;

//   const _RestaurantThumbnail({
//     required this.imageUrl,
//     required this.nameFallback,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         width: 72,
//         height: 72,
//         decoration: BoxDecoration(
//           color: const Color(0xFFF3F4F6),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: _buildImage(),
//       ),
//     );
//   }

//   Widget _buildImage() {
//     if (imageUrl == null || imageUrl!.isEmpty) {
//       return _Fallback(initial: nameFallback.isNotEmpty ? nameFallback[0].toUpperCase() : 'R');
//     }
//     return Image.network(
//       imageUrl!,
//       fit: BoxFit.cover,
//       errorBuilder: (_, __, ___) => _Fallback(initial: nameFallback.isNotEmpty ? nameFallback[0].toUpperCase() : 'R'),
//       loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
//         if (loadingProgress == null) {
//           return child;
//         }
//         return const Center(
//           child: SizedBox(
//             width: 20,
//             height: 20,
//             child: CircularProgressIndicator(strokeWidth: 2),
//           ),
//         );
//       },
//     );
//   }
// }

// class _Fallback extends StatelessWidget {
//   final String initial;

//   const _Fallback({required this.initial});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: const Color(0xFF00695C).withValues(alpha: 0.12),
//       alignment: Alignment.center,
//       child: Text(
//         initial,
//         style: const TextStyle(
//           fontSize: 28,
//           fontWeight: FontWeight.w600,
//           color: Color(0xFF00695C),
//         ),
//       ),
//     );
//   }
// }
