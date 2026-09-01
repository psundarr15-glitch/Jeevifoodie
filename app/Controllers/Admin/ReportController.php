<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\OrderModel;
use App\Models\RestaurantModel;

class ReportController extends BaseController
{
    protected function isManager(): bool
    {
        return session()->get('admin_role') === 'restaurant_manager';
    }

    protected function myRestaurantId()
    {
        return session()->get('admin_restaurant_id');
    }

    public function index()
    {
        $isManager = $this->isManager();

        // Default window: last 30 days including today. Dates come in as
        // plain Y-m-d from the filter form; validate/fallback rather than
        // trusting them outright so a malformed query string can't blow up
        // the date range queries below.
        $dateFrom = $this->request->getGet('date_from');
        $dateTo   = $this->request->getGet('date_to');
        if (! $dateFrom || ! preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateFrom)) {
            $dateFrom = date('Y-m-d', strtotime('-29 days'));
        }
        if (! $dateTo || ! preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateTo)) {
            $dateTo = date('Y-m-d');
        }
        // Order flipped dates back the right way round instead of erroring.
        if ($dateFrom > $dateTo) {
            [$dateFrom, $dateTo] = [$dateTo, $dateFrom];
        }
        $rangeStart = $dateFrom . ' 00:00:00';
        $rangeEnd   = $dateTo . ' 23:59:59';

        // A manager only ever sees their own restaurant; admin can optionally
        // narrow to one via the dropdown, or leave it as "All restaurants".
        $restaurantId = $isManager ? $this->myRestaurantId() : $this->request->getGet('restaurant_id');

        $scoped = function () use ($rangeStart, $rangeEnd, $restaurantId) {
            $m = (new OrderModel())->where('placed_at >=', $rangeStart)->where('placed_at <=', $rangeEnd);
            if ($restaurantId) {
                $m->where('restaurant_id', $restaurantId);
            }
            return $m;
        };

        $totalOrders = $scoped()->countAllResults();

        $paidTotals = $scoped()
            ->selectSum('total', 'revenue')
            ->selectSum('discount', 'total_discount')
            ->where('payment_status', 'paid')
            ->first();
        $revenue = (float) ($paidTotals['revenue'] ?? 0);
        $totalDiscount = (float) ($paidTotals['total_discount'] ?? 0);
        $paidOrders = $scoped()->where('payment_status', 'paid')->countAllResults();
        $avgOrderValue = $paidOrders > 0 ? round($revenue / $paidOrders, 2) : 0;

        $statusBreakdown = $scoped()
            ->select('order_status, COUNT(*) as count')
            ->groupBy('order_status')
            ->findAll();

        $dailySales = $scoped()
            ->select('DATE(placed_at) as day, COUNT(*) as orders, SUM(CASE WHEN payment_status = "paid" THEN total ELSE 0 END) as revenue')
            ->groupBy('DATE(placed_at)')
            ->orderBy('day', 'ASC')
            ->findAll();
        $maxDailyRevenue = max(array_column($dailySales, 'revenue') ?: [0]);

        // Top-selling items: order_items only stores a name/price snapshot
        // (no menu_item_id), which is correct for historical accuracy, but
        // means "top items" here groups by that snapshot name rather than
        // a live menu item id.
        $itemsQuery = (new \App\Models\OrderItemModel())
            ->select('order_items.item_name, SUM(order_items.quantity) as qty_sold, SUM(order_items.price * order_items.quantity) as item_revenue')
            ->join('orders', 'orders.id = order_items.order_id')
            ->where('orders.placed_at >=', $rangeStart)
            ->where('orders.placed_at <=', $rangeEnd)
            ->where('orders.payment_status', 'paid')
            ->groupBy('order_items.item_name')
            ->orderBy('qty_sold', 'DESC')
            ->limit(10);
        if ($restaurantId) {
            $itemsQuery->where('orders.restaurant_id', $restaurantId);
        }
        $topItems = $itemsQuery->findAll();

        // Restaurant-wise breakdown only makes sense for the app owner —
        // a manager already has exactly one restaurant.
        $restaurantBreakdown = [];
        if (! $isManager) {
            $restaurantBreakdown = (new OrderModel())
                ->select('restaurants.name as restaurant_name, COUNT(orders.id) as orders, SUM(CASE WHEN orders.payment_status = "paid" THEN orders.total ELSE 0 END) as revenue')
                ->join('restaurants', 'restaurants.id = orders.restaurant_id')
                ->where('orders.placed_at >=', $rangeStart)
                ->where('orders.placed_at <=', $rangeEnd)
                ->groupBy('orders.restaurant_id')
                ->orderBy('revenue', 'DESC')
                ->findAll();
        }

        return view('admin/reports/index', [
            'is_manager'           => $isManager,
            'date_from'            => $dateFrom,
            'date_to'              => $dateTo,
            'restaurant_id'        => $restaurantId,
            'restaurants'          => $isManager ? [] : (new RestaurantModel())->orderBy('name', 'ASC')->findAll(),
            'total_orders'         => $totalOrders,
            'paid_orders'          => $paidOrders,
            'revenue'              => $revenue,
            'total_discount'       => $totalDiscount,
            'avg_order_value'      => $avgOrderValue,
            'status_breakdown'     => $statusBreakdown,
            'daily_sales'          => $dailySales,
            'max_daily_revenue'    => $maxDailyRevenue,
            'top_items'            => $topItems,
            'restaurant_breakdown' => $restaurantBreakdown,
        ]);
    }
}
