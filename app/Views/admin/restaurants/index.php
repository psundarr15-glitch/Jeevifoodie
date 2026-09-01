<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <h3 class="section-title mb-0">Restaurants</h3>
    <a href="<?= base_url('admin/restaurants/create') ?>" class="btn btn-jeevi">+ Add Restaurant</a>
</div>

<div class="card card-jeevi">
    <table class="table mb-0">
        <thead><tr><th>Image</th><th>Name</th><th>Cuisine</th><th>Rating</th><th>Active</th><th></th></tr></thead>
        <tbody>
        <?php foreach ($restaurants as $r): ?>
            <tr>
                <td>
                    <?php if (! empty($r['image'])): ?>
                        <img src="<?= esc($r['image']) ?>" alt="" style="width:56px;height:40px;object-fit:cover;border-radius:6px;">
                    <?php else: ?>
                        <span class="text-muted small">No image</span>
                    <?php endif; ?>
                </td>
                <td><?= esc($r['name']) ?></td>
                <td><?= esc($r['cuisine']) ?></td>
                <td>★ <?= esc($r['rating']) ?></td>
                <td><?= $r['is_active'] ? '<span class="badge bg-success">Active</span>' : '<span class="badge bg-secondary">Inactive</span>' ?></td>
                <td>
                    <a href="<?= base_url('admin/restaurants/edit/' . $r['id']) ?>" class="btn btn-sm btn-jeevi-outline">Edit</a>
                    <form action="<?= base_url('admin/restaurants/delete/' . $r['id']) ?>" method="post" class="d-inline" onsubmit="return confirm('Delete this restaurant?')"><?= csrf_field() ?><button type="submit" class="btn btn-sm btn-outline-danger">Delete</button></form>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<?= $this->endSection() ?>
