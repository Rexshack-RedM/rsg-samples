// ============================================================
// RSG SAMPLES — NUI Script
// Edit freely — no escrow on this file.
// ============================================================

// ============================================================
// State
// ============================================================
let lang              = {};
let allSamples        = {};
let collectedSamples  = {};
let topCollectors     = [];
let globalStats       = {};
let currentCitizenId  = null;
let playerName        = '';
let featuredAnimal    = '';
let featuredMultiplier = 2;

let filteredSamples   = [];
let displayedCount    = 10;
let totalSamples      = 0;
let collectedSampleCount = 0;
let totalRewards      = 0;
let activeCategory    = 'All';

// ============================================================
// Utilities
// ============================================================
function post(endpoint, data) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).catch(err => console.error('[rsg-samples] post error:', err));
}

function esc(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

// ============================================================
// Window / menu helpers
// ============================================================
function showMenu(id) {
    hideAllMenus();
    const el = document.getElementById(id);
    if (el) {
        el.classList.remove('hidden');
        el.classList.add('active');
        document.body.classList.add('menus-active');
    }
}

function hideAllMenus() {
    const anyOpen = document.querySelectorAll('.panel-root.active').length > 0;
    document.querySelectorAll('.panel-root').forEach(m => {
        m.classList.add('hidden');
        m.classList.remove('active');
    });
    if (anyOpen) document.body.classList.remove('menus-active');
}

function backToMenu() {
    showMenu('samplesMenuUI');
}

function showToast(type, title, message) {
    const stack = document.getElementById('toastStack');
    if (!stack) return;
    const el = document.createElement('div');
    el.className = 'toast ' + (type === 'success' ? 'toast-success' : type === 'error' ? 'toast-error' : 'toast-info');
    el.innerHTML = '<div class="toast-label">' + esc(title) + '</div><div class="toast-msg">' + esc(message) + '</div>';
    stack.appendChild(el);
    setTimeout(() => el.classList.add('toast-out'), 3000);
    setTimeout(() => el.remove(), 3300);
}

function setText(id, text) {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
}

function setPlaceholder(id, text) {
    const el = document.getElementById(id);
    if (el) el.placeholder = text;
}

function formatAnimalName(name) {
    return String(name)
        .split('_')
        .map(w => w.charAt(0).toUpperCase() + w.slice(1))
        .join(' ');
}

function formatDate(dateStr) {
    if (!dateStr) return '';
    try {
        const d = new Date(dateStr);
        return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    } catch (e) {
        return String(dateStr);
    }
}

// ============================================================
// State setup  (shared by openSamplesMenu and openCertificate)
// ============================================================
function setupState(data) {
    lang               = data.lang             || {};
    allSamples         = data.allSamples        || {};
    collectedSamples   = data.collectedSamples  || {};
    topCollectors      = data.topCollectors     || [];
    globalStats        = data.globalStats       || {};
    currentCitizenId   = data.currentCitizenId  || null;
    playerName         = data.playerName        || 'Unknown';
    featuredAnimal     = data.featuredAnimal     || '';
    featuredMultiplier = data.featuredMultiplier || 2;

    // Recalculate totals
    totalSamples         = Object.keys(allSamples).length;
    collectedSampleCount = Object.keys(collectedSamples).length;
    totalRewards = Object.entries(collectedSamples).reduce((sum, [name]) => {
        const s = Object.values(allSamples).find(x => x.name === name);
        return sum + (s ? (s.reward || 0) : 0);
    }, 0);
}

// ============================================================
// Tab switching
// ============================================================
function switchTab(tabName) {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));

    const btn = document.getElementById('tabBtn' + tabName);
    const pane = document.getElementById('tab' + tabName);
    if (btn)  btn.classList.add('active');
    if (pane) pane.classList.add('active');

    if (tabName === 'Leaderboard') renderLeaderboard(topCollectors);
    if (tabName === 'Stats')       renderGlobalStats();
}

