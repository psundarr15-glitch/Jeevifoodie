<?php

namespace App\Controllers\Api;

use App\Models\DeliveryPartnerModel;

class DeliveryAuthApiController extends BaseApiController
{
    public function login()
    {
        $model = new DeliveryPartnerModel();
        $partner = $model->where('email', $this->request->getPost('email'))->first();

        if (! $partner || ! $partner['password'] || ! password_verify($this->request->getPost('password'), $partner['password'])) {
            return $this->fail('Invalid email or password.', 401);
        }

        $token = bin2hex(random_bytes(32));
        $model->update($partner['id'], ['api_token' => $token]);

        return $this->ok([
            'token'   => $token,
            'partner' => ['id' => $partner['id'], 'name' => $partner['name'], 'phone' => $partner['phone']],
        ]);
    }

    public function logout()
    {
        $partner = $this->authPartner();
        if (! $partner) return $this->response;

        (new DeliveryPartnerModel())->update($partner['id'], ['api_token' => null]);
        return $this->ok();
    }

    /**
     * In-app version of the "Join as a Delivery Man" flow. This app must
     * not depend on the web frontend (Delivery\RegisterController) at
     * all, since that's slated for deletion once the app ships - so
     * this duplicates its validation rather than the app linking out to
     * a page that may not exist anymore.
     */
    public function register()
    {
        $rules = [
            'name'                => 'required|min_length[2]',
            'email'               => 'required|valid_email|is_unique[delivery_partners.email]',
            'password'            => 'required|min_length[6]',
            'phone'               => 'required|min_length[10]',
            'dob'                 => 'required|valid_date',
            'city'                => 'required',
            'district'            => 'required',
            'pincode'             => 'required|regex_match[/^[0-9]{6}$/]',
            'aadhaar_number'      => 'required|regex_match[/^[0-9]{12}$/]',
            'license_number'      => 'required',
            'vehicle_type'        => 'required',
            'vehicle_number'      => 'required',
            'rc_number'           => 'required',
            // Bank details are optional at signup - a partner can start
            // taking deliveries and add payout details before their first
            // payout cycle instead.
            'bank_account_number' => 'permit_empty',
            'bank_ifsc'           => 'permit_empty',
            'bank_account_holder' => 'permit_empty',
        ];
        if (! $this->validate($rules)) {
            return $this->fail(implode(' ', $this->validator->getErrors()));
        }

        $data = [
            'name'                => $this->request->getPost('name'),
            'email'               => $this->request->getPost('email'),
            'password'            => password_hash($this->request->getPost('password'), PASSWORD_DEFAULT),
            'phone'               => $this->request->getPost('phone'),
            'dob'                 => $this->request->getPost('dob'),
            'city'                => $this->request->getPost('city'),
            'district'            => $this->request->getPost('district'),
            'pincode'             => $this->request->getPost('pincode'),
            'address_lat'         => $this->request->getPost('lat') ?: null,
            'address_lng'         => $this->request->getPost('lng') ?: null,
            'aadhaar_number'      => $this->request->getPost('aadhaar_number'),
            'license_number'      => $this->request->getPost('license_number'),
            'vehicle_type'        => $this->request->getPost('vehicle_type'),
            'vehicle_number'      => $this->request->getPost('vehicle_number'),
            'rc_number'           => $this->request->getPost('rc_number'),
            'bank_account_number' => $this->request->getPost('bank_account_number'),
            'bank_ifsc'           => $this->request->getPost('bank_ifsc'),
            'bank_account_holder' => $this->request->getPost('bank_account_holder'),
            'is_available'        => 1,
        ];

        $this->attachUpload($data, 'photo', 'photo', 'delivery_partners');
        $this->attachUpload($data, 'id_proof_document', 'id_proof_document', 'delivery_partners/documents');
        $this->attachUpload($data, 'rc_document', 'rc_document', 'delivery_partners/documents');

        (new DeliveryPartnerModel())->insert($data);

        return $this->ok(['message' => 'Registration successful! You can now log in from the delivery partner app.']);
    }

    /**
     * Moves an uploaded file (if present and valid) into
     * public/assets/uploads/{subdir}/ and stores its public URL under
     * $data[$dataKey]. Silently does nothing if no file was sent for
     * $fieldName.
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
}
