<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\AdminModel;
use App\Models\RestaurantModel;

/**
 * Public self-service registration: a restaurant owner signs up AND
 * creates their restaurant listing in one form — no superadmin needs to
 * pre-create anything. This is what was missing before: a manager account
 * with no restaurant_id had nothing to select in the "Restaurant" dropdown
 * anywhere in the admin panel.
 */
class RestaurantRegisterController extends BaseController
{
    public function show()
    {
        return view('admin/restaurant_register');
    }

    public function store()
    {
        $rules = [
            'manager_name'     => 'required|min_length[2]',
            'manager_email'    => 'required|valid_email|is_unique[admins.email]',
            'manager_password' => 'required|min_length[6]',
            'restaurant_name'  => 'required|min_length[2]',
            'restaurant_phone' => 'required|min_length[10]',
            'cuisine'          => 'required',
            'address'          => 'required',
            'lat'              => 'required',
            'lng'              => 'required',
        ];

        if (! $this->validate($rules)) {
            return redirect()->back()->withInput()->with('error', implode(' ', $this->validator->getErrors()));
        }

        // Salem-district check, same rule as the customer address map picker.
        if (! $this->isWithinSalemDistrict($this->request->getPost('lat'), $this->request->getPost('lng'))) {
            return redirect()->back()->withInput()->with('error', 'Please pick your restaurant\'s location within Salem district on the map.');
        }

        $imagePath = null;
        $file = $this->request->getFile('restaurant_image');
        if ($file && $file->isValid() && ! $file->hasMoved()) {
            $newName = $file->getRandomName();
            $file->move(FCPATH . 'assets/uploads/restaurants', $newName);
            $imagePath = base_url('assets/uploads/restaurants/' . $newName);
        }

        $restaurantModel = new RestaurantModel();
        $restaurantId = $restaurantModel->insert([
            'name'           => $this->request->getPost('restaurant_name'),
            'phone'          => $this->request->getPost('restaurant_phone'),
            'cuisine'        => $this->request->getPost('cuisine'),
            'description'    => $this->request->getPost('description'),
            'address'        => $this->request->getPost('address'),
            'lat'            => $this->request->getPost('lat'),
            'lng'            => $this->request->getPost('lng'),
            'cost_for_two'   => $this->request->getPost('cost_for_two') ?: 0,
            'opening_time'   => $this->request->getPost('opening_time') ?: '09:00',
            'closing_time'   => $this->request->getPost('closing_time') ?: '23:00',
            'image'          => $imagePath,
            'is_active'      => 1,
        ]);

        $adminModel = new AdminModel();
        $adminModel->insert([
            'name'          => $this->request->getPost('manager_name'),
            'email'         => $this->request->getPost('manager_email'),
            'password'      => password_hash($this->request->getPost('manager_password'), PASSWORD_DEFAULT),
            'role'          => 'restaurant_manager',
            'restaurant_id' => $restaurantId,
        ]);

        return redirect()->to('/admin/login')->with('success', 'Your restaurant has been registered! Log in below to manage it.');
    }

    protected function isWithinSalemDistrict($lat, $lng): bool
    {
        if ($lat === null || $lng === null || $lat === '' || $lng === '') {
            return false;
        }
        $lat = (float) $lat;
        $lng = (float) $lng;

        $polygon = [
            [11.9560, 77.7280], [12.0830, 77.9140], [12.0120, 78.1820],
            [11.7580, 78.5860], [11.5320, 78.6540], [11.4500, 78.3620],
            [11.5300, 77.8900], [11.6020, 77.7500], [11.9560, 77.7280],
        ];

        $inside = false;
        $n = count($polygon);
        for ($i = 0, $j = $n - 1; $i < $n; $j = $i++) {
            $latI = $polygon[$i][0]; $lngI = $polygon[$i][1];
            $latJ = $polygon[$j][0]; $lngJ = $polygon[$j][1];
            $intersects = (($lngI > $lng) !== ($lngJ > $lng))
                && ($lat < ($latJ - $latI) * ($lng - $lngI) / ($lngJ - $lngI) + $latI);
            if ($intersects) $inside = ! $inside;
        }
        return $inside;
    }
}
