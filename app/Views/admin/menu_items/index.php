<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <h3 class="section-title mb-0">Menu Items</h3>
    <a href="<?= base_url('admin/menu-items/create') ?>" class="btn btn-jeevi">+ Add Menu Item</a>
</div>

<div class="card card-jeevi">
    <table class="table mb-0">
        <thead><tr><th>Name</th><th>Restaurant</th><th>Price</th><th>Veg</th><th>Available</th><th></th></tr></thead>
        <tbody>
        <?php foreach ($items as $i): ?>
            <tr>
                <td><?= esc($i['name']) ?></td>
                <td><?= esc($i['restaurant_name']) ?></td>
                <td>₹<?= esc($i['price']) ?></td>
                <td><?= $i['is_veg'] ? 'Veg' : 'Non-Veg' ?></td>
                <td><?= $i['is_available'] ? '<span class="badge bg-success">Yes</span>' : '<span class="badge bg-secondary">No</span>' ?></td>
                <td>
                    <form action="<?= base_url('admin/menu-items/toggle-availability/' . $i['id']) ?>" method="post" class="d-inline">
                        <?= csrf_field() ?>
                        <button type="submit" class="btn btn-sm <?= $i['is_available'] ? 'btn-outline-secondary' : 'btn-jeevi' ?>">
                            <?= $i['is_available'] ? 'Mark Out of Stock' : 'Mark Available' ?>
                        </button>
                    </form>
                    <a href="<?= base_url('admin/menu-items/edit/' . $i['id']) ?>" class="btn btn-sm btn-jeevi-outline">Edit</a>
                    <form action="<?= base_url('admin/menu-items/delete/' . $i['id']) ?>" method="post" class="d-inline" onsubmit="return confirm('Delete this item?')"><?= csrf_field() ?><button type="submit" class="btn btn-sm btn-outline-danger">Delete</button></form>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<?= $this->endSection() ?>
