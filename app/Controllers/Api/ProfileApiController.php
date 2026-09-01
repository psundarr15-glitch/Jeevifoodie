<?php

namespace App\Controllers\Api;

use App\Models\UserModel;
use App\Models\AddressModel;
use App\Models\WalletTransactionModel;
use App\Models\DeviceTokenModel;

class ProfileApiController extends BaseApiController
{
    public function view()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        unset($user['password'], $user['api_token']);

        return $this->ok([
            'user'      => $user,
            'addresses' => (new AddressModel())->where('user_id', $user['id'])->findAll(),
        ]);
    }

    public function update()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        (new UserModel())->update($user['id'], [
            'name'  => $this->request->getPost('name'),
            'phone' => $this->request->getPost('phone'),
        ]);

        return $this->ok();
    }

    public function addAddress()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        // Rejects obviously corrupted/garbage submissions - e.g. a
        // pincode that isn't 6 digits, a city name that's just symbols
        // or a single character, lat/lng outside real-world range (can
        // happen if the map picker sends a bad value). This is on top
        // of whatever the app already checks client-side, since a
        // client-side check alone can always be bypassed.
        $rules = [
            'label'        => 'required|min_length[2]|max_length[50]',
            'address_line' => 'required|min_length[5]|max_length[255]',
            'city'         => 'required|min_length[2]|max_length[100]|regex_match[/^[\p{L}\s.\'-]+$/u]',
            'state'        => 'required|min_length[2]|max_length[100]|regex_match[/^[\p{L}\s.\'-]+$/u]',
            'pincode'      => 'required|regex_match[/^[0-9]{6}$/]',
            'lat'          => 'permit_empty|decimal|greater_than_equal_to[-90]|less_than_equal_to[90]',
            'lng'          => 'permit_empty|decimal|greater_than_equal_to[-180]|less_than_equal_to[180]',
        ];
        if (! $this->validate($rules)) {
            return $this->fail(implode(' ', $this->validator->getErrors()));
        }

        $addressModel = new AddressModel();
        $makeDefault = (bool) $this->request->getPost('is_default');
        $hasAny = $addressModel->where('user_id', $user['id'])->countAllResults() > 0;

        if ($makeDefault) {
            $addressModel->where('user_id', $user['id'])->set(['is_default' => 0])->update();
        }

        $id = $addressModel->insert([
            'user_id'      => $user['id'],
            'label'        => $this->request->getPost('label'),
            'address_line' => $this->request->getPost('address_line'),
            'city'         => $this->request->getPost('city'),
            'state'        => $this->request->getPost('state'),
            'pincode'      => $this->request->getPost('pincode'),
            'lat'          => $this->request->getPost('lat') ?: null,
            'lng'          => $this->request->getPost('lng') ?: null,
            'is_default'   => ($makeDefault || ! $hasAny) ? 1 : 0,
        ]);

        return $this->ok(['address' => $addressModel->find($id)]);
    }

    public function setDefaultAddress($id)
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        $addressModel = new AddressModel();
        $address = $addressModel->find($id);
        if (! $address || $address['user_id'] != $user['id']) {
            return $this->fail('Address not found.', 404);
        }

        $addressModel->where('user_id', $user['id'])->set(['is_default' => 0])->update();
        $addressModel->update($id, ['is_default' => 1]);

        return $this->ok();
    }

    public function deleteAddress($id)
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        $addressModel = new AddressModel();
        $address = $addressModel->find($id);
        if (! $address || $address['user_id'] != $user['id']) {
            return $this->fail('Address not found.', 404);
        }

        $addressModel->delete($id);
        return $this->ok();
    }

    /**
     * Wallet balance + recent transactions. View-only - mirrors
     * Customer\WalletController, which has no "add money" action either
     * (balance only changes via refunds/credits from the system).
     */
    public function wallet()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        return $this->ok([
            'balance'      => $user['wallet_balance'] ?? 0,
            'transactions' => (new WalletTransactionModel())->where('user_id', $user['id'])->orderBy('id', 'DESC')->findAll(30),
        ]);
    }

    /**
     * Registers (or refreshes) this device's FCM token so the backend
     * can push order-status notifications to it. Called once after
     * login and again whenever Firebase issues a new/refreshed token.
     */
    public function registerDeviceToken()
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        $token = $this->request->getPost('fcm_token');
        if (! $token) {
            return $this->fail('fcm_token is required.');
        }

        (new DeviceTokenModel())->saveToken($user['id'], $token, $this->request->getPost('platform') ?? 'android');
        return $this->ok();
    }
}
