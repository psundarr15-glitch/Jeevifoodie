<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\OrderModel;
use App\Models\RestaurantModel;
use App\Models\MenuItemModel;
use App\Models\UserModel;

class DashboardController extends BaseController
{
    public function index()
    {
        $isManager = session()->get('admin_role') === 'restaurant_manager';
        $myRestaurantId = session()->get('admin_restaurant_id');

        // Each query below uses its OWN fresh model instance — CodeIgniter's
        // query builder does not deep-clone cleanly, so reusing/cloning one
        // configured model across multiple queries silently drops the
        // restaurant_id filter after the first query runs. That bug was
        // exactly why managers were seeing every restaurant's data here.

        $totalOrders = new OrderModel();
        if ($isManager) $totalOrders->where('restaurant_id', $myRestaurantId);

        $totalMenuItems = new MenuItemModel();
        if ($isManager) $totalMenuItems->where('restaurant_id', $myRestaurantId);

        $recentOrders = new OrderModel();
        if ($isManager) $recentOrders->where('restaurant_id', $myRestaurantId);

        $revenue = new OrderModel();
        if ($isManager) $revenue->where('restaurant_id', $myRestaurantId);

        $data = [
            'is_manager'         => $isManager,
            'total_orders'       => $totalOrders->countAllResults(),
            'total_restaurants'  => $isManager ? 1 : (new RestaurantModel())->countAll(),
            'total_menu_items'   => $totalMenuItems->countAllResults(),
            'total_users'        => $isManager ? null : (new UserModel())->countAll(),
            'recent_orders'      => $recentOrders->orderBy('id', 'DESC')->findAll(10),
            'revenue'            => $revenue->selectSum('total')->where('payment_status', 'paid')->first()['total'] ?? 0,
        ];

        return view('admin/dashboard', $data);
    }
}