// ============================================================
// Category tabs
// ============================================================
function buildCategoryTabs() {
    const cats = ['All'];
    Object.values(allSamples).forEach(d => {
        const cat = d.category || 'Exotic';
        if (!cats.includes(cat)) cats.push(cat);
    });

    const catOrder = ['All', 'Predator', 'Bird', 'Reptile', 'Ungulate', 'Small Game', 'Exotic'];
    cats.sort((a, b) => {
        const ia = catOrder.indexOf(a), ib = catOrder.indexOf(b);
        return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib);
    });

    const container = document.getElementById('categoryTabs');
    container.innerHTML = '';

    cats.forEach(cat => {
        const btn = document.createElement('button');
        btn.className = 'cat-btn' + (cat === activeCategory ? ' active' : '');
        btn.textContent = translateCat(cat);
        btn.addEventListener('click', () => {
            activeCategory = cat;
            document.querySelectorAll('#categoryTabs .cat-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            applyFilter(document.getElementById('searchSamplesInput').value);
        });
        container.appendChild(btn);
    });
}

function translateCat(cat) {
    const map = {
        'All':        lang.cat_all        || 'All',
        'Predator':   lang.cat_predator   || 'Predators',
        'Bird':       lang.cat_bird       || 'Birds',
        'Reptile':    lang.cat_reptile    || 'Reptiles',
        'Ungulate':   lang.cat_ungulate   || 'Ungulates',
        'Small Game': lang.cat_small_game || 'Small Game',
        'Exotic':     lang.cat_exotic     || 'Exotic',
    };
    return map[cat] || cat;
}

// ============================================================
// Sample list rendering
// ============================================================
function applyFilter(searchTerm) {
    const all = Object.entries(allSamples).map(([hash, d]) => ({
        hash,
        name:      d.name      || 'unknown',
        reward:    d.reward    || 0,
        category:  d.category  || 'Exotic',
        legendary: d.legendary || false,
    }));

    filteredSamples = all.filter(s => {
        const matchCat = (activeCategory === 'All' || activeCategory === (lang.cat_all || 'All'))
                         || s.category === activeCategory;
        const matchSearch = !searchTerm
                            || s.name.toLowerCase().includes(searchTerm.toLowerCase());
        return matchCat && matchSearch;
    });

    displayedCount = 10;
    renderSamples();
}

function renderSamples() {
    const list = document.getElementById('samplesList');
    list.innerHTML = '';

    // Update progress
    const pct = totalSamples > 0 ? (collectedSampleCount / totalSamples * 100) : 0;
    document.getElementById('progressFill').style.width = pct.toFixed(1) + '%';
    setText('progressText',
        (lang.ui_progress_label || 'Progress') + ': ' + pct.toFixed(1) + '%');
    setText('progressInner', collectedSampleCount + ' / ' + totalSamples);
    setText('totalRewards',
        (lang.ui_total_rewards || 'Total Rewards') + ': $' + totalRewards);

    if (!filteredSamples.length) {
        const p = document.createElement('p');
        p.className = 'empty-state';
        p.textContent = lang.ui_no_samples || 'No samples available';
        list.appendChild(p);
        document.getElementById('loadMoreButton').disabled = true;
        return;
    }

    const slice = filteredSamples.slice(0, displayedCount);
    slice.forEach(sample => {
        const isCollected = !!collectedSamples[sample.name];
        const isLegendary = sample.legendary;
        const isFeatured  = (sample.name === featuredAnimal && featuredAnimal !== '');
        const displayReward = isFeatured
            ? (sample.reward * featuredMultiplier)
            : sample.reward;

        const div = document.createElement('div');
        div.className = 'sample-item'
            + (isCollected ? ' collected' : '')
            + (isLegendary ? ' legendary' : '');

        // Checkmark
        const check = document.createElement('span');
        check.className = 'sample-check';
        check.textContent = isCollected ? '✔' : '';
        div.appendChild(check);

        // Info block
        const info = document.createElement('div');
        info.className = 'sample-info';

        // Name row with badges
        const nameRow = document.createElement('div');
        nameRow.className = 'sample-name';
        nameRow.appendChild(document.createTextNode(formatAnimalName(sample.name)));

        if (isLegendary) {
            const b = document.createElement('span');
            b.className = 'badge-legendary';
            b.textContent = lang.ui_legendary || '★ LEGENDARY';
            nameRow.appendChild(b);
        }
        if (isFeatured) {
            const b = document.createElement('span');
            b.className = 'badge-featured';
            b.textContent = lang.ui_featured || '⭐ FEATURED';
            nameRow.appendChild(b);
        }
        info.appendChild(nameRow);

        // Details row
        const details = document.createElement('div');
        details.className = 'sample-details';

        const rewardSpan = document.createElement('span');
        rewardSpan.className = 'reward-text';
        rewardSpan.textContent = (lang.ui_reward || 'Reward') + ': $' + displayReward
            + (isFeatured ? ' (x' + featuredMultiplier + ')' : '');
        details.appendChild(rewardSpan);

        if (isCollected) {
            const entry = collectedSamples[sample.name];
            if (entry && entry.created_at) {
                const dateSpan = document.createElement('span');
                dateSpan.className = 'collected-date';
                dateSpan.textContent = (lang.ui_collected_on || 'Collected') + ': ' + formatDate(entry.created_at);
                details.appendChild(dateSpan);
            }
        }
        info.appendChild(details);
        div.appendChild(info);
        list.appendChild(div);
    });

    const btn = document.getElementById('loadMoreButton');
    btn.disabled  = displayedCount >= filteredSamples.length;
    btn.textContent = lang.ui_load_more || 'Load More';
}

