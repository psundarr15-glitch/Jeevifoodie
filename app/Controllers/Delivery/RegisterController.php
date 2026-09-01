<?php

namespace App\Controllers\Delivery;

use App\Controllers\BaseController;
use App\Models\DeliveryPartnerModel;

/**
 * Public self-service registration for delivery partners — matches the
 * restaurant owner self-registration flow (App\Controllers\Admin\
 * RestaurantRegisterController).
 */
class RegisterController extends BaseController
{
    public function show()
    {
        return view('delivery/register');
    }

    public function store()
    {
        $rules = [
            'name'           => 'required|min_length[2]',
            'email'          => 'required|valid_email|is_unique[delivery_partners.email]',
            'password'       => 'required|min_length[6]',
            'phone'          => 'required|min_length[10]',
            'vehicle_number' => 'required',
        ];

        if (! $this->validate($rules)) {
            return redirect()->back()->withInput()->with('error', implode(' ', $this->validator->getErrors()));
        }

        (new DeliveryPartnerModel())->insert([
            'name'           => $this->request->getPost('name'),
            'email'          => $this->request->getPost('email'),
            'password'       => password_hash($this->request->getPost('password'), PASSWORD_DEFAULT),
            'phone'          => $this->request->getPost('phone'),
            'vehicle_number' => $this->request->getPost('vehicle_number'),
            'is_available'   => 1,
        ]);

        return redirect()->to('/delivery/login')->with('success', 'Registration successful! Log in below to start receiving orders.');
    }
}
