<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;
use App\Models\UserModel;
use App\Models\AddressModel;
use App\Models\OrderModel;

class ProfileController extends BaseController
{
    public function index()
    {
        $userId = session()->get('user_id');
        $userModel = new UserModel();
        $addressModel = new AddressModel();
        $orderModel = new OrderModel();

        return view('customer/profile', [
            'user'       => $userModel->find($userId),
            'addresses'  => $addressModel->where('user_id', $userId)->findAll(),
            'orderCount' => $orderModel->where('user_id', $userId)->countAllResults(),
        ]);
    }

    public function updateProfile()
    {
        $userId = session()->get('user_id');
        $userModel = new UserModel();

        $rules = [
            'name'  => 'required|min_length[2]',
            'phone' => 'required|min_length[10]',
        ];

        if (! $this->validate($rules)) {
            return redirect()->to('/profile')->with('error', implode(' ', $this->validator->getErrors()));
        }

        $userModel->update($userId, [
            'name'  => $this->request->getPost('name'),
            'phone' => $this->request->getPost('phone'),
        ]);

        session()->set('user_name', $this->request->getPost('name'));

        return redirect()->to('/profile')->with('success', 'Profile updated.');
    }

    // Actual Salem district boundary (not a rough rectangle) — same points
    // used to draw the map polygon client-side, kept here so the server
    // enforces the exact same shape regardless of what the browser sends.
    protected const SALEM_POLYGON = [
        [11.9560, 77.7280], // Mettur / West Border
        [12.0830, 77.9140], // North West / Mecheri
        [12.0120, 78.1820], // North / Yercaud hills edge
        [11.7580, 78.5860], // East / Attur edge
        [11.5320, 78.6540], // South East / Thalaivasal
        [11.4500, 78.3620], // South / Vazhapadi-Namakkal border
        [11.5300, 77.8900], // South West / Sankagiri edge
        [11.6020, 77.7500], // Jalakandapuram border
        [11.9560, 77.7280], // Closed loop (first point repeated)
    ];

    /**
     * Standard ray-casting point-in-polygon test: draws a ray from the
     * point eastward and counts how many polygon edges it crosses. Odd
     * number of crossings = inside.
     */
    protected function isWithinSalemDistrict($lat, $lng): bool
    {
        if ($lat === null || $lng === null || $lat === '' || $lng === '') {
            return false;
        }
        $lat = (float) $lat;
        $lng = (float) $lng;

        $polygon = self::SALEM_POLYGON;
        $inside = false;
        $n = count($polygon);

        for ($i = 0, $j = $n - 1; $i < $n; $j = $i++) {
            $latI = $polygon[$i][0];
            $lngI = $polygon[$i][1];
            $latJ = $polygon[$j][0];
            $lngJ = $polygon[$j][1];

            $intersects = (($lngI > $lng) !== ($lngJ > $lng))
                && ($lat < ($latJ - $latI) * ($lng - $lngI) / ($lngJ - $lngI) + $latI);

            if ($intersects) {
                $inside = ! $inside;
            }
        }

        return $inside;
    }

    public function addAddress()
    {
        $userId = session()->get('user_id');
        $addressModel = new AddressModel();

        $rules = [
            'label'        => 'required',
            'address_line' => 'required',
            'city'         => 'required',
            'state'        => 'required',
            'pincode'      => 'required|min_length[4]',
        ];

        if (! $this->validate($rules)) {
            return redirect()->to('/profile')->with('error', implode(' ', $this->validator->getErrors()));
        }

        $lat = $this->request->getPost('lat');
        $lng = $this->request->getPost('lng');

        if (! $this->isWithinSalemDistrict($lat, $lng)) {
            return redirect()->to('/profile')->with('error', 'Please pick a delivery location within Salem district using the map — we currently only deliver there.');
        }

        $makeDefault = (bool) $this->request->getPost('is_default');

        if ($makeDefault) {
            $addressModel->where('user_id', $userId)->set(['is_default' => 0])->update();
        }

        // First-ever address for this user is always the default, regardless of the checkbox
        $hasAny = $addressModel->where('user_id', $userId)->countAllResults() > 0;

        $addressModel->insert([
            'user_id'      => $userId,
            'label'        => $this->request->getPost('label'),
            'address_line' => $this->request->getPost('address_line'),
            'city'         => $this->request->getPost('city'),
            'state'        => $this->request->getPost('state'),
            'pincode'      => $this->request->getPost('pincode'),
            'lat'          => $lat,
            'lng'          => $lng,
            'is_default'   => ($makeDefault || ! $hasAny) ? 1 : 0,
        ]);

        return redirect()->to('/profile')->with('success', 'Address added.');
    }

    public function setDefaultAddress($id)
    {
        $userId = session()->get('user_id');
        $addressModel = new AddressModel();

        $address = $addressModel->find($id);
        if (! $address || $address['user_id'] != $userId) {
            return redirect()->to('/profile')->with('error', 'Address not found.');
        }

        $addressModel->where('user_id', $userId)->set(['is_default' => 0])->update();
        $addressModel->update($id, ['is_default' => 1]);

        return redirect()->to('/profile')->with('success', 'Default address updated.');
    }

    public function deleteAddress($id)
    {
        $userId = session()->get('user_id');
        $addressModel = new AddressModel();

        $address = $addressModel->find($id);
        if (! $address || $address['user_id'] != $userId) {
            return redirect()->to('/profile')->with('error', 'Address not found.');
        }

        $addressModel->delete($id);

        return redirect()->to('/profile')->with('success', 'Address removed.');
    }
}