// ============================================================
// Leaderboard rendering
// ============================================================
function renderLeaderboard(collectors) {
    const list = document.getElementById('rankedList');
    list.innerHTML = '';

    if (!collectors || collectors.length === 0) {
        const p = document.createElement('p');
        p.className = 'empty-state';
        p.textContent = lang.ui_no_collectors || 'No collectors yet';
        list.appendChild(p);
        return;
    }

    collectors.forEach(c => {
        const div = document.createElement('div');
        div.className = 'collector-item'
            + (c.citizenid === currentCitizenId ? ' current-player' : '');

        const rankClass = c.rank === 1 ? ' gold' : c.rank === 2 ? ' silver' : c.rank === 3 ? ' bronze' : '';
        const rank = document.createElement('span');
        rank.className = 'collector-rank' + rankClass;
        rank.textContent = (lang.ui_rank_prefix || '#') + c.rank;
        div.appendChild(rank);

        const name = document.createElement('span');
        name.className = 'collector-name';
        name.textContent = c.name;
        div.appendChild(name);

        const count = document.createElement('span');
        count.className = 'collector-count';
        count.textContent = c.sample_count + ' ' + (lang.ui_samples_count || 'samples');
        div.appendChild(count);

        list.appendChild(div);
    });
}

function filterCollectors(searchTerm) {
    if (!searchTerm) {
        renderLeaderboard(topCollectors);
        return;
    }
    renderLeaderboard(
        topCollectors.filter(c => c.name.toLowerCase().includes(searchTerm.toLowerCase()))
    );
}

