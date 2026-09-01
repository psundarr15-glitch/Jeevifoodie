<?php

namespace App\Controllers\Delivery;

use App\Controllers\BaseController;
use App\Models\DeliveryPartnerModel;

class AuthController extends BaseController
{
    public function showLogin()
    {
        return view('delivery/login');
    }

    public function login()
    {
        $model = new DeliveryPartnerModel();
        $partner = $model->where('email', $this->request->getPost('email'))->first();

        if (! $partner || ! $partner['password'] || ! password_verify($this->request->getPost('password'), $partner['password'])) {
            return redirect()->back()->with('error', 'Invalid email or password.');
        }

        session()->set([
            'partner_id'   => $partner['id'],
            'partner_name' => $partner['name'],
        ]);

        return redirect()->to('/delivery/dashboard');
    }

    public function logout()
    {
        session()->remove(['partner_id', 'partner_name']);
        return redirect()->to('/delivery/login');
    }
}
