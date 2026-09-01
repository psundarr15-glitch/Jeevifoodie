<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>

<a href="<?= base_url('admin/chat') ?>" class="small d-inline-block mb-3"><i class="bi bi-arrow-left"></i> Back to Live Chat</a>
<div class="d-flex justify-content-between align-items-center mb-4">
    <h4 class="section-title mb-0">Chat with <?= esc($customer['name'] ?? 'Customer') ?></h4>
    <div id="adminChatStatusArea"></div>
</div>

<div class="card card-jeevi p-3">
    <div id="adminChatThread" style="height: 420px; overflow-y: auto;" class="mb-3 px-2">
        <p class="text-muted small">Connecting…</p>
    </div>
    <div id="adminChatClosedBanner" class="alert alert-secondary py-2 small mb-2" style="display:none;">
        This chat has ended. Replying will re-open it.
    </div>
    <form id="adminChatForm" class="d-flex gap-2">
        <input type="text" id="adminChatInput" class="form-control" placeholder="Type a reply…" autocomplete="off" disabled>
        <button type="submit" class="btn btn-jeevi" disabled>Send</button>
    </form>
    <p id="adminChatError" class="text-danger small mt-2 mb-0" style="display:none;"></p>
</div>



<script type="module">
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import { getAuth, signInWithCustomToken } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js";
import {
    getFirestore, collection, doc, addDoc, getDoc,
    query, orderBy, onSnapshot, serverTimestamp, updateDoc
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";

const customerId = <?= (int) $customer_id ?>;
const isManager  = <?= $is_manager ? 'true' : 'false' ?>;

const thread = document.getElementById('adminChatThread');
const form = document.getElementById('adminChatForm');
const input = document.getElementById('adminChatInput');
const submitBtn = form.querySelector('button[type="submit"]');
const errorBox = document.getElementById('adminChatError');
const statusArea = document.getElementById('adminChatStatusArea');
const closedBanner = document.getElementById('adminChatClosedBanner');

function showError(msg) {
    errorBox.textContent = msg;
    errorBox.style.display = 'block';
}

function scrollToBottom() { thread.scrollTop = thread.scrollHeight; }

function escapeHtml(str) {
    const d = document.createElement('div');
    d.textContent = str;
    return d.innerHTML;
}

function renderMessages(messages) {
    if (messages.length === 0) {
        thread.innerHTML = '<p class="text-muted small">No messages yet.</p>';
        return;
    }
    thread.innerHTML = messages.map(m => `
        <div class="d-flex mb-2 ${m.sender === 'support' ? 'justify-content-end' : 'justify-content-start'}">
            <div class="p-2 px-3 rounded-3 ${m.sender === 'support' ? 'bg-danger text-white' : 'bg-light'}" style="max-width: 70%;">
                ${escapeHtml(m.message)}
                <div class="small ${m.sender === 'support' ? 'text-white-50' : 'text-muted'}" style="font-size: .68rem;">${m.createdAt ?? ''}</div>
            </div>
        </div>
    `).join('');
    scrollToBottom();
}

function renderStatus(status, onToggle) {
    const isClosed = status === 'closed';
    closedBanner.style.display = isClosed ? '' : 'none';
    statusArea.innerHTML = `
        <span class="badge ${isClosed ? 'bg-secondary' : 'bg-success'} me-2">${isClosed ? 'Closed' : 'Open'}</span>
        <button type="button" id="adminChatToggleBtn" class="btn btn-sm btn-outline-secondary">
            ${isClosed ? 'Reopen chat' : 'Close chat'}
        </button>
    `;
    document.getElementById('adminChatToggleBtn').addEventListener('click', () => onToggle(isClosed));
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

        const threadId = isManager
            ? `restaurant_${tokenData.restaurant_id}_user_${customerId}`
            : `admin_${customerId}`;

        const threadRef = doc(db, 'chat_threads', threadId);
        const messagesRef = collection(db, 'chat_threads', threadId, 'messages');

        onSnapshot(query(messagesRef, orderBy('createdAt', 'asc')), (snap) => {
            const messages = snap.docs.map(d => {
                const data = d.data();
                return {
                    sender: data.sender,
                    message: data.message,
                    createdAt: data.createdAt?.toDate ? data.createdAt.toDate().toLocaleString() : '',
                };
            });
            renderMessages(messages);
        }, (err) => {
            showError('Lost connection to chat: ' + err.message);
        });

        let currentStatus = 'open';
        onSnapshot(threadRef, (snap) => {
            currentStatus = snap.exists() ? (snap.data().status || 'open') : 'open';
            renderStatus(currentStatus, async (wasClosed) => {
                try {
                    await updateDoc(threadRef, wasClosed
                        ? { status: 'open', closedAt: null, closedBy: null }
                        : { status: 'closed', closedAt: serverTimestamp(), closedBy: isManager ? 'manager' : 'admin' });
                } catch (err) {
                    showError('Could not update chat status: ' + err.message);
                }
            });
        });

        input.disabled = false;
        submitBtn.disabled = false;

        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            const message = input.value.trim();
            if (! message) return;
            input.value = '';
            submitBtn.disabled = true;
            try {
                const threadSnap = await getDoc(threadRef);
                if (! threadSnap.exists()) {
                    showError('This customer has not messaged this thread yet.');
                    input.value = message;
                    return;
                }
                await addDoc(messagesRef, {
                    sender: 'support',
                    message,
                    createdAt: serverTimestamp(),
                });
                const wasClosed = (threadSnap.data().status || 'open') === 'closed';
                await updateDoc(threadRef, {
                    lastMessage: message,
                    lastMessageAt: serverTimestamp(),
                    unreadForCustomer: (threadSnap.data().unreadForCustomer || 0) + 1,
                    unreadForStaff: 0,
                    // Replying to a closed chat re-opens it — same
                    // behavior as the customer sending a new message.
                    ...(wasClosed ? { status: 'open', closedAt: null, closedBy: null } : {}),
                });
                errorBox.style.display = 'none';
            } catch (err) {
                showError('Reply could not be sent: ' + err.message);
                input.value = message;
            } finally {
                submitBtn.disabled = false;
            }
        });

        const snap = await getDoc(threadRef);
        if (snap.exists()) {
            await updateDoc(threadRef, { unreadForStaff: 0 });
        }
    } catch (err) {
        showError('Could not connect to chat: ' + err.message);
    }
}

init();
</script>
<?= $this->endSection() ?>
