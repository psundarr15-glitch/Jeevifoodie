<?= $this->extend('admin/layouts/main') ?>
<?= $this->section('content') ?>
<h3 class="section-title mb-4">Live Chat (Firebase/Firestore) Setup Diagnosis</h3>

<div class="card card-jeevi p-4 mb-4" style="max-width: 700px;">
    <p class="text-muted small mb-3">Checked top to bottom - fix the first FAILED step, then reload this page.</p>
    <table class="table mb-0">
        <tbody>
        <?php foreach ($report as $step => $result): ?>
            <tr>
                <td style="width: 45%;"><?= esc($step) ?></td>
                <td>
                    <?php if (str_starts_with($result, 'OK')): ?>
                        <span class="text-success fw-bold"><?= esc($result) ?></span>
                    <?php elseif (str_starts_with($result, 'FAILED') || str_starts_with($result, 'MISSING')): ?>
                        <span class="text-danger fw-bold"><?= esc($result) ?></span>
                    <?php else: ?>
                        <span class="text-muted"><?= esc($result) ?></span>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<div class="card card-jeevi p-4" style="max-width: 700px;">
    <h5 class="mb-2">12. Live browser test</h5>
    <p class="text-muted small mb-3">
        Runs the exact same steps the real chat widget does, right here, so
        client-only errors (e.g. <code>auth/CONFIGURATION_NOT_FOUND</code>,
        <code>firestore/unavailable</code>) show up with their real message
        instead of only inside the chat page.
    </p>
    <button id="runLiveTest" class="btn btn-jeevi">Run live test</button>
    <table class="table mt-3 mb-0" id="liveTestTable" style="display:none;">
        <tbody id="liveTestBody"></tbody>
    </table>
</div>

<a href="<?= base_url('admin/chat') ?>" class="btn btn-jeevi-outline mt-3">Back to Live Chat</a>



<script type="module">
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import { getAuth, signInWithCustomToken } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js";
import { getFirestore, doc, setDoc, getDoc, deleteDoc } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";

const button = document.getElementById('runLiveTest');
const table = document.getElementById('liveTestTable');
const body = document.getElementById('liveTestBody');

function addRow(label, ok, detail) {
    const tr = document.createElement('tr');
    tr.innerHTML = `
        <td style="width:45%;">${label}</td>
        <td class="${ok ? 'text-success' : 'text-danger'} fw-bold">${ok ? 'OK' : 'FAILED'}${detail ? ' - ' + detail : ''}</td>
    `;
    body.appendChild(tr);
    table.style.display = '';
}

button.addEventListener('click', async () => {
    button.disabled = true;
    body.innerHTML = '';
    table.style.display = '';

    // Step a: get a Firebase custom token from our own backend.
    let tokenData;
    try {
        const res = await fetch(`<?= base_url('admin/chat/firebase-token') ?>`);
        tokenData = await res.json();
        if (! tokenData.success) throw new Error(tokenData.error || 'token endpoint returned success:false');
        addRow('a. GET /admin/chat/firebase-token', true, `thread role: ${tokenData.is_manager ? 'manager' : 'admin'}`);
    } catch (err) {
        addRow('a. GET /admin/chat/firebase-token', false, err.message);
        button.disabled = false;
        return;
    }

    // Step b: initialize the Firebase Web SDK with the configured web app config.
    let app, auth, db;
    try {
        app = initializeApp(<?= json_encode(config('Firebase')->toJsConfig()) ?>);
        auth = getAuth(app);
        db = getFirestore(app);
        addRow('b. Firebase Web SDK initialized', true);
    } catch (err) {
        addRow('b. Firebase Web SDK initialized', false, err.message);
        button.disabled = false;
        return;
    }

    // Step c: sign in with the custom token. This is where
    // auth/CONFIGURATION_NOT_FOUND shows up if Authentication hasn't
    // been enabled ("Get started") on this Firebase project yet.
    try {
        await signInWithCustomToken(auth, tokenData.token);
        addRow('c. signInWithCustomToken()', true, `uid: ${auth.currentUser.uid}`);
    } catch (err) {
        addRow('c. signInWithCustomToken()', false, `[${err.code}] ${err.message}`);
        if (err.code === 'auth/configuration-not-found') {
            addRow('   → likely fix', true, 'Firebase Console → Build → Authentication → click "Get started" on this project.');
        }
        button.disabled = false;
        return;
    }

    // Step d: write a throwaway doc under this admin/manager's own
    // diagnostic path (allowed by firestore.rules for any signed-in
    // staff user) and read it back. This is where
    // firestore/unavailable or permission-denied shows up.
    const testDocRef = doc(db, 'chat_diagnostics', 'admin_live_test_' + auth.currentUser.uid);
    try {
        await setDoc(testDocRef, { ping: 'ok', at: new Date().toISOString() });
        addRow('d. Firestore write', true);
    } catch (err) {
        addRow('d. Firestore write', false, `[${err.code}] ${err.message}`);
        if (err.code === 'unavailable') {
            addRow('   → likely fix', true, 'Firestore Database not created yet for this project, or network/firewall blocking firestore.googleapis.com — Firebase Console → Build → Firestore Database → Create database.');
        }
        button.disabled = false;
        return;
    }

    try {
        const snap = await getDoc(testDocRef);
        addRow('e. Firestore read', snap.exists(), snap.exists() ? '' : 'doc not found after write');
    } catch (err) {
        addRow('e. Firestore read', false, `[${err.code}] ${err.message}`);
    }

    try {
        await deleteDoc(testDocRef);
        addRow('f. Firestore delete (cleanup)', true);
    } catch (err) {
        addRow('f. Firestore delete (cleanup)', false, `[${err.code}] ${err.message}`);
    }

    addRow('All steps finished', true, 'If every row above is OK, live chat should work — try admin/chat again.');
    button.disabled = false;
});
</script>
<?= $this->endSection() ?>