// ============================================================
// Global Stats rendering
// ============================================================
function renderGlobalStats() {
    const container = document.getElementById('globalStatsList');
    container.innerHTML = '';

    const stats = globalStats || {};

    // Helper to add a card
    function addCard(titleKey, value, subText, extraClass) {
        const card = document.createElement('div');
        card.className = 'stat-card';

        const title = document.createElement('div');
        title.className = 'stat-card-title';
        title.textContent = lang[titleKey] || titleKey;
        card.appendChild(title);

        const val = document.createElement('div');
        val.className = 'stat-card-value' + (extraClass ? ' ' + extraClass : '');
        val.textContent = value;
        card.appendChild(val);

        if (subText) {
            const sub = document.createElement('div');
            sub.className = 'stat-card-sub';
            sub.textContent = subText;
            card.appendChild(sub);
        }
        container.appendChild(card);
    }

    // Total collected
    addCard('ui_total_all', stats.totalCollected || 0, null);

    // Rarest animal
    const rareName  = stats.rarestAnimal
        ? formatAnimalName(stats.rarestAnimal)
        : (lang.ui_no_stats || 'No data yet');
    const rareSub   = stats.rarestAnimal
        ? (lang.ui_rarest_sub || 'only %s collector(s) server-wide').replace('%s', stats.rarestCount || 0)
        : null;
    addCard('ui_rarest_animal', rareName, rareSub);

    // Weekly top collector
    const weekName  = stats.weeklyTopName || (lang.ui_no_weekly || 'No activity recorded this week');
    const weekSub   = stats.weeklyTopName
        ? (lang.ui_weekly_sub || '%s samples collected this week').replace('%s', stats.weeklyTopCount || 0)
        : null;
    addCard('ui_weekly_top', weekName, weekSub);

    // Featured animal
    const featName  = (stats.featuredAnimal && stats.featuredAnimal !== '')
        ? formatAnimalName(stats.featuredAnimal)
        : (lang.ui_no_featured || 'No featured animal set');
    const featSub   = (stats.featuredAnimal && stats.featuredAnimal !== '')
        ? (lang.ui_featured_mult || 'x%s reward multiplier active').replace('%s', stats.featuredMult || 2)
        : null;
    addCard('ui_featured_now', featName, featSub,
            (stats.featuredAnimal && stats.featuredAnimal !== '') ? 'featured-val' : '');
}

// ============================================================
// Certificate
// ============================================================
function showCertificate() {
    const content = document.getElementById('certContent');
    content.innerHTML = '';

    setText('certTitleHeader', lang.cert_title || 'FIELD RESEARCH CERTIFICATE');

    const now = new Date().toLocaleDateString('en-US', {
        year: 'numeric', month: 'long', day: 'numeric'
    });
    const pct = totalSamples > 0
        ? (collectedSampleCount / totalSamples * 100).toFixed(1)
        : '0.0';

    const legendaryCount = Object.values(allSamples).filter(d =>
        d.legendary && collectedSamples[d.name]
    ).length;

    function addField(labelKey, value, large) {
        const div = document.createElement('div');
        div.className = 'cert-field';

        const lbl = document.createElement('div');
        lbl.className = 'cert-field-label';
        lbl.textContent = lang[labelKey] || labelKey;
        div.appendChild(lbl);

        const val = document.createElement('div');
        val.className = 'cert-field-value' + (large ? ' large' : '');
        val.textContent = String(value);
        div.appendChild(val);

        content.appendChild(div);
    }

    addField('cert_issued_to',       playerName,          true);
    addField('cert_completion',       pct + '%',           true);
    addField('cert_total_rewards',    '$' + totalRewards,  false);
    addField('cert_legendary_count',  legendaryCount,      false);

    if (featuredAnimal && featuredAnimal !== '') {
        addField('cert_featured_animal', formatAnimalName(featuredAnimal), false);
    }

    addField('cert_issued_date', now, false);

    const sig = document.createElement('div');
    sig.className = 'cert-signature';
    sig.textContent = lang.cert_signed || 'Director of Naturalist Studies';
    content.appendChild(sig);

    const seal = document.createElement('div');
    seal.className = 'cert-seal';
    seal.textContent = lang.cert_footer || '— Official Field Research Record —';
    content.appendChild(seal);

    document.getElementById('certOverlay') && showMenu('certOverlay');
}

function closeCertificate() {
    hideAllMenus();
    post('closeUI', {});
}

// ============================================================
// Close main UI
// ============================================================
function closeUI() {
    hideAllMenus();
    post('closeUI', {});
}

