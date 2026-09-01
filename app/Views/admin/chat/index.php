<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<h4 class="section-title mb-4">Live Chat <?php if ($is_manager): ?><span class="badge bg-secondary fs-6">Your Restaurant</span><?php endif; ?></h4>

<div class="card card-jeevi">
    <div id="chatThreadsBody">
        <p class="text-muted p-4 mb-0">Connecting…</p>
    </div>
</div>



<script type="module">
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import { getAuth, signInWithCustomToken } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js";
import { getFirestore, collection, query, where, orderBy, onSnapshot } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";

const isManager = <?= $is_manager ? 'true' : 'false' ?>;
const body = document.getElementById('chatThreadsBody');

function render(threads) {
    if (threads.length === 0) {
        body.innerHTML = '<p class="text-muted p-4 mb-0">No chat conversations yet.</p>';
        return;
    }
    body.innerHTML = `
        <table class="table mb-0 align-middle">
            <thead>
                <tr>
                    <th class="ps-3">Customer</th>
                    <th>Email</th>
                    <th>Status</th>
                    <th>Last Message</th>
                    <th class="text-end pe-3">Unread</th>
                </tr>
            </thead>
            <tbody>
                ${threads.map(t => `
                    <tr>
                        <td class="ps-3"><a href="<?= base_url('admin/chat/') ?>${t.userId}">${escapeHtml(t.customerName || 'Unknown customer')}</a></td>
                        <td>${escapeHtml(t.customerEmail || '')}</td>
                        <td>${t.status === 'closed' ? '<span class="badge bg-secondary">Closed</span>' : '<span class="badge bg-success">Open</span>'}</td>
                        <td class="text-muted small">${t.lastMessageAt}</td>
                        <td class="text-end pe-3">
                            ${t.unreadForStaff > 0 ? `<span class="badge bg-danger">${t.unreadForStaff}</span>` : '<span class="text-muted small">—</span>'}
                        </td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;
}

function escapeHtml(str) {
    const d = document.createElement('div');
    d.textContent = str;
    return d.innerHTML;
}

async function init() {
    try {
        const tokenRes = await fetch(`<?= base_url('admin/chat/firebase-token') ?>`);
        const tokenData = await tokenRes.json();
        if (! tokenData.success) throw new Error('Could not start chat session.');

        const app = initializeApp(<?= json_encode(config('Firebase')->toJsConfig()) ?>);
        const auth = getAuth(app);
        const db = getFirestore(app);
        await signInWithCustomToken(auth, tokenData.token);

        let q;
        if (isManager) {
            q = query(collection(db, 'chat_threads'),
                where('recipientRole', '==', 'manager'),
                where('restaurantId', '==', tokenData.restaurant_id),
                orderBy('lastMessageAt', 'desc'));
        } else {
            q = query(collection(db, 'chat_threads'),
                where('recipientRole', '==', 'admin'),
                orderBy('lastMessageAt', 'desc'));
        }

        onSnapshot(q, (snap) => {
            const threads = snap.docs.map(d => {
                const data = d.data();
                return {
                    userId: data.userId,
                    customerName: data.customerName,
                    customerEmail: data.customerEmail,
                    status: data.status || 'open',
                    lastMessageAt: data.lastMessageAt?.toDate ? data.lastMessageAt.toDate().toLocaleString() : '',
                    unreadForStaff: data.unreadForStaff || 0,
                };
            });
            render(threads);
        }, (err) => {
            body.innerHTML = `<p class="text-danger p-4 mb-0">Could not load chats: ${err.message}</p>`;
        });
    } catch (err) {
        body.innerHTML = `<p class="text-danger p-4 mb-0">Could not connect to chat: ${err.message}</p>`;
    }
}

init();
</script>
<?= $this->endSection() ?>
