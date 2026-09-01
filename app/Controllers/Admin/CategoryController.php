<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\CategoryModel;

/**
 * Main/top-level categories (e.g. "Indian Food", "Chinese Food") - the
 * app owner's job, not a restaurant manager's. A manager creates
 * sub-categories nested under one of these (e.g. "Biryani" under
 * "Indian Food") via SubCategoryController instead - that's where their
 * own menu items get grouped.
 */
class CategoryController extends BaseController
{
    private function blockManagers()
    {
        if (session()->get('admin_role') === 'restaurant_manager') {
            return redirect()->to('/admin/dashboard')->with('error', 'Main categories are managed by the app owner. Use Sub-Categories to organize your own menu.');
        }
        return null;
    }

    public function index()
    {
        if ($block = $this->blockManagers()) return $block;
        return view('admin/categories/index', ['categories' => (new CategoryModel())->findAll()]);
    }

    public function store()
    {
        if ($block = $this->blockManagers()) return $block;

        $model = new CategoryModel();
        $data = [
            'name'    => $this->request->getPost('name'),
            'name_ta' => $this->request->getPost('name_ta') ?: null,
        ];

        $file = $this->request->getFile('icon');
        if ($file && $file->isValid() && ! $file->hasMoved()) {
            $newName = $file->getRandomName();
            $file->move(FCPATH . 'assets/uploads/categories', $newName);
            $data['icon'] = base_url('assets/uploads/categories/' . $newName);
        }

        $model->insert($data);
        return redirect()->to('/admin/categories')->with('success', 'Category added.');
    }

    public function edit($id)
    {
        if ($block = $this->blockManagers()) return $block;

        $category = (new CategoryModel())->find($id);
        if (! $category) {
            return redirect()->to('/admin/categories')->with('error', 'Not found.');
        }
        return view('admin/categories/edit', ['category' => $category]);
    }

    public function update($id)
    {
        if ($block = $this->blockManagers()) return $block;

        $model = new CategoryModel();
        $data = [
            'name'    => $this->request->getPost('name'),
            'name_ta' => $this->request->getPost('name_ta') ?: null,
        ];

        $file = $this->request->getFile('icon');
        if ($file && $file->isValid() && ! $file->hasMoved()) {
            $newName = $file->getRandomName();
            $file->move(FCPATH . 'assets/uploads/categories', $newName);
            $data['icon'] = base_url('assets/uploads/categories/' . $newName);
        }

        $model->update($id, $data);
        return redirect()->to('/admin/categories')->with('success', 'Category updated.');
    }

    public function delete($id)
    {
        if ($block = $this->blockManagers()) return $block;

        (new CategoryModel())->delete($id);
        return redirect()->to('/admin/categories')->with('success', 'Category deleted.');
    }
}
