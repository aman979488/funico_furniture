import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funica/core/utils/formatters.dart';
import 'package:funica/features/cart/repositories/cart_repository.dart';
import 'package:funica/features/cart/viewmodels/cart_viewmodel.dart';
import 'package:funica/features/cart/views/cart_screen.dart';
import 'package:funica/features/product/views/product_detail_screen.dart';
import 'package:funica/shared/models/product.dart';

void main() {
  test('formats amounts as Indian rupees', () {
    expect(CurrencyFormatter.inRupees(399), '₹399');
    expect(CurrencyFormatter.inRupees(18500), '₹18,500');
    expect(CurrencyFormatter.inRupees(1234567), '₹12,34,567');
  });

  test('keeps catalog product prices above the minimum', () {
    expect(
      [
        ...Product.sofaOptions,
        ...Product.sampleProducts,
      ].every((product) => product.price >= Product.minimumPrice),
      isTrue,
    );

    final firestoreProduct = Product.fromMap({
      'id': 'mapped-product',
      'price': 500,
    });
    expect(firestoreProduct.price, Product.minimumPrice);
  });

  group('CartRepository and CartViewModel', () {
    test('adds items and calculates total price correctly', () async {
      final repository = CartRepositoryImpl();
      final container = ProviderContainer(
        overrides: [cartRepositoryProvider.overrideWithValue(repository)],
      );

      final viewModel = container.read(cartViewModelProvider.notifier);
      final product = Product.sampleProducts.first;

      // Initial state
      expect(container.read(cartViewModelProvider).items, isEmpty);
      expect(container.read(cartViewModelProvider).codes, hasLength(3));
      expect(container.read(cartViewModelProvider).total, 0.0);

      // Add to cart with quantity 2
      viewModel.addToCart(product, quantity: 2, selectedColor: 0xFFA0624A);
      var state = container.read(cartViewModelProvider);
      expect(state.items.length, 1);
      expect(state.items.first.quantity, 2);
      expect(state.items.first.totalPrice, product.price * 2);
      expect(state.total, product.price * 2);
      expect(viewModel.isInCart(product.id), isTrue);

      // Add same product and color again -> quantity increments
      viewModel.addToCart(product, quantity: 1, selectedColor: 0xFFA0624A);
      state = container.read(cartViewModelProvider);
      expect(state.items.length, 1);
      expect(state.items.first.quantity, 3);
      expect(state.total, product.price * 3);

      // Update quantity
      viewModel.updateQuantity(state.items.first.id, 5);
      state = container.read(cartViewModelProvider);
      expect(state.items.first.quantity, 5);

      // Remove from cart
      viewModel.removeFromCart(state.items.first.id);
      state = container.read(cartViewModelProvider);
      expect(state.items, isEmpty);
      expect(state.total, 0.0);
    });

    test(
      'keeps products in separate codes and supports creating more codes',
      () {
        final repository = CartRepositoryImpl();
        final container = ProviderContainer(
          overrides: [cartRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);
        final viewModel = container.read(cartViewModelProvider.notifier);
        final product = Product.sampleProducts.first;

        viewModel.addToCart(product, quantity: 2);
        viewModel.selectCode('code_2');
        viewModel.addToCart(product, quantity: 1);
        viewModel.selectCode('code_1');

        var state = container.read(cartViewModelProvider);
        expect(state.items, hasLength(2));
        expect(state.selectedCodeItems.single.quantity, 2);
        expect(state.subtotal, product.price * 2);

        final customCode = viewModel.createCode('Bedroom');
        expect(customCode.name, 'Bedroom');
        expect(container.read(cartViewModelProvider).codes, hasLength(4));
        viewModel.addToCart(product, codeId: customCode.id);
        state = container.read(cartViewModelProvider);
        expect(state.selectedCodeId, customCode.id);
        expect(state.selectedCodeItems.single.codeId, customCode.id);
        expect(state.selectedCodeItems.single.quantity, 1);
      },
    );
  });

  group('ProductDetailScreen Add to Cart UI', () {
    testWidgets(
      'renders ProductDetailScreen with Add to Cart and adjusts quantity',
      (tester) async {
        final product = Product.sampleProducts.first;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(home: ProductDetailScreen(product: product)),
          ),
        );
        await tester.pumpAndSettle();

        // Verify product name and Add to Cart button are present
        expect(find.text(product.name), findsOneWidget);
        expect(find.text('Add to Cart'), findsOneWidget);
        expect(find.text('Total price'), findsOneWidget);
        expect(find.text('Quantity'), findsOneWidget);
        expect(find.text('Color'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
        expect(find.text('₹1,600'), findsWidgets);

        // Initial quantity is 1
        expect(find.text('1'), findsOneWidget);

        // Scroll to '+' button to ensure visible and tap
        await tester.ensureVisible(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(find.text('2'), findsOneWidget);

        // Tap 'Add to Cart' (in bottomNavigationBar)
        await tester.tap(find.text('Add to Cart'));
        await tester.pumpAndSettle();

        // No View Cart SnackBar popup appears
        expect(find.text('View Cart'), findsNothing);
      },
    );

    testWidgets('CartScreen shows items and empty state', (tester) async {
      final container = ProviderContainer();
      final product = Product.sampleProducts.first;

      // Initially empty
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Cart is Empty'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);

      // Add item to cart
      container
          .read(cartViewModelProvider.notifier)
          .addToCart(product, quantity: 2);
      await tester.pumpAndSettle();

      // CartScreen shows the item, summary, and purchase action.
      expect(find.text('Your Cart is Empty'), findsNothing);
      expect(find.text(product.name), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Dynamic Cost (Delivery & Fitting)'), findsOneWidget);
      expect(find.text('Promo Discount'), findsOneWidget);
      expect(find.text('Total Amount'), findsOneWidget);
      expect(find.text('10% Add code'), findsOneWidget);
      expect(find.text('₹3,200'), findsOneWidget);
      expect(find.text('₹4,080'), findsOneWidget);
    });
  });
}
