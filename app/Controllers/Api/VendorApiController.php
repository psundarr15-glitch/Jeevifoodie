<?php

namespace App\Controllers\Api;

use App\Models\AdminModel;
use App\Models\RestaurantModel;

/**
 * In-app version of "Open Vendor" (restaurant self-registration). This
 * duplicates Admin\RestaurantRegisterController's logic - including the
 * Salem-district boundary check - because that web form is slated for
 * deletion once the app ships, and the app must not depend on it.
 */
class VendorApiController extends BaseApiController
{
    public function register()
    {
        $rules = [
            'owner_name'       => 'required|min_length[2]',
            'owner_phone'      => 'required|min_length[10]',
            'manager_email'    => 'required|valid_email|is_unique[admins.email]',
            'manager_password' => 'required|min_length[6]',
            'restaurant_name'  => 'required|min_length[2]',
            'restaurant_phone' => 'required|min_length[10]',
            'restaurant_type'  => 'required',
            'food_type'        => 'required|in_list[veg,non_veg,both]',
            'cuisine'          => 'required',
            'address'          => 'required',
            'lat'              => 'required',
            'lng'              => 'required',
            // FSSAI is mandatory for any food business in India; TIN/GST
            // is optional since very small/new eateries may not have one yet.
            'fssai_number'     => 'required',
            // Bank details are optional at signup - a restaurant can start
            // taking Cash on Delivery orders and add payout details later.
            'bank_account_number' => 'permit_empty',
            'bank_ifsc'           => 'permit_empty',
            'bank_account_holder' => 'permit_empty',
        ];
        if (! $this->validate($rules)) {
            return $this->fail(implode(' ', $this->validator->getErrors()));
        }

        if (! $this->isWithinSalemDistrict($this->request->getPost('lat'), $this->request->getPost('lng'))) {
            return $this->fail("Please pick your restaurant's location within Salem district on the map.");
        }

        $data = [
            'name'                => $this->request->getPost('restaurant_name'),
            'owner_name'          => $this->request->getPost('owner_name'),
            'phone'               => $this->request->getPost('restaurant_phone'),
            'owner_phone'         => $this->request->getPost('owner_phone'),
            'restaurant_type'     => $this->request->getPost('restaurant_type'),
            'food_type'           => $this->request->getPost('food_type'),
            'cuisine'             => $this->request->getPost('cuisine'),
            'description'         => $this->request->getPost('description'),
            'address'             => $this->request->getPost('address'),
            'lat'                 => $this->request->getPost('lat'),
            'lng'                 => $this->request->getPost('lng'),
            'cost_for_two'        => $this->request->getPost('cost_for_two') ?: 0,
            'opening_time'        => $this->request->getPost('opening_time') ?: '09:00',
            'closing_time'        => $this->request->getPost('closing_time') ?: '23:00',
            'fssai_number'        => $this->request->getPost('fssai_number'),
            'tin_number'          => $this->request->getPost('tin_number'),
            'bank_account_number' => $this->request->getPost('bank_account_number'),
            'bank_ifsc'           => $this->request->getPost('bank_ifsc'),
            'bank_account_holder' => $this->request->getPost('bank_account_holder'),
            'is_active'           => 1,
        ];

        $this->attachUpload($data, 'image', 'restaurant_banner', 'restaurants');
        $this->attachUpload($data, 'logo', 'restaurant_logo', 'restaurants');
        $this->attachUpload($data, 'fssai_certificate', 'fssai_certificate', 'restaurants/documents');
        $this->attachUpload($data, 'tin_certificate', 'tin_certificate', 'restaurants/documents');

        $restaurantId = (new RestaurantModel())->insert($data);

        (new AdminModel())->insert([
            'name'          => $this->request->getPost('owner_name'),
            'email'         => $this->request->getPost('manager_email'),
            'password'      => password_hash($this->request->getPost('manager_password'), PASSWORD_DEFAULT),
            'role'          => 'restaurant_manager',
            'restaurant_id' => $restaurantId,
        ]);

        return $this->ok(['message' => 'Your restaurant has been registered! You can now log in to the admin panel to manage it.']);
    }

    /**
     * Moves an uploaded file (if present and valid) into
     * public/assets/uploads/{subdir}/ and stores its public URL under
     * $data[$dataKey]. Silently does nothing if no file was sent for
     * $fieldName - every document here is either optional, or checked
     * separately by validation rules.
     */
    private function attachUpload(array &$data, string $dataKey, string $fieldName, string $subdir): void
    {
        $file = $this->request->getFile($fieldName);
        if ($file && $file->isValid() && ! $file->hasMoved()) {
            $newName = $file->getRandomName();
            $file->move(FCPATH . 'assets/uploads/' . $subdir, $newName);
            $data[$dataKey] = base_url('assets/uploads/' . $subdir . '/' . $newName);
        }
    }

    private function isWithinSalemDistrict($lat, $lng): bool
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
