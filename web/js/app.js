/**
 * RITMINITY - Main Application
 * Frontend JavaScript application
 */

const App = {
    currentPage: 'home',
    currentUser: null,
    mapsPage: 1,
    mapsLimit: 12,
    leaderboardType: 'score',
    
    /**
     * Initialize the application
     */
    init() {
        this.bindEvents();
        this.checkAuth();
        this.loadHomeData();
    },
    
    /**
     * Bind DOM events
     */
    bindEvents() {
        // Navigation
        document.querySelectorAll('.nav-links a').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const page = link.dataset.page;
                this.navigateTo(page);
            });
        });
        
        // Auth buttons
        document.getElementById('loginBtn')?.addEventListener('click', () => this.showModal('loginModal'));
        document.getElementById('registerBtn')?.addEventListener('click', () => this.showModal('registerModal'));
        document.getElementById('logoutBtn')?.addEventListener('click', () => this.logout());
        
        // Modal close buttons
        document.querySelectorAll('.modal .close').forEach(btn => {
            btn.addEventListener('click', () => this.hideAllModals());
        });
        
        // Forms
        document.getElementById('loginForm')?.addEventListener('submit', (e) => this.handleLogin(e));
        document.getElementById('registerForm')?.addEventListener('submit', (e) => this.handleRegister(e));
        
        // Maps filters
        document.getElementById('difficultyFilter')?.addEventListener('change', () => this.loadMaps());
        document.getElementById('columnFilter')?.addEventListener('change', () => this.loadMaps());
        document.getElementById('searchInput')?.addEventListener('input', this.debounce(() => this.loadMaps(), 300));
        
        // Pagination
        document.getElementById('prevPage')?.addEventListener('click', () => this.changePage(-1));
        document.getElementById('nextPage')?.addEventListener('click', () => this.changePage(1));
        
        // Leaderboard tabs
        document.querySelectorAll('.leaderboard-tabs .tab').forEach(tab => {
            tab.addEventListener('click', () => {
                document.querySelectorAll('.leaderboard-tabs .tab').forEach(t => t.classList.remove('active'));
                tab.classList.add('active');
                this.leaderboardType = tab.dataset.type;
                this.loadLeaderboard();
            });
        });
        
        // Close modals on background click
        document.querySelectorAll('.modal').forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    this.hideAllModals();
                }
            });
        });
    },
    
    /**
     * Check authentication status
     */
    async checkAuth() {
        const token = API.getToken();
        if (token) {
            try {
                const data = await API.get('users/me');
                if (data.success) {
                    this.currentUser = data.user;
                    this.updateAuthUI();
                } else {
                    this.logout();
                }
            } catch (e) {
                this.logout();
            }
        }
    },
    
    /**
     * Update auth UI based on login status
     */
    updateAuthUI() {
        const loginBtn = document.getElementById('loginBtn');
        const registerBtn = document.getElementById('registerBtn');
        const userMenu = document.getElementById('userMenu');
        const usernameDisplay = document.getElementById('usernameDisplay');
        
        if (this.currentUser) {
            loginBtn?.classList.add('hidden');
            registerBtn?.classList.add('hidden');
            userMenu?.classList.remove('hidden');
            usernameDisplay.textContent = this.currentUser.username;
        } else {
            loginBtn?.classList.remove('hidden');
            registerBtn?.classList.remove('hidden');
            userMenu?.classList.add('hidden');
        }
    },
    
    /**
     * Navigate to page
     */
    navigateTo(page) {
        // Update nav links
        document.querySelectorAll('.nav-links a').forEach(link => {
            link.classList.toggle('active', link.dataset.page === page);
        });
        
        // Update pages
        document.querySelectorAll('.page').forEach(p => {
            p.classList.remove('active');
        });
        
        const pageElement = document.getElementById(`${page}Page`);
        if (pageElement) {
            pageElement.classList.add('active');
            this.currentPage = page;
            
            // Load page data
            switch (page) {
                case 'maps':
                    this.loadMaps();
                    break;
                case 'leaderboard':
                    this.loadLeaderboard();
                    break;
                case 'profile':
                    this.loadProfile();
                    break;
                case 'play':
                    this.loadPlayMaps();
                    break;
            }
        }
    },
    
    /**
     * Load home page data
     */
    async loadHomeData() {
        try {
            const stats = await API.getGlobalStats();
            if (stats.success) {
                // Update stats display if needed
            }
        } catch (e) {
            console.error('Failed to load home data:', e);
        }
    },
    
    /**
     * Load maps
     */
    async loadMaps() {
        const container = document.getElementById('mapsList');
        if (!container) return;
        
        container.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
        
        const difficulty = document.getElementById('difficultyFilter')?.value;
        const columnCount = document.getElementById('columnFilter')?.value;
        const search = document.getElementById('searchInput')?.value;
        
        try {
            const data = await API.getMaps({
                page: this.mapsPage,
                limit: this.mapsLimit,
                difficulty: difficulty || undefined,
                column_count: columnCount || undefined,
                search: search || undefined
            });
            
            if (data.success) {
                this.renderMaps(data.maps);
                this.updatePagination(data.pagination);
            } else {
                container.innerHTML = '<p class="text-center text-muted">No maps found</p>';
            }
        } catch (e) {
            container.innerHTML = '<p class="text-center text-error">Failed to load maps</p>';
        }
    },
    
    /**
     * Render maps grid
     */
    renderMaps(maps) {
        const container = document.getElementById('mapsList');
        if (!container) return;
        
        if (!maps || maps.length === 0) {
            container.innerHTML = '<p class="text-center text-muted">No maps available</p>';
            return;
        }
        
        container.innerHTML = maps.map(map => `
            <div class="map-card" onclick="App.selectMap(${map.id})">
                <div class="map-cover">🎵</div>
                <div class="map-info">
                    <h3 class="map-title">${this.escapeHtml(map.title)}</h3>
                    <p class="map-artist">${this.escapeHtml(map.artist || 'Unknown')}</p>
                    <div class="map-meta">
                        <span class="map-difficulty ${map.difficulty.toLowerCase()}">${map.difficulty}</span>
                        <span class="map-stats">${map.column_count}K | ${map.bpm} BPM</span>
                    </div>
                </div>
            </div>
        `).join('');
    },
    
    /**
     * Update pagination
     */
    updatePagination(pagination) {
        const pageInfo = document.getElementById('pageInfo');
        const prevBtn = document.getElementById('prevPage');
        const nextBtn = document.getElementById('nextPage');
        
        if (pageInfo) {
            pageInfo.textContent = `Page ${pagination.page} of ${pagination.pages}`;
        }
        
        if (prevBtn) {
            prevBtn.disabled = pagination.page <= 1;
        }
        
        if (nextBtn) {
            nextBtn.disabled = pagination.page >= pagination.pages;
        }
    },
    
    /**
     * Change maps page
     */
    changePage(delta) {
        this.mapsPage += delta;
        if (this.mapsPage < 1) this.mapsPage = 1;
        this.loadMaps();
    },
    
    /**
     * Select map for playing
     */
    selectMap(mapId) {
        // Store selected map and start game
        localStorage.setItem('selected_map', mapId);
        // In a real implementation, this would launch the game
        alert('Starting game with map ' + mapId);
    },
    
    /**
     * Load play maps
     */
    async loadPlayMaps() {
        const container = document.getElementById('playMapsList');
        if (!container) return;
        
        container.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
        
        try {
            const data = await API.getMaps({ limit: 20 });
            
            if (data.success) {
                this.renderPlayMaps(data.maps);
            }
        } catch (e) {
            container.innerHTML = '<p class="text-center text-error">Failed to load maps</p>';
        }
    },
    
    /**
     * Render play maps
     */
    renderPlayMaps(maps) {
        const container = document.getElementById('playMapsList');
        if (!container) return;
        
        container.innerHTML = maps.map(map => `
            <div class="map-card" onclick="App.playMap(${map.id})">
                <div class="map-cover">🎵</div>
                <div class="map-info">
                    <h3 class="map-title">${this.escapeHtml(map.title)}</h3>
                    <p class="map-artist">${this.escapeHtml(map.artist || 'Unknown')}</p>
                    <div class="map-meta">
                        <span class="map-difficulty ${map.difficulty.toLowerCase()}">${map.difficulty}</span>
                        <span class="map-stats">${map.column_count}K</span>
                    </div>
                </div>
            </div>
        `).join('');
    },
    
    /**
     * Play map
     */
    playMap(mapId) {
        // In a real implementation, this would launch the game with the selected map
        alert('Playing map ' + mapId);
    },
    
    /**
     * Load leaderboard
     */
    async loadLeaderboard() {
        const tbody = document.getElementById('leaderboardBody');
        if (!tbody) return;
        
        tbody.innerHTML = '<tr><td colspan="6" class="text-center"><div class="spinner"></div></td></tr>';
        
        try {
            const data = await API.getLeaderboard(this.leaderboardType, 1, 50);
            
            if (data.success) {
                this.renderLeaderboard(data.leaderboard);
            }
        } catch (e) {
            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-error">Failed to load leaderboard</td></tr>';
        }
    },
    
    /**
     * Render leaderboard
     */
    renderLeaderboard(leaderboard) {
        const tbody = document.getElementById('leaderboardBody');
        if (!tbody) return;
        
        if (!leaderboard || leaderboard.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted">No data available</td></tr>';
            return;
        }
        
        tbody.innerHTML = leaderboard.map((entry, index) => `
            <tr>
                <td class="rank rank-${index + 1}">#${index + 1}</td>
                <td>${this.escapeHtml(entry.username)}</td>
                <td>${this.formatNumber(entry.rank_points || entry.total_score)}</td>
                <td>${entry.max_accuracy ? entry.max_accuracy.toFixed(2) + '%' : '-'}</td>
                <td>${entry.max_combo || '-'}</td>
                <td>${entry.total_plays || 0}</td>
            </tr>
        `).join('');
    },
    
    /**
     * Load profile
     */
    async loadProfile() {
        if (!this.currentUser) {
            this.navigateTo('home');
            return;
        }
        
        try {
            const data = await API.getUser(this.currentUser.id);
            
            if (data.success) {
                this.renderProfile(data.user);
            }
        } catch (e) {
            console.error('Failed to load profile:', e);
        }
    },
    
    /**
     * Render profile
     */
    renderProfile(user) {
        document.getElementById('profileUsername').textContent = user.username;
        document.getElementById('profileCountry').textContent = `Country: ${user.country}`;
        document.getElementById('profileJoinDate').textContent = `Member since: ${new Date(user.created_at).toLocaleDateString()}`;
        
        if (user.avatar_url) {
            document.getElementById('profileAvatar').src = user.avatar_url;
        }
        
        if (user.stats) {
            document.getElementById('statPlays').textContent = this.formatNumber(user.stats.total_plays);
            document.getElementById('statScore').textContent = this.formatNumber(user.stats.total_score);
            document.getElementById('statCombo').textContent = user.stats.max_combo;
            document.getElementById('statRank').textContent = this.formatNumber(user.stats.rank_points);
            document.getElementById('gradeSS').textContent = user.stats.ss_count;
            document.getElementById('gradeS').textContent = user.stats.s_count;
            document.getElementById('gradeA').textContent = user.stats.a_count;
        }
    },
    
    /**
     * Handle login form submission
     */
    async handleLogin(e) {
        e.preventDefault();
        
        const form = e.target;
        const username = form.username.value;
        const password = form.password.value;
        
        try {
            const data = await API.login(username, password);
            
            if (data.success) {
                this.currentUser = data.user;
                this.updateAuthUI();
                this.hideAllModals();
                form.reset();
            } else {
                alert(data.error || 'Login failed');
            }
        } catch (e) {
            alert('Login failed. Please try again.');
        }
    },
    
    /**
     * Handle register form submission
     */
    async handleRegister(e) {
        e.preventDefault();
        
        const form = e.target;
        const username = form.username.value;
        const email = form.email.value;
        const password = form.password.value;
        const confirmPassword = form.confirm_password.value;
        
        if (password !== confirmPassword) {
            alert('Passwords do not match');
            return;
        }
        
        try {
            const data = await API.register(username, email, password);
            
            if (data.success) {
                alert('Registration successful! Please login.');
                this.hideAllModals();
                form.reset();
                this.showModal('loginModal');
            } else {
                alert(data.error || 'Registration failed');
            }
        } catch (e) {
            alert('Registration failed. Please try again.');
        }
    },
    
    /**
     * Logout
     */
    async logout() {
        try {
            await API.logout();
        } catch (e) {
            // Ignore errors
        }
        
        this.currentUser = null;
        this.updateAuthUI();
        this.navigateTo('home');
    },
    
    /**
     * Show modal
     */
    showModal(modalId) {
        document.getElementById(modalId)?.classList.add('active');
    },
    
    /**
     * Hide all modals
     */
    hideAllModals() {
        document.querySelectorAll('.modal').forEach(modal => {
            modal.classList.remove('active');
        });
    },
    
    /**
     * Escape HTML
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },
    
    /**
     * Format number
     */
    formatNumber(num) {
        if (!num) return '0';
        if (num >= 1000000) {
            return (num / 1000000).toFixed(1) + 'M';
        }
        if (num >= 1000) {
            return (num / 1000).toFixed(1) + 'K';
        }
        return num.toString();
    },
    
    /**
     * Debounce function
     */
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
};

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    App.init();
});

// Export for global use
window.App = App;