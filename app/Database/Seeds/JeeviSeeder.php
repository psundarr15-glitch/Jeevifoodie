<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class JeeviSeeder extends Seeder
{
    public function run()
    {
        $now = date('Y-m-d H:i:s');

        // Super admin login: admin@jeevi.com / admin123
        $this->db->table('admins')->insert([
            'name'     => 'Jeevi Admin',
            'email'    => 'admin@jeevi.com',
            'password' => password_hash('admin123', PASSWORD_DEFAULT),
            'role'     => 'superadmin',
            'created_at' => $now,
        ]);

        // Demo customer login: demo@jeevi.com / demo123
        $this->db->table('users')->insert([
            'name'     => 'Demo Customer',
            'email'    => 'demo@jeevi.com',
            'phone'    => '9999999999',
            'password' => password_hash('demo123', PASSWORD_DEFAULT),
            'created_at' => $now,
            'updated_at' => $now,
        ]);
        $userId = $this->db->insertID();

        $this->db->table('addresses')->insert([
            'user_id'      => $userId,
            'label'        => 'Home',
            'address_line' => '5th Street',
            'city'         => 'Salem',
            'state'        => 'Tamil Nadu',
            'pincode'      => '636001',
            'lat'          => 11.6643,
            'lng'          => 78.1460,
            'is_default'   => 1,
            'created_at'   => $now,
        ]);

        $categories = ['Biryani', 'Pizza', 'Burger', 'Chicken', 'Desserts', 'Beverages'];
        $catIds = [];
        foreach ($categories as $c) {
            $this->db->table('categories')->insert(['name' => $c, 'icon' => strtolower($c) . '.png']);
            $catIds[$c] = $this->db->insertID();
        }

        $restaurants = [
            ['name' => 'Tasty Biryani', 'phone' => '9840012345', 'cuisine' => 'Biryani, North Indian', 'rating' => 4.5, 'rating_count' => 120, 'prep_time_min' => 30, 'prep_time_max' => 40, 'cost_for_two' => 300, 'discount_label' => '50% OFF', 'lat' => 11.6650, 'lng' => 78.1470, 'image' => 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&h=400&fit=crop', 'opening_time' => '10:00:00', 'closing_time' => '23:00:00'],
            ['name' => 'Pizza Heaven', 'phone' => '9840012346', 'cuisine' => 'Pizza, Italian', 'rating' => 4.3, 'rating_count' => 98, 'prep_time_min' => 25, 'prep_time_max' => 35, 'cost_for_two' => 400, 'discount_label' => '40% OFF', 'lat' => 11.6660, 'lng' => 78.1480, 'image' => 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&h=400&fit=crop', 'opening_time' => '11:00:00', 'closing_time' => '22:30:00'],
            ['name' => 'Burger Hub', 'phone' => '9840012347', 'cuisine' => 'Burgers, Fast Food', 'rating' => 4.6, 'rating_count' => 110, 'prep_time_min' => 20, 'prep_time_max' => 30, 'cost_for_two' => 250, 'discount_label' => '60% OFF', 'lat' => 11.6670, 'lng' => 78.1490, 'image' => 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&h=400&fit=crop', 'opening_time' => '18:00:00', 'closing_time' => '02:00:00'],
        ];
        $restIds = [];
        foreach ($restaurants as $r) {
            $r['description'] = 'Good food, great mood — delivered fresh by Jeevi.';
            $r['address'] = '5th Street, Salem';
            $r['is_active'] = 1;
            $r['created_at'] = $now;
            $this->db->table('restaurants')->insert($r);
            $restIds[$r['name']] = $this->db->insertID();
        }

        $menuItems = [
            ['restaurant_id' => $restIds['Tasty Biryani'], 'category_id' => $catIds['Biryani'], 'name' => 'Chicken Biryani', 'price' => 229, 'rating' => 4.6, 'rating_count' => 120, 'is_veg' => 0, 'image' => 'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=500&h=350&fit=crop'],
            ['restaurant_id' => $restIds['Tasty Biryani'], 'category_id' => $catIds['Chicken'], 'name' => 'Paneer Butter Masala', 'price' => 189, 'rating' => 4.4, 'rating_count' => 86, 'is_veg' => 1, 'image' => 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=500&h=350&fit=crop'],
            ['restaurant_id' => $restIds['Pizza Heaven'], 'category_id' => $catIds['Pizza'], 'name' => 'Veg Pizza', 'price' => 249, 'rating' => 4.3, 'rating_count' => 90, 'is_veg' => 1, 'image' => 'https://images.unsplash.com/photo-1595854341625-f33ee10dbf94?w=500&h=350&fit=crop'],
            ['restaurant_id' => $restIds['Burger Hub'], 'category_id' => $catIds['Burger'], 'name' => 'Chicken Burger', 'price' => 149, 'rating' => 4.5, 'rating_count' => 112, 'is_veg' => 0, 'image' => 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=500&h=350&fit=crop'],
        ];
        foreach ($menuItems as $m) {
            $m['description'] = 'Freshly prepared and delivered hot.';
            $m['is_available'] = 1;
            $m['created_at'] = $now;
            $this->db->table('menu_items')->insert($m);
        }

        $this->db->table('coupons')->insert([
            'code' => 'JEEVI30',
            'description' => 'Flat 30% off on your order',
            'discount_type' => 'percent',
            'discount_value' => 30,
            'min_order_value' => 199,
            'max_discount' => 150,
            'valid_from' => date('Y-m-d'),
            'valid_to' => date('Y-m-d', strtotime('+90 days')),
            'is_active' => 1,
        ]);

        $this->db->table('delivery_partners')->insert([
            'name' => 'Suresh Kumar',
            'email' => 'delivery@foodie.test',
            'password' => password_hash('delivery123', PASSWORD_DEFAULT),
            'phone' => '9876543210',
            'vehicle_number' => 'TN-30-AB-1234',
            'current_lat' => 11.6640,
            'current_lng' => 78.1450,
            'is_available' => 1,
        ]);
    }
}