// ============================================================
// Apply locale to static DOM labels
// ============================================================
function applyLang() {
    setText('menuTitle',         lang.ui_title             || 'Sample Collector');
    setText('menuSubtitle',      lang.ui_subtitle          || 'Naturalist Research Log');
    setText('leaderboardTitle',  lang.ui_top_collectors    || 'Top Sample Collectors');
    setText('statsHeading',      lang.ui_global_stats      || 'Server Statistics');
    setText('fieldGuideLabel',   lang.ui_field_guide       || 'Field Guide');
    setText('searchGuideLabel',  lang.ui_search_guide      || 'Search Guide');
    setText('findCollectorLabel', lang.ui_find_collector   || 'Find Collector');
    setText('certSubtitle',      lang.cert_subtitle        || 'Official Field Research Record');

    if (document.getElementById('closeButton'))       document.getElementById('closeButton').title       = lang.ui_close || 'Close';
    if (document.getElementById('menuBackButton'))    document.getElementById('menuBackButton').title     = lang.ui_close || 'Close';
    if (document.getElementById('certCloseButton'))   document.getElementById('certCloseButton').title   = lang.cert_close || 'Close';
    if (document.getElementById('certBackButton'))    document.getElementById('certBackButton').title    = lang.cert_back || 'Back to Field Guide';

    document.getElementById('tabBtnSamples').textContent     = lang.ui_tab_samples    || 'My Samples';
    document.getElementById('tabBtnLeaderboard').textContent = lang.ui_tab_leaderboard || 'Leaderboard';
    document.getElementById('tabBtnStats').textContent       = lang.ui_tab_stats      || 'Global Stats';

    setPlaceholder('searchSamplesInput',    lang.ui_search_samples    || 'Search animals...');
    setPlaceholder('searchCollectorsInput', lang.ui_search_collectors || 'Search collectors...');
}

// ============================================================
// DOMContentLoaded — wire up events
// ============================================================
document.addEventListener('DOMContentLoaded', function () {

    document.getElementById('closeButton').addEventListener('click', closeUI);
    document.getElementById('menuBackButton').addEventListener('click', closeUI);
    document.getElementById('certCloseButton').addEventListener('click', closeCertificate);
    document.getElementById('certBackButton').addEventListener('click', backToMenu);

    document.getElementById('tabBtnSamples').addEventListener('click',     () => switchTab('Samples'));
    document.getElementById('tabBtnLeaderboard').addEventListener('click', () => switchTab('Leaderboard'));
    document.getElementById('tabBtnStats').addEventListener('click',       () => switchTab('Stats'));

    document.getElementById('searchSamplesInput').addEventListener('input', e => {
        applyFilter(e.target.value);
    });

    document.getElementById('searchCollectorsInput').addEventListener('input', e => {
        filterCollectors(e.target.value);
    });

    document.getElementById('loadMoreButton').addEventListener('click', () => {
        displayedCount += 10;
        renderSamples();
    });

    document.addEventListener('keydown', e => {
        if (e.key !== 'Escape') return;
        // Close cert first if open, then main menu
        if (!document.getElementById('certOverlay').classList.contains('hidden')) {
            closeCertificate();
        } else if (!document.getElementById('samplesMenuUI').classList.contains('hidden')) {
            closeUI();
        }
    });
});

// ============================================================
// NUI Message Handler
// ============================================================
window.addEventListener('message', event => {
    const data = event.data;
    if (!data || !data.action) return;

    // ---- Open full menu ----
    if (data.action === 'openSamplesMenu') {
        setupState(data);
        applyLang();

        activeCategory = 'All';
        filteredSamples = Object.entries(allSamples).map(([hash, d]) => ({
            hash,
            name:      d.name      || 'unknown',
            reward:    d.reward    || 0,
            category:  d.category  || 'Exotic',
            legendary: d.legendary || false,
        }));

        buildCategoryTabs();
        displayedCount = 10;

        // Ensure My Samples tab is active
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
        document.getElementById('tabBtnSamples').classList.add('active');
        document.getElementById('tabSamples').classList.add('active');

        renderSamples();
        showMenu('samplesMenuUI');

    // ---- Open certificate directly ----
    } else if (data.action === 'openCertificate') {
        setupState(data);
        applyLang();
        showCertificate();

    // ---- Force close ----
    } else if (data.action === 'closeUI') {
        hideAllMenus();
    }
});
