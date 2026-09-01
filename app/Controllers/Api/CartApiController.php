<?php

namespace App\Controllers\Api;

use App\Models\CartModel;
use App\Models\CartItemModel;
use App\Models\MenuItemModel;

class CartApiController extends BaseApiController
{
    protected function getOrCreateCart($userId, $restaurantId)
    {
        $cartModel = new CartModel();
        $cart = $cartModel->where('user_id', $userId)->first();

        if ($cart && $cart['restaurant_id'] != $restaurantId) {
            (new CartItemModel())->where('cart_id', $cart['id'])->delete();
            $cartModel->update($cart['id'], ['restaurant_id' => $restaurantId]);
            $cart['restaurant_id'] = $restaurantId;
            return $cart;
        }

        if (! $cart) {
            $id = $cartModel->insert(['user_id' => $userId, 'restaurant_id' => $restaurantId]);
            return $cartModel->find($id);
        }

        return $cart;
    }

    protected function summarize(array $items): array
    {
        $count = 0;
        $subtotal = 0;
        foreach ($items as $it) {
            $count += $it['quantity'];
            $subtotal += $it['price'] * $it['quantity'];
        }
        return ['cart_count' => $count, 'cart_subtotal' => $subtotal];
    }

    public function view()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        $cartModel = new CartModel();
        $cartItemModel = new CartItemModel();
        $cart = $cartModel->where('user_id', $user['id'])->first();

        if (! $cart) {
            return $this->ok(['items' => [], 'cart_count' => 0, 'cart_subtotal' => 0]);
        }

        $items = $cartItemModel->itemsWithDetails($cart['id']);
        return $this->ok(array_merge(['items' => $items], $this->summarize($items)));
    }

    public function add()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        $menuItemId = $this->request->getPost('menu_item_id');
        $qty = (int) ($this->request->getPost('quantity') ?? 1);

        $menuItem = (new MenuItemModel())->find($menuItemId);
        if (! $menuItem) {
            return $this->fail('Item not found.', 404);
        }
        if (! $menuItem['is_available']) {
            return $this->fail('This item is currently out of stock.');
        }

        $cart = $this->getOrCreateCart($user['id'], $menuItem['restaurant_id']);
        $cartItemModel = new CartItemModel();
        $existing = $cartItemModel->where('cart_id', $cart['id'])->where('menu_item_id', $menuItemId)->first();

        if ($existing) {
            $cartItemModel->update($existing['id'], ['quantity' => $existing['quantity'] + $qty]);
        } else {
            $cartItemModel->insert([
                'cart_id'      => $cart['id'],
                'menu_item_id' => $menuItemId,
                'quantity'     => $qty,
                'price'        => $menuItem['price'],
            ]);
        }

        $items = $cartItemModel->where('cart_id', $cart['id'])->findAll();
        return $this->ok($this->summarize($items));
    }

    public function update()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        $itemId = $this->request->getPost('cart_item_id');
        $qty = (int) $this->request->getPost('quantity');
        $cartItemModel = new CartItemModel();

        $item = $cartItemModel->find($itemId);
        if (! $item) {
            return $this->fail('Item not found.', 404);
        }

        $removed = false;
        if ($qty <= 0) {
            $cartItemModel->delete($itemId);
            $removed = true;
        } else {
            $menuItem = (new MenuItemModel())->find($item['menu_item_id']);
            if (! $menuItem || ! $menuItem['is_available']) {
                return $this->fail('This item is currently out of stock.');
            }
            $cartItemModel->update($itemId, ['quantity' => $qty]);
        }

        $remaining = $cartItemModel->where('cart_id', $item['cart_id'])->findAll();

        return $this->ok(array_merge([
            'removed'      => $removed,
            'new_quantity' => $qty > 0 ? $qty : 0,
            'item_total'   => $qty > 0 ? $item['price'] * $qty : 0,
        ], $this->summarize($remaining)));
    }
}
