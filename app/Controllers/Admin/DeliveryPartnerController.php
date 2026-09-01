<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\DeliveryPartnerModel;

class DeliveryPartnerController extends BaseController
{
    public function index()
    {
        return view('admin/delivery_partners/index', ['partners' => (new DeliveryPartnerModel())->findAll()]);
    }

    public function store()
    {
        (new DeliveryPartnerModel())->insert([
            'name'           => $this->request->getPost('name'),
            'phone'          => $this->request->getPost('phone'),
            'vehicle_number' => $this->request->getPost('vehicle_number'),
            'is_available'   => 1,
        ]);

        return redirect()->to('/admin/delivery-partners')->with('success', 'Delivery partner added. Open "Edit" to fill in full KYC details.');
    }

    public function edit($id)
    {
        $partner = (new DeliveryPartnerModel())->find($id);
        if (! $partner) {
            return redirect()->to('/admin/delivery-partners')->with('error', 'Not found.');
        }
        return view('admin/delivery_partners/edit', ['partner' => $partner]);
    }

    public function update($id)
    {
        $model = new DeliveryPartnerModel();
        $data = [
            'name'                => $this->request->getPost('name'),
            'phone'               => $this->request->getPost('phone'),
            'dob'                 => $this->request->getPost('dob') ?: null,
            'city'                => $this->request->getPost('city'),
            'district'            => $this->request->getPost('district'),
            'pincode'             => $this->request->getPost('pincode'),
            'aadhaar_number'      => $this->request->getPost('aadhaar_number'),
            'license_number'      => $this->request->getPost('license_number'),
            'vehicle_type'        => $this->request->getPost('vehicle_type'),
            'vehicle_number'      => $this->request->getPost('vehicle_number'),
            'rc_number'           => $this->request->getPost('rc_number'),
            'bank_account_number' => $this->request->getPost('bank_account_number'),
            'bank_ifsc'           => $this->request->getPost('bank_ifsc'),
            'bank_account_holder' => $this->request->getPost('bank_account_holder'),
        ];

        $this->attachUpload($data, 'photo', 'photo', 'delivery_partners');
        $this->attachUpload($data, 'id_proof_document', 'id_proof_document', 'delivery_partners/documents');
        $this->attachUpload($data, 'rc_document', 'rc_document', 'delivery_partners/documents');

        $model->update($id, $data);
        return redirect()->to('/admin/delivery-partners/edit/' . $id)->with('success', 'Delivery partner updated.');
    }

    public function delete($id)
    {
        (new DeliveryPartnerModel())->delete($id);
        return redirect()->to('/admin/delivery-partners')->with('success', 'Deleted.');
    }

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
