<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<h3 class="section-title mb-4">Customers</h3>

<div class="card card-jeevi">
    <table class="table mb-0">
        <thead><tr><th>Name</th><th>Email</th><th>Phone</th><th>Orders</th><th></th></tr></thead>
        <tbody>
        <?php foreach ($users as $u): ?>
            <tr>
                <td><?= esc($u['name']) ?></td>
                <td><?= esc($u['email']) ?></td>
                <td><?= esc($u['phone']) ?></td>
                <td><?= (int)$u['order_count'] ?></td>
                <td>
                    <a href="<?= base_url('admin/users/' . $u['id']) ?>" class="btn btn-sm btn-jeevi-outline">View</a>
                    <a href="<?= base_url('admin/users/edit/' . $u['id']) ?>" class="btn btn-sm btn-jeevi-outline">Edit</a>
                    <form action="<?= base_url('admin/users/delete/' . $u['id']) ?>" method="post" class="d-inline" onsubmit="return confirm('Delete this customer? This cannot be undone.')"><?= csrf_field() ?><button type="submit" class="btn btn-sm btn-outline-danger">Delete</button></form>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<?= $this->endSection() ?>
