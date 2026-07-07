import 'package:flutter/material.dart';
import '../features/market/cart.dart';
import '../routes/app_routes.dart';

class CommonAppBarActions {
  static List<Widget> actions(BuildContext context) => [const CartActionButton()];
}

class CartActionButton extends StatelessWidget {
  const CartActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Cart.instance,
      builder: (context, _) {
         final count = Cart.instance.distinctItemCount;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.marketCart),
              ),
              if (count > 0)
                Positioned(
                  right: 4,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.15),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}